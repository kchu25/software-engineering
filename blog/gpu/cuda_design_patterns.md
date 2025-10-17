@def title = "CUDA Design Patterns: A Friendly Guide"
@def published = "17 October 2025"
@def tags = ["gpu-programming", "cuda", "julia"]

# CUDA Design Patterns: A Friendly Guide

So you know the basics of CUDA kernels? Great! Let's talk about the patterns that separate "it works" code from "it flies" code.

## 1. Memory Coalescing: The Golden Rule

**The big idea**: GPUs love when neighboring threads access neighboring memory locations. It's like carpooling – one memory transaction can serve 32 threads at once.

> **What "Coalesced" Actually Means** (the dead simple version):
>
> Imagine 32 friends going to a library. They need books from the shelves.
>
> **COALESCED** ✅: They all stand in a line and each person grabs the book right in front of them.  
> → Librarian brings ONE cart with 32 consecutive books. Done in one trip!
>
> **NOT COALESCED** ❌: Person 1 wants a book from shelf A, person 2 wants one from shelf Z, person 3 wants one from shelf M...  
> → Librarian has to make 32 separate trips. Nightmare!
>
> **In GPU terms**: 
> - Thread 0, 1, 2, 3... accessing `array[0], array[1], array[2], array[3]...` = **ONE memory transaction** ✅
> - Thread 0, 1, 2, 3... accessing `array[0], array[1000], array[2000], array[3000]...` = **32 separate transactions** ❌
>
> **Wait, what about uniform spacing?**
> - `array[0], array[2], array[4], array[6]...` (every other element) = Still pretty good! GPU can fetch in 2 transactions instead of 32
> - `array[0], array[4], array[8], array[12]...` (stride of 4 for float32) = Perfect! Still just 1 transaction (they fit in one 128-byte chunk)
> 
> **The rule**: Distance DOES matter, but there's a sweet spot:
> - **Stride 1** (consecutive): BEST - always 1 transaction
> - **Small strides** (2-4): GOOD - fits in 1-2 cache lines (128 bytes)
> - **Large strides** (100+): BAD - each needs its own transaction
>
> Think of it like: the GPU fetches memory in big 128-byte chunks (like loading a whole bookshelf section). If your 32 threads all want books from the same section, great! If they're scattered across the entire library? Pain.

### Real Example: Processing RGB Images

Say you have an image stored as `[R1, G1, B1, R2, G2, B2, R3, G3, B3, ...]` and you want to extract just the red channel.

**Bad pattern** (what feels natural):
```julia
using CUDA

# Input: [R1,G1,B1, R2,G2,B2, R3,G3,B3, ...]
# Want: [R1, R2, R3, ...]
function extract_red_bad!(output, rgb_image)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    
    if i <= length(output)
        # Thread 0 reads position 0 (R1)
        # Thread 1 reads position 3 (R2)  
        # Thread 2 reads position 6 (R3)
        # Threads jump by 3 - NOT coalesced!
        output[i] = rgb_image[3 * (i - 1) + 1]
    end
    return
end
```

**Good pattern** (think differently about the problem):
```julia
# Instead: have each thread read consecutive elements,
# then sort them out afterward
function extract_red_good!(output, rgb_image)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    
    if i <= length(rgb_image)
        # Thread 0 reads position 0 (R1)
        # Thread 1 reads position 1 (G1)
        # Thread 2 reads position 2 (B1)
        # Thread 3 reads position 3 (R2) - COALESCED!
        
        val = rgb_image[i]
        
        # Only every 3rd thread writes (when we hit a red pixel)
        if (i - 1) % 3 == 0
            output[(i - 1) ÷ 3 + 1] = val
        end
    end
    return
end
```

**Why it matters**: The bad version does 32 separate memory loads. The good version does 1 memory transaction that loads 32 consecutive values. That's potentially 32x less memory traffic!

### Another Real Example: Struct of Arrays vs Array of Structs

