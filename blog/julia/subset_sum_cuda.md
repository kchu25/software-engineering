@def title = "GPU Subset Sum Sampling: Mathematical Explanation"
@def published = "15 October 2025"
@def tags = ["julia"]

# GPU Subset Sum Sampling: Mathematical Explanation

## Overview

This Julia code implements a GPU-accelerated algorithm to sample subset sums from multiple vectors in parallel. It uses CUDA to efficiently compute sums of random subsets using bitmask representations.

## Problem Statement

**Input:** A collection of $M$ vectors $\mathbf{v}_1, \mathbf{v}_2, \ldots, \mathbf{v}_M$ where vector $\mathbf{v}_i \in \mathbb{R}^{n_i}$ has length $n_i$.

**Goal:** For each vector $\mathbf{v}_i$, approximate the set of all possible subset sums:

$$S_i = \left\{ \sum_{j \in S} v_{i,j} : S \subseteq \{1, 2, \ldots, n_i\} \right\}$$

Since $|S_i| \leq 2^{n_i}$, computing all subset sums becomes intractable for large $n_i$. Instead, we **sample** up to $k$ random subsets per vector.

---

## Algorithm Components

### 1. Vector Padding

**Mathematical Operation:** Given vectors with lengths $n_1, n_2, \ldots, n_M$, create matrix $\mathbf{V} \in \mathbb{R}^{n_{\max} \times M}$ where $n_{\max} = \max_i n_i$:

$$V_{j,i} = \begin{cases} 
v_{i,j} & \text{if } j \leq n_i \\
0 & \text{if } j > n_i
\end{cases}$$

This enables **column-major memory access** which is optimal for GPU operations.

**Code:**

```julia
function prepare_padded_vectors(vectors::Vector{Vector{T}}) where T
    max_len = maximum(length.(vectors))
    M = length(vectors)
    lengths = Int32.(length.(vectors))
    
    padded_matrix = zeros(T, max_len, M)
    for (i, vec) in enumerate(vectors)
        padded_matrix[1:length(vec), i] .= vec
    end
    
    return padded_matrix, lengths
end
```

---

### 2. Random Mask Generation

**Mathematical Operation:** Each subset $S \subseteq \{1, 2, \ldots, n_i\}$ is encoded as an integer $m \in \{0, 1, \ldots, 2^{n_i} - 1\}$ where:

$$j \in S \iff \text{bit}_{j-1}(m) = 1$$

**Example:** For vector $[a, b, c]$ with $n=3$:
- Mask $m = 5 = (101)_2$ represents subset $\{a, c\}$ (bits 0 and 2 are set)
- Mask $m = 3 = (011)_2$ represents subset $\{a, b\}$ (bits 0 and 1 are set)

> **💡 Why Use Integer Masks Instead of Binary Matrices?**
>
> You might wonder: why encode subsets as integers rather than storing explicit binary matrices?
>
> **Memory Efficiency:**
> - **Integer mask:** 1 Int32 (4 bytes) per subset
> - **Binary matrix:** $n$ bytes per subset (one boolean per element)
> 
> For a vector of length $n=20$, storing 1000 subsets:
> - Masks: $1000 \times 4 = 4$ KB
> - Binary matrix: $1000 \times 20 = 20$ KB (5× larger)
>
> **Computational Efficiency:**
> - **Bit operations** (`>>`, `&`) are extremely fast (single CPU cycles)
> - **On-the-fly extraction:** We decode which elements to include during computation, avoiding separate memory lookups
> - **Cache friendly:** Compact representation means more masks fit in GPU cache
>
> **Sampling Efficiency:**
> - Generating random integers in range $[0, 2^n-1]$ is trivial
> - No need to construct and store explicit binary arrays
> - Easy to ensure uniqueness: just sample integers without replacement
>
> The mask encoding is essentially a **compressed representation** that's both space-efficient and computation-friendly!

**Sampling Strategy:** For each vector $i$, sample $k_i = \min(2^{n_i}, k)$ unique masks **without replacement**, where $k$ is `num_samples_per_vec`.

