@def title = "Avoiding Memory Explosion in Julia For Loops"
@def published = "23 February 2026"
@def tags = ["julia", "memory-management"]

# Avoiding Memory Explosion in Julia For Loops

The core mental model is simple: **every chunk you append to a collection stays alive in RAM until the program ends** (or until nothing references it). If chunks are big, that adds up fast. The fix is usually to ask: *do I actually need all chunks at once?* Usually the answer is no.

---

## 1. Pre-allocate Instead of Growing

When you `push!` in a loop, Julia may have to copy the entire collection repeatedly as it resizes. If you know the final size upfront, just fill by index:

```julia
result = Vector{Float64}(undef, n)
for i in 1:n
    result[i] = compute(i)
end
```

The memory cost is paid **once**, not on every iteration.

---

## 2. Reduce As You Go (Don't Accumulate)

Ask yourself: are you collecting chunks to compute something at the end? Then just compute it inline and throw the chunk away:

```julia
total = 0.0
for chunk in chunks
    total += sum(chunk.value)
    # chunk goes out of scope here — GC can reclaim it
end
```

The "collection" you actually needed was just a single `Float64`.

---

## 3. 🗂️ Write Chunks to Disk As You Go *(The Big One)*

This is the most impactful strategy when chunks are genuinely large DataFrames. Instead of building a massive in-memory structure, flush each chunk to disk immediately and let it go.

### CSV (simplest, slowest)

```julia
using CSV, DataFrames

for (i, chunk) in enumerate(chunks)
    CSV.write("output.csv", chunk, append = i > 1)
end
```

Easy, but CSV is slow to read/write and bloated on disk. Fine for small-ish data.

---

### Arrow (sweet spot for most use cases)

Arrow is a **columnar binary format** — think of it like a DataFrame frozen in the exact memory layout Julia already uses. Reading it back is essentially zero-copy.

```julia
using Arrow, DataFrames

# Write one chunk per file, then combine later
for (i, chunk) in enumerate(chunks)
    Arrow.write("chunk_$i.arrow", chunk)
end

# Read back lazily (doesn't load everything at once)
tables = [Arrow.Table("chunk_$i.arrow") for i in 1:n]
full = vcat(DataFrame.(tables)...)
```

Or, write a **multi-record-batch Arrow file** (one file, multiple chunks inside):

```julia
open("output.arrow", "w") do io
    writer = Arrow.Writer(io)  # opens a streaming writer
    for chunk in chunks
        Arrow.write(writer, chunk)
    end
    close(writer)
end
```

Then read it back in one shot, or iterate over batches lazily:

```julia
for batch in Arrow.Stream("output.arrow")
    df = DataFrame(batch)
    process(df)
end
```

> **Why Arrow?** Read/write is $\sim 10\text{–}100\times$ faster than CSV, the file is compact, and the format is interoperable with Python (pandas, polars), R, and Spark.

---

### Parquet (best for long-term storage / analytics)

Parquet is a **compressed columnar format** designed for big data pipelines (think S3 + Spark). It's the standard in data engineering.

```julia
using Parquet2, DataFrames

Parquet2.writefile("output.parquet", df)

# Read back
df2 = DataFrame(Parquet2.Dataset("output.parquet"))
```

Parquet supports **row groups** natively — each chunk you write becomes a row group, and downstream tools can skip row groups entirely when filtering. This is called *predicate pushdown* and is a big deal for query performance.

| Format  | Speed     | File size | Interop | Best for |
|---------|-----------|-----------|---------|----------|
| CSV     | 🐢 Slow    | ❌ Large   | ✅ Universal | Quick exports, small data |
| Arrow   | ⚡ Fast    | ✅ Small   | ✅ Great | In-memory pipelines, IPC |
| Parquet | ✅ Fast    | ✅✅ Smallest | ✅ Great | Long-term storage, analytics |

---

## 4. Lazy Iteration with Generators

If *you* are producing the chunks, don't materialize them all first. Use a `Channel` to yield one at a time:

```julia
function lazy_chunks(data, step)
    Channel() do ch
        for i in 1:step:length(data)
            put!(ch, data[i:min(i+step-1, end)])
        end
    end
end

for chunk in lazy_chunks(big_data, 10_000)
    process(chunk)  # only one chunk in memory at a time
end
```

---

## 5. Nudge the GC

Julia's garbage collector is lazy — it doesn't collect until it feels pressure. If you know a big object is done, you can hint:

```julia
for chunk in chunks
    process(chunk)
    GC.gc()
end
```

This is a band-aid, not a solution. Use it alongside the strategies above, not instead of them.

---

## 6. Memory-Map Large Arrays

If you need random access to data that's too large to fit in RAM, `Mmap` lets you treat a file on disk as if it were an array:

```julia
using Mmap
A = Mmap.mmap("bigfile.bin", Matrix{Float64}, (nrows, ncols))
```

The OS handles paging in only the pages you actually touch. Reads are fast; you never load the whole thing.

---

## The One-Line Heuristic

> **If chunks are big, stream and write — don't accumulate.** After each iteration, ask: *"does anything still hold a reference to this chunk?"* If yes, that chunk is stuck in RAM.