You're processing particles with position and velocity:

**Bad** (Array of Structs - AoS):
```julia
struct Particle
    x::Float32
    y::Float32
    z::Float32
    vx::Float32
    vy::Float32
    vz::Float32
end

function update_positions_bad!(particles, dt)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    
    if i <= length(particles)
        # Thread 0 wants x at byte 0
        # Thread 1 wants x at byte 24 (6 floats later)
        # Memory is scattered!
        p = particles[i]
        particles[i] = Particle(
            p.x + p.vx * dt,
            p.y + p.vy * dt,
            p.z + p.vz * dt,
            p.vx, p.vy, p.vz
        )
    end
    return
end
```

**Good** (Struct of Arrays - SoA):
```julia
struct ParticlesSoA
    x::CuDeviceVector{Float32}
    y::CuDeviceVector{Float32}
    z::CuDeviceVector{Float32}
    vx::CuDeviceVector{Float32}
    vy::CuDeviceVector{Float32}
    vz::CuDeviceVector{Float32}
end

function update_positions_good!(particles, dt)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    
    if i <= length(particles.x)
        # Thread 0 reads x[0], thread 1 reads x[1], etc.
        # All consecutive! Perfect coalescing!
        particles.x[i] += particles.vx[i] * dt
        particles.y[i] += particles.vy[i] * dt
        particles.z[i] += particles.vz[i] * dt
    end
    return
end
```

**The tradeoff**: SoA feels weird in CPU code but is gold for GPUs. If you only need to update X positions, you don't even load the Y and Z arrays!

### When Coalescing is Hard (and that's okay!)

Sometimes you genuinely need random access - like in a hash table lookup or tree traversal. In those cases:
- Use texture memory (has a cache)
- Batch your random accesses
- Or just accept it and optimize something else

Not every memory access can be coalesced, but the ones in your hot loops? Those are worth the effort.

## 2. Shared Memory: Your On-Chip Cache

**The big idea**: Shared memory is like a scratchpad shared by all threads in a block. It's 100x faster than global memory but tiny (48-96 KB).

> **The Shared Memory Recipe**:
> 
> 1. **Pick TILE size**: Almost always **16, 32, or 64**
>    - Why these numbers? They're multiples of 32 (warp size) and powers of 2
>    - Most common: **TILE=32** (sweet spot for most GPUs)
>    - Rule of thumb: `TILE × TILE × sizeof(element)` should be < 48KB
>    - Example: 32×32 floats = 4KB ✅, 128×128 floats = 64KB ❌ (too big!)
>
> 2. **Launch with TILE×TILE threads per block**
>    - For TILE=32: launch with `threads=(32,32)` → 1024 threads per block
>
> 3. **The loading pattern** (YES, this should be coalesced!):
>    - Each thread loads ONE element from global → shared
>    - Thread positions map directly: `tile[threadIdx.y, threadIdx.x] = input[global_y, global_x]`
>    - This is naturally coalesced because consecutive thread IDs access consecutive memory
>
> 4. **The using pattern** (can be whatever you want!):
>    - After `sync_threads()`, read from shared memory however you like
>    - Shared memory is fast enough that "uncoalesced" patterns are fine here