**Code:**

```julia
function generate_random_masks(lengths::Vector{Int32}, num_samples_per_vec::Int)
    M = length(lengths)
    
    # Calculate actual sample counts (capped by 2^n)
    masks_needed = [min(2^n, num_samples_per_vec) for n in lengths]
    total_samples = sum(masks_needed)
    
    # Allocate flat arrays to hold all masks and their corresponding vector IDs
    masks = zeros(Int32, total_samples)
    vec_ids = zeros(Int32, total_samples)
    
    # Fill arrays: for each vector, generate its random masks
    current_position = 1
    for vec_id in 1:M
        vec_length = lengths[vec_id]
        num_masks_for_this_vec = masks_needed[vec_id]
        
        start_idx = current_position
        end_idx = current_position + num_masks_for_this_vec - 1
        
        # Generate random masks (0 to 2^vec_length - 1)
        # Sample WITHOUT replacement to ensure unique subsets
        total_possible_subsets = 2^vec_length
        if num_masks_for_this_vec >= total_possible_subsets
            masks[start_idx:end_idx] = 0:(total_possible_subsets - 1)
        else
            all_possible = collect(0:(total_possible_subsets - 1))
            sampled = shuffle(all_possible)[1:num_masks_for_this_vec]
            masks[start_idx:end_idx] = sampled
        end
        
        vec_ids[start_idx:end_idx] .= vec_id
        current_position = end_idx + 1
    end
    
    return masks, vec_ids, masks_needed
end
```

---

### 3. GPU Kernel Computation

**Mathematical Operation:** Given mask $m$ for vector $\mathbf{v}_i$ of length $n_i$, compute:

$$\text{sum}(m) = \sum_{j=1}^{n_i} v_{i,j} \cdot \mathbb{1}_{j \in S(m)}$$

where $S(m) = \{j : (m \gg (j-1)) \& 1 = 1\}$ and $\mathbb{1}_{\cdot}$ is the indicator function.

**Bit Extraction:** For position $j$, we check: `(mask >> (j-1)) & 1 == 1`

> **📘 Detailed Bit Extraction Explanation**
>
> Let's break down the operation `(mask >> (i-1)) & 1 == 1` step by step:
>
> **Example:** Suppose `mask = 5` and we want to check positions 1, 2, and 3.
>
> Binary representation: `5 = (101)₂`
>
> **Position 1 (i=1):**
> ```
> mask >> (1-1) = 5 >> 0 = 5 = (101)₂
> (101)₂ & 1 = (101)₂ & (001)₂ = (001)₂ = 1 ✓ (bit 0 is SET)
> ```
>
> **Position 2 (i=2):**
> ```
> mask >> (2-1) = 5 >> 1 = 2 = (010)₂
> (010)₂ & 1 = (010)₂ & (001)₂ = (000)₂ = 0 ✗ (bit 1 is NOT set)
> ```
>
> **Position 3 (i=3):**
> ```
> mask >> (3-1) = 5 >> 2 = 1 = (001)₂
> (001)₂ & 1 = (001)₂ & (001)₂ = (001)₂ = 1 ✓ (bit 2 is SET)
> ```
>
> **Result:** Mask 5 selects positions {1, 3}, which corresponds to subset $\{v_1, v_3\}$.
>
> **Why this works:**
> - **Right shift `>>` (i-1):** Moves bit (i-1) to the rightmost position
>   
>   > **🔍 Understanding Right Shift**
>   >
>   > The right shift operator `>>` moves all bits to the right by a specified number of positions.
>   >
>   > **Example with mask = 5 = (101)₂:**
>   > ```
>   > Original:        1 0 1
>   > Bit positions:   2 1 0
>   > 
>   > Shift right 0:   1 0 1  (no change)
>   > Shift right 1:   0 1 0  (each bit moves right 1 position)
>   > Shift right 2:   0 0 1  (each bit moves right 2 positions)
>   > ```
>   >
>   > **Why shift by (i-1)?**
>   > - We want to check bit at position (i-1) in the mask
>   > - After shifting right by (i-1), that bit is now at position 0 (rightmost)
>   > - Then `& 1` extracts just that rightmost bit
>   >
>   > **Concrete example checking position 2 (i=2):**
>   > ```
>   > mask = 5 = (101)₂     [bit 1 is at position 1, currently 0]
>   > mask >> 1 = (010)₂    [bit 1 is now at position 0]
>   > (010)₂ & 1 = 0        [extract rightmost bit → 0, so exclude position 2]
>   > ```
>   >
>   > It's like sliding the bits right until the one we care about is in the "inspection window" at position 0!
>
> - **Bitwise AND with 1:** Extracts only the rightmost bit (masks all other bits to 0)
> - **Check `== 1`:** Tests if that bit is set
>
> **Visual representation for mask = 5 = (101)₂:**
> ```
> Original:     1 0 1
>              ↑ ↑ ↑
> Position:    3 2 1
>
> Checking position 1: Look at bit 0 → 1 (included)
> Checking position 2: Look at bit 1 → 0 (excluded)
> Checking position 3: Look at bit 2 → 1 (included)
> ```

