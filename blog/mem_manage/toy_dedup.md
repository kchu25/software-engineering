@def title = "Toy Test: Periodic Deduplication in a Loop"
@def published = "23 February 2026"
@def tags = ["julia", "memory-management"]

# Toy Test: Periodic Deduplication in a Loop

A self-contained playground that mimics the motif-collection pattern — generating fake "motifs" across samples, appending to a growing DataFrame, and deduplicating periodically to keep memory bounded.

---

## Setup

```julia
using DataFrames
```

No extra packages needed — just DataFrames.

---

## Toy Data Generator

This stands in for your `extract_motifs_from_sample`. It produces a small DataFrame of fake motifs, with **intentional overlaps across samples** so dedup actually has work to do.

```julia
"""
Simulates extracting motifs from one sample.
- `sample_id`  : which iteration we're on (used to control overlap)
- `n_motifs`   : how many rows this sample produces
- `n_unique`   : size of the "universe" of possible motifs (controls overlap rate)
"""
function fake_extract_motifs(sample_id::Int; n_motifs=20, n_unique=30)
    rng = (sample_id * 1337)  # deterministic but varied per sample

    # motif identity columns (what you'd dedup on)
    motif_a = [string("node_", rand(1:n_unique)) for _ in 1:n_motifs]
    motif_b = [string("node_", rand(1:n_unique)) for _ in 1:n_motifs]
    pattern = [rand(["AND", "OR", "XOR"])        for _ in 1:n_motifs]

    # a "contribution" column — varies per sample, NOT part of dedup key
    contribution = rand(n_motifs) .* sample_id

    return DataFrame(; motif_a, motif_b, pattern, contribution)
end
```

---

## The Main Loop

```julia
# ---- config ----
num_samples  = 12      # total iterations (like ec.num_contrib_samples)
dedup_every  = 3       # deduplicate every N iterations
dedup_cols   = Not(:contribution)   # dedup key: everything except :contribution

# ---- state ----
df_motifs = DataFrame()
n_before  = 0          # total rows seen before any dedup

for offset in 0:(num_samples - 1)
    @info "Sample $(offset + 1) / $num_samples"

    # --- simulate your pipeline ---
    df = fake_extract_motifs(offset + 1; n_motifs=20, n_unique=30)
    n_before += nrow(df)
    append!(df_motifs, df)

    # --- periodic dedup ---
    if (offset + 1) % dedup_every == 0 || offset == num_samples - 1
        n_before_dedup = nrow(df_motifs)
        unique!(df_motifs, dedup_cols)
        n_after_dedup  = nrow(df_motifs)
        GC.gc()
        @info "  → Dedup pass: $n_before_dedup rows → $n_after_dedup rows (removed $(n_before_dedup - n_after_dedup))"
    end
end

# final dedup (safety net — periodic passes may have missed cross-boundary dupes)
unique!(df_motifs, dedup_cols)

println("\nDone.")
println("  Total rows seen (pre-dedup): $n_before")
println("  Unique rows kept:            $(nrow(df_motifs))")
```

---

## What to Expect

Because `n_unique=30` but each sample draws `n_motifs=20` rows, there's heavy overlap between samples. You should see the dedup passes cut row counts significantly, which is exactly the point — **memory stays bounded** even if `num_samples` grows large.

Sample output:
```
[ Info: Sample 3 / 12
[ Info:   → Dedup pass: 60 rows → 28 rows (removed 32)
[ Info: Sample 6 / 12
[ Info:   → Dedup pass: 56 rows → 30 rows (removed 26)
...
Done.
  Total rows seen (pre-dedup): 240
  Unique rows kept:            30
```

---

## Variants to Try

**1. Crank up overlap** (more dedup benefit):
```julia
df = fake_extract_motifs(offset + 1; n_motifs=20, n_unique=15)
# n_unique < n_motifs → lots of within-sample dupes too
```

**2. Reduce overlap** (stress test — fewer dupes, memory grows more):
```julia
df = fake_extract_motifs(offset + 1; n_motifs=20, n_unique=500)
```

**3. Dedup on specific columns only** (not `Not(:contribution)`):
```julia
dedup_cols = [:motif_a, :motif_b]   # ignore :pattern too
```

**4. Track memory directly**:
```julia
# wrap the loop body with:
@info "  Memory: $(Base.gc_live_bytes() / 1e6) MB"
```

**5. Swap `append!` for Arrow streaming** (the memory-safe upgrade):
```julia
using Arrow
open("motifs.arrow", "w") do io
    writer = Arrow.Writer(io)
    for offset in 0:(num_samples - 1)
        df = fake_extract_motifs(offset + 1)
        Arrow.write(writer, df)
    end
    close(writer)
end
df_motifs = DataFrame(Arrow.Table("motifs.arrow"))
unique!(df_motifs, dedup_cols)
```

---

## Key Insight

The periodic dedup is a **memory pressure valve**: each pass converts accumulated rows into a much smaller deduplicated set, so the DataFrame never grows proportionally to `num_samples × rows_per_sample`. The final `unique!` outside the loop is a safety net for cross-boundary duplicates that straddled two dedup windows.