**Classic use case** – Matrix transpose:
```julia
function transpose_shared!(output, input, width, height)
    TILE = 32  # The magic number - try 16, 32, or 64
    
    # Allocate shared memory: TILE×TILE elements
    tile = @cuDynamicSharedMem(Float32, (TILE, TILE))
    
    # The typical 2D index pattern:
    tx = threadIdx().x  # Local thread position in block (1 to 32)
    ty = threadIdx().y  # Local thread position in block (1 to 32)
    
    # Global position in the input matrix
    i = tx + (blockIdx().x - 1) * TILE  # Global column
    j = ty + (blockIdx().y - 1) * TILE  # Global row
    
    # STEP 1: Load from global memory (COALESCED!)
    # Each thread grabs one element from input[j, i]
    if i <= width && j <= height
        tile[ty, tx] = input[j, i]
        #    ↑   ↑          ↑  ↑
        #  local coords   global coords
    end
    
    sync_threads()  # ⚠️ CRITICAL: Wait for all threads to finish loading!
    
    # STEP 2: Write to output with coordinates swapped (ALSO COALESCED!)
    # The transpose happens in shared memory indexing
    i_out = ty + (blockIdx().x - 1) * TILE  # Notice: ty becomes i_out
    j_out = tx + (blockIdx().y - 1) * TILE  # Notice: tx becomes j_out
    
    if i_out <= height && j_out <= width
        output[j_out, i_out] = tile[tx, ty]
        #                           ↑   ↑
        #                      Swap the indices!
    end
    
    return
end

# Launch it - CRITICAL: threads must match TILE!
# @cuda threads=(32,32) blocks=(ceil(Int,width/32), ceil(Int,height/32)) transpose_shared!(out, in, w, h)
#              ↑↑  ↑↑                    ↑↑          ↑↑
#              Must match TILE=32!
```