**Parallelization:** Each GPU thread handles one mask independently, enabling massive parallelism.

> **⚡ Efficiency Analysis: When is Bitmask Approach Optimal?**
>
> The bitmask approach is efficient on GPUs because bitwise operations are extremely fast, but there's a tradeoff with the loop over vector elements.
>
> **Cost per subset sum:**
> - $n$ right shifts: `mask >> (i-1)` for each element
> - $n$ bitwise ANDs: `... & 1` for each element  
> - $n$ conditionals and additions: `if ... then s += vecs[i, vec_id]`
>
> **Alternative approach:** Pre-materialize all subsets as binary matrices
> - Cost: $O(1)$ memory lookups per element (no bit operations)
> - Memory: $O(k \cdot n)$ for $k$ subsets of length $n$
>
> **Efficiency threshold estimation:**
>
> Bitwise operations on modern GPUs are typically **1-2 cycles**, while memory access can be **hundreds of cycles** (even with caching). The bitmask approach wins when:
>
> $\text{Cost}_{\text{bitwise}} < \text{Cost}_{\text{memory}}$
> $n \cdot (2\text{-}4 \text{ cycles}) < k \cdot n \cdot \text{(memory access penalty)}$
>
> **Practical upper bound for vector length $n$:**
> - **Sweet spot:** $n \leq 30\text{-}32$ (fits in Int32, very efficient)
> - **Still efficient:** $n \leq 50\text{-}64$ (bitwise ops still faster than memory overhead)
> - **Diminishing returns:** $n > 100$ (might consider pre-materialization if memory allows)
>
> **Why this code is well-designed:**
> - For typical subset sum problems, vectors have $n \approx 10\text{-}30$ elements
> - At $n=20$: Each thread does 20 shifts + 20 ANDs = **40 fast ops** vs storing/loading 20 bytes
> - The loop is **fully unrolled** by the compiler for small $n$, eliminating loop overhead
> - **No thread divergence:** All threads execute the same number of iterations
>
> **Key insight:** Bitmasks trade a small amount of computation (cheap bitwise ops) for massive memory savings and better cache utilization. On GPUs with thousands of threads, keeping data compact is often more important than minimizing arithmetic operations!

**Code:**

```julia
function subset_sum_kernel!(sums, vecs, masks, vec_ids, lengths)
    idx = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    
    if idx <= length(masks)
        vec_id = vec_ids[idx]
        mask = masks[idx]
        n = lengths[vec_id]
        
        # Compute subset sum using bit mask
        s = zero(eltype(vecs))
        for i in 1:n
            if (mask >> (i-1)) & 1 == 1
                s += vecs[i, vec_id]
            end
        end
        sums[idx] = s
    end
    
    return nothing
end
```

---

### 4. Result Processing

**Mathematical Operation:** Given flattened sums array of length $\sum_i k_i$, partition into $M$ vectors and apply uniqueness:

$\text{result}_i = \text{unique}\left(\left\{\text{sum}(m) : m \in \text{masks}_i\right\}\right)$

> **🤔 Why Apply `unique()` if We Sample Without Replacement?**
>
> Great observation! We do sample masks without replacement, so why do we still need `unique()`?
>
> **The key insight:** Different subsets can have the **same sum**!
>
> **Example:** Consider vector $[1, 2, 3]$
> - Mask $3 = (011)_2$ → Subset $\{1, 2\}$ → Sum = $3$
> - Mask $4 = (100)_2$ → Subset $\{3\}$ → Sum = $3$
>
> Both masks are different (sampled without replacement), but they produce the **same subset sum**!
>
> **What sampling without replacement guarantees:**
> - All masks are distinct integers
> - No duplicate subsets in our sample
>
> **What it doesn't guarantee:**
> - Distinct sums (different subsets can sum to the same value)
>
> **In the subset sum problem:** We care about the set of **possible sums**, not the subsets themselves. So we need `unique()` to:
> 1. Remove duplicate sum values
> 2. Give us the actual set $S_i$ of achievable sums
>
> **Practical impact:** 
> - For **"nice" vectors** (distinct, random values): Collisions are rare! For small $n$, you might see 95-99%+ of sums being unique. The probability of duplicate sums grows as you sample more subsets, but remains relatively low.
> - For **structured vectors** (e.g., powers of 2 like $[1, 2, 4, 8]$): Every subset has a unique sum (by design)
> - For **vectors with repeated values** (e.g., $[1, 1, 2, 3]$): Collisions become much more common—potentially 30-50% duplicates
> - For **special cases** (e.g., many small integers, arithmetic sequences): Moderate collision rates
>
> The `unique()` call is cheap insurance—it's $O(k \log k)$ or $O(k)$ with hashing, negligible compared to the GPU computation cost!

**Code:**

```julia
function split_results(sums::Vector{T}, masks_needed::Vector{Int}) where T
    M = length(masks_needed)
    results = Vector{Vector{T}}(undef, M)
    
    offset = 1
    for (i, n_samples) in enumerate(masks_needed)
        range = offset:(offset + n_samples - 1)
        results[i] = unique(sums[range])
        offset += n_samples
    end
    
    return results
end
```

---

### 5. Main Pipeline

**Mathematical Operation:** For $M$ input vectors $\mathbf{v}_1, \mathbf{v}_2, \ldots, \mathbf{v}_M$ with lengths $n_1, n_2, \ldots, n_M$, compute approximations to the subset sum sets where we sample at most $\min(2^{n_i}, k)$ elements from each $S_i$.

**Computational Complexity:** $O\left(\sum_{i=1}^{M} k_i \cdot n_i\right)$ where $k_i = \min(2^{n_i}, k)$

**Code:**

```julia
function sample_subset_sums_batch_gpu(
    vectors::Vector{Vector{T}}, 
    num_samples_per_vec::Int
) where T
    # 1. Prepare data
    padded_vecs, lengths = prepare_padded_vectors(vectors)
    masks, vec_ids, masks_needed = generate_random_masks(lengths, num_samples_per_vec)
    
    # 2. Move to GPU
    d_vecs = CuArray(padded_vecs)
    d_lengths = CuArray(lengths)
    d_masks = CuArray(masks)
    d_vec_ids = CuArray(vec_ids)
    d_sums = CUDA.zeros(T, length(masks))
    
    # 3. Launch kernel
    threads = 256
    blocks = cld(length(masks), threads)
    @cuda threads=threads blocks=blocks subset_sum_kernel!(
        d_sums, d_vecs, d_masks, d_vec_ids, d_lengths
    )
    
    # 4. Process results
    sums_cpu = Array(d_sums)
    results = split_results(sums_cpu, masks_needed)
    
    return results
end
```

---

## Complete Example

For vectors `[[1.0, 2.0, 3.0], [4.0, 5.0]]` with `k = 8`:

**Vector 1** ($n_1 = 3$): All $2^3 = 8$ subsets sampled
- Masks: 0, 1, 2, 3, 4, 5, 6, 7
- Subsets: {}, {1.0}, {2.0}, {1.0,2.0}, {3.0}, {1.0,3.0}, {2.0,3.0}, {1.0,2.0,3.0}
- Sums: 0.0, 1.0, 2.0, 3.0, 3.0, 4.0, 5.0, 6.0
- Unique: {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0}

**Vector 2** ($n_2 = 2$): All $2^2 = 4$ subsets sampled
- Masks: 0, 1, 2, 3
- Subsets: {}, {4.0}, {5.0}, {4.0,5.0}
- Sums: 0.0, 4.0, 5.0, 9.0
- Unique: {0.0, 4.0, 5.0, 9.0}

**Usage:**

```julia
vectors = [[1.0, 2.0, 3.0], [4.0, 5.0], [6.0, 7.0, 8.0, 9.0]]
results = sample_subset_sums_batch_gpu(vectors, 1000)

# Ground truth for vector 1: [1.0, 2.0, 3.0]
# All 2^3 = 8 possible subsets and their sums:
# {} → 0.0
# {1.0} → 1.0
# {2.0} → 2.0
# {3.0} → 3.0
# {1.0, 2.0} → 3.0 (duplicate!)
# {1.0, 3.0} → 4.0
# {2.0, 3.0} → 5.0
# {1.0, 2.0, 3.0} → 6.0
# Unique sums: {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0} (7 values)

println("Subset sums for each vector:")
for (i, sums) in enumerate(results)
    println("Vector $i: $(length(sums)) unique sums")
end
```

---

## Key Implementation Details

1. **Memory Coalescing:** Column-major storage ensures adjacent threads access contiguous memory
2. **No Branching in Kernel:** Bitmask operations avoid expensive conditional logic
   
   > **🔀 Why Avoid Conditionals on GPUs?**
   >
   > Wait—doesn't the kernel have `if (mask >> (i-1)) & 1 == 1`? That's a conditional!
   >
   > **The crucial distinction:**
   > - **This conditional is uniform:** All threads checking the same position $i$ make the same decision (branch or not) since they're iterating through the same loop
   > - **Thread divergence** occurs when threads in the same warp take different execution paths
   >
   > **What we avoid:** Dynamic branching based on data values that differ across threads. For example:
   > ```julia
   > # BAD: Causes divergence
   > if vec_id == 1
   >     # do computation A
   > else
   >     # do computation B  
   > end
   > ```
   >
   > **What we have:** Structured loops where all threads execute the same instructions
   > ```julia
   > # GOOD: No divergence
   > for i in 1:n
   >     if (mask >> (i-1)) & 1 == 1  # All threads check same bit position
   >         s += vecs[i, vec_id]      # Some add, some don't, but no divergence
   >     end
   > end
   > ```
   >
   > **GPU architecture context:**
   > - GPUs execute threads in groups called **warps** (typically 32 threads)
   > - All threads in a warp execute the **same instruction** simultaneously (SIMT)
   > - When threads diverge, the GPU must execute both paths serially, disabling threads that don't match
   >
   > **Why bitmasks help:**
   > - The alternative would be storing explicit subset selections in memory
   > - Different threads would load different subset patterns → potential divergence
   > - Bitmask computation is **uniform across iterations** even if results differ
   >
   > **Performance impact:**
   > - No divergence: ~1-2 cycles per instruction
   > - Divergent branch: 2× the instructions (both paths executed serially)
   > - Our loop: Compiles to predicated instructions (conditional moves), avoiding true branches!

3. **Sampling Without Replacement:** Uses shuffle to ensure unique subsets
4. **Thread Configuration:** 256 threads per block balances occupancy and resource usage
5. **Type Genericity:** Works with any numeric type `T` (Float32, Float64, Int, etc.)
6. **GPU Advantage:** The $k_i$ subset sum computations happen in parallel, dramatically reducing wall-clock time compared to sequential CPU execution