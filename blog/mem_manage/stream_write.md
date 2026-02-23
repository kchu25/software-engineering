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

#### Writing chunks during the loop

The cleanest pattern is a **streaming writer** — one file, one chunk written per iteration, nothing accumulates in RAM:

```julia
using Arrow, DataFrames

open("output.arrow", "w") do io
    writer = Arrow.Writer(io)
    for chunk in chunks          # chunk is a DataFrame
        Arrow.write(writer, chunk)
    end
    close(writer)
end
```

Each `chunk` is flushed to disk and can be GC'd. The file grows on disk, not in RAM.

#### Combining after the loop

When you're done and ready to work with the full dataset, read it back as one DataFrame:

```julia
df = DataFrame(Arrow.Table("output.arrow"))
```

`Arrow.Table` reads all batches and presents them as a single table. Wrapping in `DataFrame(...)` materializes it. If the file is truly massive and you only need to process it in passes, iterate lazily instead:

```julia
for batch in Arrow.Stream("output.arrow")
    df_batch = DataFrame(batch)
    process(df_batch)
end
```

#### Deduplicating identical rows

Once you have your combined DataFrame, `unique` drops exact duplicate rows:

```julia
df_deduped = unique(df)
```

If you only care about duplicates across *specific columns* (e.g. a natural key), pass them explicitly:

```julia
df_deduped = unique(df, [:col_a, :col_b])  # keep first occurrence of each unique combo
```

For very large DataFrames where you want to avoid a full copy, `unique!` deduplicates in-place:

```julia
unique!(df)   # mutates df, no copy made
```

> **Why not dedup per chunk during the loop?** You can — `unique!(chunk)` before writing is free and reduces file size. But you'll still need a final `unique!` after combining, since the *same row can appear in two different chunks*. Do both if chunks are huge.

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