> **Pro Tip: Avoid the TILE/threads mismatch bug!**
>
> The #1 bug with shared memory kernels: `TILE` in the kernel doesn't match `threads` at launch.
>
> **Bad** (easy to mess up):
> ```julia
> TILE = 32  # inside kernel
> @cuda threads=(16,16) ...  # Oops! Mismatch = wrong results or crash
> ```
>
> **Better** (programmatic consistency):
> ```julia
> const TILE = 32  # Define once as a constant
> 
> function transpose_shared!(output, input, width, height)
>     tile = @cuDynamicSharedMem(Float32, (TILE, TILE))
>     # ... rest of kernel uses TILE
> end
> 
> # Launch using the SAME constant
> @cuda threads=(TILE,TILE) blocks=(ceil(Int,width/TILE), ceil(Int,height/TILE)) \
>     transpose_shared!(out, in, w, h)
> ```
>
> **Best** (wrapper function that can't go wrong):
> ```julia
> function launch_transpose(output, input, width, height; TILE=32)
>     threads = (TILE, TILE)
>     blocks = (ceil(Int, width/TILE), ceil(Int, height/TILE))
>     
>     @cuda threads=threads blocks=blocks shmem=TILE*TILE*sizeof(Float32) \
>         transpose_shared!(output, input, width, height)
> end
> 
> # Now just call:
> launch_transpose(out, in, w, h)  # Can't mess it up!
> ```
>
> The wrapper pattern is bulletproof - TILE is defined once and used everywhere automatically.

**The i,j pattern explained**:
- `tx, ty`: Where am I in my thread block? (1-32 for each)
- `i, j`: Where am I in the global matrix? (could be anywhere)
- Load uses `input[j, i]` with global coords
- Store uses `tile[ty, tx]` with local coords
- Then flip everything for the transpose!

**Why this works**: 
- Loading `input[y,x]` row by row = coalesced ✅
- Writing `output[y_out,x_out]` row by row = coalesced ✅  
- The transpose happens in the shared memory indexing (swapping threadIdx.x and threadIdx.y)
- Without shared memory, either the read OR write would be uncoalesced (column access) = 32x slower!

## 3. Warp-Level Primitives: Free Synchronization

**The big idea**: 32 threads (a "warp") execute in lockstep. You can shuffle data between them without slow synchronization.

**Example** – Sum reduction within a warp:
```julia
function warp_reduce_sum(val)
    # Threads can share data within a warp for free!
    for offset in [16, 8, 4, 2, 1]
        val += shfl_down_sync(0xffffffff, val, offset)
    end
    return val
end

function block_sum_kernel!(output, input)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    
    # Each thread loads one value
    val = i <= length(input) ? input[i] : 0.0f0
    
    # Reduce within warp (no __syncthreads needed!)
    val = warp_reduce_sum(val)
    
    # First thread in each warp writes result
    if threadIdx().x % 32 == 1
        warp_id = (threadIdx().x - 1) ÷ 32 + 1
        @inbounds output[warp_id + (blockIdx().x - 1) * 32] = val
    end
    
    return
end
```

**Why it's awesome**: No synchronization barriers, no shared memory needed for simple reductions.

## 4. Occupancy: Keep Those Cores Busy

**The big idea**: GPUs have thousands of cores. If you don't give them enough work, they sit idle.

**The tradeoff**:
- More threads per block = better occupancy
- More shared memory per block = fewer blocks fit on the GPU

```julia
# Calculate theoretical occupancy
function analyze_kernel()
    threads_per_block = 256
    shared_mem_per_block = 48 * 1024  # 48 KB
    
    # CUDA.jl can tell you occupancy
    kernel = @cuda launch=false my_kernel!(args...)
    occupancy = CUDA.occupancy(kernel, threads_per_block, 
                               shmem=shared_mem_per_block)
    
    println("Occupancy: $(occupancy.active_blocks) blocks active")
end
```

**Rule of thumb**: Aim for at least 128 threads per block, ideally 256-512. But measure!

## 5. Memory Access Patterns: Bank Conflicts

**The big idea**: Shared memory is divided into 32 "banks". If multiple threads in a warp access the same bank (but different addresses), they serialize (slow!).

> **What are banks?** Think of shared memory like a bank with 32 teller windows. Each "address" goes to a specific bank:
> - `shared[0]` → Bank 0
> - `shared[1]` → Bank 1
> - `shared[32]` → Bank 0 (wraps around!)
> - `shared[33]` → Bank 1
> 
> **Formula**: `bank_id = (address / 4) % 32` for 4-byte elements (Float32)
>
> If 2 threads in a warp want different addresses from the same bank → they have to wait in line (serialized)!

**Real example** – Why matrix transpose has bank conflicts:

```julia
function transpose_with_conflicts!(output, input, width, height)
    TILE = 32
    tile = @cuDynamicSharedMem(Float32, (TILE, TILE))  # 32×32 array
    
    tx = threadIdx().x
    ty = threadIdx().y
    
    # Load data (no conflicts here - different rows)
    tile[ty, tx] = input[...]
    sync_threads()
    
    # PROBLEM: Write transposed
    output[...] = tile[tx, ty]
    #                  ↑   ↑
    #            Reading COLUMNS now!
    
    # When tx=1, ty varies from 1 to 32:
    # Thread 0 reads tile[1, 1]  → address 1   → Bank 1
    # Thread 1 reads tile[1, 2]  → address 33  → Bank 1  (conflict!)
    # Thread 2 reads tile[1, 3]  → address 65  → Bank 1  (conflict!)
    # ...
    # All 32 threads hit Bank 1! They serialize = 32x slower
end
```

**Why does this happen?**
- Julia stores arrays column-major: `tile[row, col]`
- Elements in the same column are 32 elements apart: `tile[1,1]` to `tile[2,1]` = +32 addresses
- +32 addresses = same bank (because banks wrap every 32)
- When you read a column, all threads hit the same bank!

**The fix** – Add padding:

```julia
function transpose_no_conflicts!(output, input, width, height)
    TILE = 32
    # Add +1 to one dimension (padding)
    tile = @cuDynamicSharedMem(Float32, (TILE, TILE + 1))  # 32×33 array (wastes 32 floats)
    
    tx = threadIdx().x
    ty = threadIdx().y
    
    # Load (still works fine, just ignore column 33)
    tile[ty, tx] = input[...]
    sync_threads()
    
    # Write transposed (NOW no conflicts!)
    output[...] = tile[tx, ty]
    
    # Why it works:
    # Thread 0 reads tile[1, 1]  → address 1   → Bank 1
    # Thread 1 reads tile[1, 2]  → address 34  → Bank 2  (no conflict!)
    # Thread 2 reads tile[1, 3]  → address 67  → Bank 3  (no conflict!)
    # The +1 padding shifts everything, spreading across different banks!
end
```

**Another example** – Reduction with bank conflicts:

```julia
# BAD: Power-of-2 stride causes bank conflicts
function reduce_bad!(data)
    shared = @cuDynamicSharedMem(Float32, 256)
    tid = threadIdx().x
    
    shared[tid] = data[tid]
    sync_threads()
    
    # Reduce with stride=1, 2, 4, 8, 16, 32...
    stride = 1
    while stride < 256
        if tid <= 256 ÷ (2 * stride)
            # Thread 0 reads shared[1] and shared[1+stride]
            # When stride=16: all active threads read 16 elements apart
            # 16 apart → same banks → CONFLICTS!
            shared[tid] = shared[tid] + shared[tid + stride]
        end
        stride *= 2
        sync_threads()
    end
end

# GOOD: Sequential addressing avoids conflicts
function reduce_good!(data)
    shared = @cuDynamicSharedMem(Float32, 256)
    tid = threadIdx().x
    
    shared[tid] = data[tid]
    sync_threads()
    
    # Reduce with sequential indices
    stride = 128
    while stride > 0
        if tid <= stride
            # Thread 0 reads shared[0] and shared[128]
            # Thread 1 reads shared[1] and shared[129]
            # All consecutive = different banks = NO CONFLICTS!
            shared[tid] = shared[tid] + shared[tid + stride]
        end
        stride ÷= 2
        sync_threads()
    end
end
```

**When to worry about bank conflicts:**
- ✅ When reading/writing columns of 2D arrays in shared memory
- ✅ When accessing with power-of-2 strides (2, 4, 8, 16, 32...)
- ❌ When reading rows (consecutive access = different banks naturally)
- ❌ When each thread reads a different location (no conflict if different banks)

**The quick fix**: Add `+1` padding to one dimension. Wastes a tiny bit of memory but can give huge speedups!

## 6. Stream Processing: Overlap Everything

**The big idea**: GPUs can compute while copying data. Use streams to overlap operations.

```julia
# Create multiple streams
streams = [CuStream() for _ in 1:4]

# Launch work on different streams
for (i, stream) in enumerate(streams)
    # Each stream can work independently
    d_input = CuArray{Float32}(data_chunks[i])
    d_output = similar(d_input)
    
    @cuda stream=stream threads=256 blocks=N my_kernel!(d_output, d_input)
    
    # This can happen while GPU is computing
    results[i] = Array(d_output)
end

# Synchronize all streams
foreach(synchronize, streams)
```

**Win**: CPU-GPU transfers happen while other streams compute. Total time goes down.

## 7. The Grid-Stride Loop: Scale to Any Data Size

**The big idea**: Don't assume you have enough threads for all data. Loop if needed.

```julia
function flexible_kernel!(output, input)
    # Global thread index
    idx = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    stride = blockDim().x * gridDim().x
    
    # Each thread handles multiple elements if needed
    while idx <= length(input)
        output[idx] = process(input[idx])
        idx += stride
    end
    
    return
end
```

**Why**: Works with any data size, easy to tune block/grid dimensions for performance.

## Quick Checklist for Fast CUDA Code

1. ✅ Memory accesses coalesced?
2. ✅ Using shared memory for reused data?
3. ✅ Avoiding shared memory bank conflicts?
4. ✅ Occupancy above 50%?
5. ✅ Grid-stride loop for flexibility?
6. ✅ Using streams for overlap?

## The Reality Check

Start simple. Measure. Then optimize. Premature optimization is real – sometimes the "bad" pattern is fast enough and way easier to maintain.

Use Julia's `CUDA.@profile` to see where time actually goes. You'll be surprised what matters!

```julia
CUDA.@profile @cuda threads=256 blocks=1000 my_kernel!(output, input)
```

Happy GPU hacking! 🚀