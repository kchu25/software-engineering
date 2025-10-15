@def title = "GPU Memory Management for batched processing tasks"
@def published = "15 October 2025"
@def tags = ["julia", "gpu-programming"]


# GPU Memory Management - The Simple Version

## The Core Problem

Your GPU is super fast but has limited memory. If you try to process too much data at once, it crashes with an "Out Of Memory" (OOM) error. This code solves that problem automatically.

---

## The Main Idea: Smart Batching

Instead of processing everything at once, split your work into **batches** (chunks). The code figures out the optimal batch size by:

1. **Checking how much GPU memory is free**
2. **Looking at your data** (how big are the vectors?)
3. **Doing some math** to calculate: "How many vectors can I safely fit?"

If it guesses wrong and runs out of memory anyway, it **automatically cuts the batch size in half and tries again**.

---

## Three Key Strategies

### 1. **Prevention** 
Estimate the right batch size *before* starting, so you hopefully never run out of memory

### 2. **Recovery**
If you do run out of memory, catch the error, reduce batch size, and retry (instead of crashing)

### 3. **Adaptation**
If everything's going smoothly, *increase* the batch size to work faster

---

## Special Feature: Streaming Data

For datasets too big to load into RAM, the code can process a **generator** (data stream):
- Takes samples to understand what's coming
- Processes data as it arrives in batches
- Never loads the entire dataset at once

Think of it like washing dishes as they come in, rather than waiting for the whole stack.

---

## The Recovery Chain

When something goes wrong, there are **multiple safety nets**:

```
Try full batch
  ↓ (OOM error)
Cut batch in half, try again
  ↓ (still OOM)
Cut in half again
  ↓ (still OOM)
Process one item at a time
  ↓ (still failing?)
Give up and report error
```

It's like trying to fit through a door with a big box - if it doesn't fit, try a smaller box!

---

## Debug Helpers

The code also includes utilities to:
- Print GPU memory status (how much is used/free)
- Monitor memory changes during execution
- Force cleanup of old data
- Validate that your input data makes sense

These are like dashboard gauges showing you what's happening under the hood.

---

## Bottom Line

**You just call the function with your data, and it handles all the complexity:**
- Figures out optimal batch sizes
- Recovers from memory errors
- Adapts to your specific hardware
- Works with streaming data
- Shows you what's happening

**No manual tuning required** - it's designed to "just work" regardless of your GPU size or data characteristics.

---

## The Two Functions You Actually Use

**For regular data (already loaded):**
```julia
results = process_in_batches(my_function, vectors, targets)
```

**For streaming data (generator):**
```julia
# Same function! It detects generators automatically
results = process_in_batches(my_function, vector_generator, targets)
```

Everything else in the code is infrastructure that runs behind the scenes to make these two calls bulletproof.



-----


# GPU Memory Management --- now let's get started

This code handles the tricky problem of running calculations on a GPU without running out of memory. Think of it like managing a very fast but limited workspace - you need to be smart about what you put on it and when.

---

## Safe Memory Allocation

```julia
"""
Safe GPU computation with memory management
"""
function safe_gpu_alloc(f::Function, arrays...)
    # Just call the function and let Julia's GC handle cleanup
    # Manual unsafe_free! can cause race conditions
    result = f(arrays...)
    
    # Optionally trigger GC to free up memory sooner
    # But don't force unsafe_free! which can cause freed reference errors
    CUDA.reclaim()
    
    return result
end
```

This is a wrapper that runs your GPU function and then politely asks the GPU to clean up any memory it's not using anymore. It's like doing your work and then tidying up your desk - you don't want old stuff cluttering up the workspace.

---

## Smart Batch Processing

```julia
"""
Enhanced batch processing with generator support and memory-aware sizing
"""
function process_in_batches(f::Function, vectors, target_vals; batch_size=nothing, kwargs...)
    
    # Check if vectors is a generator or iterator
    if !isa(vectors, AbstractVector)
        # Handle generators without materializing
        println("🔄 Processing generator/iterator without materialization")
        return process_generator_in_batches(f, vectors, target_vals; batch_size=batch_size, kwargs...)
    end
    
    # Handle regular vectors (already materialized)
    num_vectors = length(vectors)
    
    if batch_size === nothing
        # Auto-calculate batch size based on memory analysis
        batch_size = estimate_optimal_batch_size(vectors, kwargs)
    end
    
    if batch_size >= num_vectors
        # No batching needed - try single batch first
        try
            return f(vectors, target_vals; kwargs...)
        catch e
            if isa(e, CUDA.OutOfGPUMemoryError)
                @warn "OOM in single batch, forcing batching with size $(num_vectors÷2)"
                batch_size = max(1, num_vectors ÷ 2)
            else
                rethrow(e)
            end
        end
    end
    
    # Process in batches with adaptive sizing
    results = Vector{Float32}(undef, num_vectors)
    
    return process_batches_with_recovery(f, vectors, target_vals, results, batch_size; kwargs...)
end
```

The main workhorse function. Instead of trying to process everything at once (which might overflow your GPU's memory), this breaks work into manageable chunks. It's like eating a pizza slice by slice instead of trying to stuff the whole thing in your mouth.

The clever part? It figures out the optimal batch size automatically by looking at:
- How much memory you have available
- How big your data is
- Whether you're dealing with a generator (streaming data) or already-loaded data

If you try to process too much at once and run out of memory, it automatically retries with smaller batches.

---

## Automatic Recovery from Memory Errors

```julia
"""
Process batches with automatic recovery from OOM errors
"""
function process_batches_with_recovery(f::Function, vectors, target_vals, results, 
                                     initial_batch_size; kwargs...)
    num_vectors = length(vectors)
    batch_size = initial_batch_size
    processed = 0
    
    while processed < num_vectors
        remaining = num_vectors - processed
        current_batch_size = min(batch_size, remaining)
        
        start_idx = processed + 1
        end_idx = processed + current_batch_size
        
        batch_vectors = vectors[start_idx:end_idx]
        batch_targets = target_vals[start_idx:end_idx]
        
        try
            # Attempt batch processing
            batch_results = f(batch_vectors, batch_targets; kwargs...)
            results[start_idx:end_idx] = batch_results
            processed += current_batch_size
            
            # Success - try to increase batch size for efficiency
            if current_batch_size < batch_size && remaining > current_batch_size
                batch_size = min(batch_size, Int(ceil(batch_size * 1.2)))
            end
            
        catch e
            if isa(e, CUDA.OutOfGPUMemoryError) && current_batch_size > 1
                # OOM - reduce batch size and retry
                new_batch_size = max(1, current_batch_size ÷ 2)
                @warn "GPU OOM at batch size $current_batch_size, reducing to $new_batch_size"
                batch_size = new_batch_size
                CUDA.reclaim()  # Force garbage collection
                continue
            else
                rethrow(e)
            end
        end
    end
    
    return results
end
```

This is the safety net. When processing batches, if the GPU runs out of memory (OOM = Out Of Memory), this function catches the error, cuts the batch size in half, and tries again. It even tries to *increase* batch size when things are going well, to work more efficiently.

---

## Memory Estimation

```julia
"""
Estimate optimal batch size based on vector characteristics and available memory
"""
function estimate_optimal_batch_size(vectors, kwargs)
    num_samples = get(kwargs, :num_samples_per_vec, DEFAULT_SAMPLES_PER_VECTOR)
    
    # Analyze vector length distribution
    lengths = length.(vectors)
    min_len, max_len = extrema(lengths)
    avg_len = mean(lengths)
    std_len = std(lengths)
    
    # Memory estimation for different scenarios
    small_vec_memory = estimate_memory_usage(1, num_samples, min_len)
    avg_vec_memory = estimate_memory_usage(1, num_samples, Int(ceil(avg_len)))
    large_vec_memory = estimate_memory_usage(1, num_samples, max_len)
    
    free_mem, total_mem = CUDA.memory_info()
    usable_memory = Int(floor(free_mem * MAX_GPU_MEMORY_FRACTION))
    
    # Conservative estimate using worst-case scenario (largest vectors)
    # but with some optimization for typical case
    if std_len / avg_len < 0.1  # Low variance in vector lengths
        target_memory = avg_vec_memory
    else
        # High variance - use weighted average biased toward larger vectors
        target_memory = Int(ceil(0.7 * avg_vec_memory + 0.3 * large_vec_memory))
    end
    
    batch_size = max(1, min(
        length(vectors),
        Int(floor(usable_memory / target_memory)),
        BATCH_PROCESSING_THRESHOLD
    ))
    
    @info "Memory analysis" free_mb=round(free_mem/1e6, digits=2) usable_mb=round(usable_memory/1e6, digits=2) target_mb_per_vec=round(target_memory/1e6, digits=4) estimated_batch_size=batch_size
    
    return batch_size
end
```

Before doing any real work, this function does some math to figure out the ideal batch size. It analyzes your vector lengths (shortest, longest, average), checks how much GPU memory is free, and estimates how much each calculation will need. If vectors are all similar sizes, it's more aggressive. If they vary wildly, it plays it safe.

---

## GPU Configuration Helpers

```julia
"""
Optimal thread/block configuration for given problem size
"""
function get_optimal_launch_config(problem_size::Int, max_threads::Int=DEFAULT_THREADS_PER_BLOCK)
    threads = min(max_threads, problem_size)
    blocks = cld(problem_size, threads)
    return threads, blocks
end

"""
Launch kernel with error handling and timing
"""
function launch_kernel_safe(kernel_func, args...; threads=DEFAULT_THREADS_PER_BLOCK, 
                           blocks=nothing, name="kernel")
    if blocks === nothing
        problem_size = length(args[1])  # Assume first arg determines size
        threads, blocks = get_optimal_launch_config(problem_size, threads)
    end
    
    try
        @cuda threads=threads blocks=blocks kernel_func(args...)
        CUDA.synchronize()
    catch e
        @error "Kernel $name failed" exception=e
        rethrow(e)
    end
end
```

GPUs work differently than regular CPUs - they run thousands of tiny workers (threads) organized into groups (blocks). These functions figure out the right number of workers and groups for your specific problem size, and provide safe execution with error handling.

---

## Data Validation

```julia
"""
Validate input data for GPU computation
"""
function validate_inputs(vectors, target_vals)
    @assert !isempty(vectors) "Input vectors cannot be empty"
    @assert length(vectors) == length(target_vals) "Vectors and target values must have same length"
    
    # Check for invalid vector lengths
    for (i, vec) in enumerate(vectors)
        @assert !isempty(vec) "Vector $i cannot be empty"
        @assert length(vec) <= MAX_SAFE_VECTOR_LENGTH "Vector $i too long ($(length(vec)) > $MAX_SAFE_VECTOR_LENGTH)"
    end
    
    # Check target values
    @assert all(isfinite, target_vals) "All target values must be finite"
end

"""
Validate GPU arrays for bounds checking
"""
function validate_gpu_arrays(d_sums, d_vec_ids, target_vals)
    vec_id_range = extrema(Array(d_vec_ids))
    @assert vec_id_range[1] >= 1 "Vector IDs must be >= 1, got $(vec_id_range[1])"
    @assert vec_id_range[2] <= length(target_vals) "Vector IDs must be <= $(length(target_vals)), got $(vec_id_range[2])"
end
```

Before doing any expensive GPU work, these functions check that your data makes sense: no empty vectors, vectors aren't absurdly long, you have matching target values, and all numbers are valid (not infinity or NaN). Catching problems early saves you from mysterious crashes later.

---

## Memory Monitoring Tools

```julia
"""
Print detailed GPU memory information
"""
function print_gpu_memory_info(label::String="")
    if !CUDA.functional()
        println("CUDA not available")
        return
    end
    
    free_mem, total_mem = CUDA.memory_info()
    used_mem = total_mem - free_mem
    
    println("GPU Memory Info $(label != "" ? "($label)" : ""):")
    println("  Total: $(round(total_mem/1e6, digits=1)) MB")
    println("  Used:  $(round(used_mem/1e6, digits=1)) MB ($(round(used_mem/total_mem*100, digits=1))%)")
    println("  Free:  $(round(free_mem/1e6, digits=1)) MB ($(round(free_mem/total_mem*100, digits=1))%)")
end

"""
Monitor memory usage during function execution
"""
function with_memory_monitoring(f::Function, label::String="")
    if !CUDA.functional()
        return f()
    end
    
    # Initial memory state
    free_before, total_mem = CUDA.memory_info()
    used_before = total_mem - free_before
    
    println("Starting $label")
    print_gpu_memory_info("before")
    
    # Execute function
    start_time = time()
    result = f()
    end_time = time()
    
    # Final memory state
    free_after, _ = CUDA.memory_info()
    used_after = total_mem - free_after
    
    print_gpu_memory_info("after")
    println("Memory change: $(round((used_after - used_before)/1e6, digits=2)) MB")
    println("Execution time: $(round(end_time - start_time, digits=3)) seconds")
    
    return result
end

"""
Force GPU garbage collection and print memory stats
"""
function cleanup_gpu_memory(label::String="")
    if !CUDA.functional()
        return
    end
    
    print_gpu_memory_info("before cleanup")
    
    # Force cleanup
    CUDA.reclaim()
    GC.gc()
    sleep(0.1)  # Give time for cleanup
    
    print_gpu_memory_info("after cleanup")
end

"""
Calculate recommended batch size based on current GPU memory state
"""
function get_recommended_batch_size(vectors, num_samples_per_vec::Int)
    if !CUDA.functional()
        return length(vectors)
    end
    
    # Current memory state
    free_mem, total_mem = CUDA.memory_info()
    usable_mem = Int(floor(free_mem * MAX_GPU_MEMORY_FRACTION))
    
    # Vector characteristics
    lengths = length.(vectors)
    avg_len = mean(lengths)
    max_len = maximum(lengths)
    
    # Conservative estimate using largest vectors
    memory_per_vector = estimate_memory_usage(1, num_samples_per_vec, max_len)
    max_vectors = max(1, Int(floor(usable_mem / memory_per_vector)))
    
    recommended_batch_size = min(max_vectors, length(vectors))
    
    println("Batch size recommendation:")
    println("  Available memory: $(round(usable_mem/1e6, digits=1)) MB")
    println("  Memory per vector (worst case): $(round(memory_per_vector/1e6, digits=3)) MB")
    println("  Max vectors per batch: $max_vectors")
    println("  Recommended batch size: $recommended_batch_size")
    
    return recommended_batch_size
end
```

Debugging tools that show you exactly what's happening with GPU memory. They print formatted stats (total/used/free memory), monitor memory changes during execution, force cleanup when needed, and recommend batch sizes. Super helpful when troubleshooting!

---

## Generator Processing (Part 1: Estimation)

```julia
"""
Estimate batch size by sampling from generator without materializing entire dataset
"""
function estimate_batch_size_from_generator(vector_generator, target_vals; 
                                          num_samples_per_vec::Int = 10000,
                                          sample_size::Int = 50)
    
    # Sample a few vectors to estimate characteristics
    sample_vectors = Vector{Vector{Float32}}()
    count = 0
    for vec in vector_generator
        push!(sample_vectors, vec)
        count += 1
        if count >= sample_size
            break
        end
    end
    
    if isempty(sample_vectors)
        error("Generator appears to be empty")
    end
    
    # Analyze sample characteristics
    lengths = length.(sample_vectors)
    min_len, max_len = extrema(lengths)
    avg_len = mean(lengths)
    std_len = std(lengths)
    
    # Estimate total count (if target_vals is available)
    total_count = length(target_vals)
    
    # Memory estimation using worst-case scenario
    target_memory_per_vec = estimate_memory_usage(1, num_samples_per_vec, max_len)
    
    free_mem, _ = CUDA.memory_info()
    usable_memory = Int(floor(free_mem * MAX_GPU_MEMORY_FRACTION))
    
    batch_size = max(1, min(
        total_count,
        Int(floor(usable_memory / target_memory_per_vec)),
        BATCH_PROCESSING_THRESHOLD
    ))
    
    println("🔍 Generator analysis (sampled $count vectors):")
    println("  Vector lengths: $min_len - $max_len (avg: $(round(avg_len, digits=1)))")
    println("  Estimated total vectors: $total_count")
    println("  Memory per vector (worst case): $(round(target_memory_per_vec/1e6, digits=3)) MB")
    println("  Recommended batch size: $batch_size")
    
    return batch_size, avg_len, max_len
end
```

---

## Generator Processing (Part 2: Batch Processing)

```julia
"""
Process generator in batches without materializing the entire dataset
"""
function process_generator_in_batches(f::Function, vector_generator, target_vals;
                                    batch_size=nothing, kwargs...)
    
    total_vectors = length(target_vals)
    
    if batch_size === nothing
        batch_size, _, _ = estimate_batch_size_from_generator(vector_generator, target_vals; 
                                                           get(kwargs, :num_samples_per_vec, DEFAULT_SAMPLES_PER_VECTOR))
    end
    
    if batch_size >= total_vectors
        # Single batch - collect only once
        println("📦 Processing all $total_vectors vectors in single batch")
        return f(collect(vector_generator), target_vals; kwargs...)
    end
    
    # Process in batches
    println("📦 Processing $total_vectors vectors in batches of size $batch_size")
    results = Vector{Float32}(undef, total_vectors)
    
    batch_vectors = Vector{Vector{Float32}}()
    current_batch_size = 0
    batch_start_idx = 1
    batch_count = 0
    
    for (idx, vec) in enumerate(vector_generator)
        push!(batch_vectors, vec)
        current_batch_size += 1
        
        # Process batch when it's full or we've reached the end
        if current_batch_size >= batch_size || idx >= total_vectors
            batch_end_idx = batch_start_idx + current_batch_size - 1
            batch_range = batch_start_idx:batch_end_idx
            
            batch_count += 1
            expected_batches = cld(total_vectors, batch_size)
            
            println("  Processing batch $batch_count/$expected_batches: vectors $(batch_start_idx)-$(batch_end_idx)")
            
            try
                # Process current batch
                batch_target_vals = @view target_vals[batch_range]
                batch_results = process_batch_with_recovery(f, batch_vectors, batch_target_vals, 
                                                          current_batch_size; kwargs...)
                
                results[batch_range] = batch_results
                
                println("    ✅ Batch $batch_count completed successfully")
                
            catch e
                println("    ❌ Batch $batch_count failed: $e")
                rethrow(e)
            end
            
            # Reset for next batch
            empty!(batch_vectors)
            current_batch_size = 0
            batch_start_idx = batch_end_idx + 1
            
            # Optional memory cleanup between batches
            CUDA.reclaim()
        end
        
        # Progress update
        if idx % max(1, total_vectors ÷ 20) == 0  # Update every 5%
            progress = round(idx / total_vectors * 100, digits=1)
            println("    Progress: $progress% ($idx/$total_vectors vectors)")
        end
    end
    
    return results
end
```

---

## Recursive Batch Recovery

```julia
"""
Process a single batch with automatic size reduction on OOM
"""
function process_batch_with_recovery(f::Function, batch_vectors, batch_target_vals, 
                                   original_batch_size; max_retries::Int = 3, kwargs...)
    
    current_vectors = batch_vectors
    current_targets = batch_target_vals
    retry_count = 0
    
    while retry_count <= max_retries
        try
            return f(current_vectors, current_targets; kwargs...)
            
        catch e
            if isa(e, CUDA.OutOfGPUMemoryError) && retry_count < max_retries
                retry_count += 1
                
                # Reduce batch size by half
                new_size = max(1, length(current_vectors) ÷ 2)
                println("      🔄 OOM detected, reducing batch size to $new_size (attempt $retry_count)")
                
                if new_size < length(current_vectors)
                    # Split the batch and process recursively
                    mid_point = new_size
                    
                    # Process first half
                    first_half_vectors = current_vectors[1:mid_point]
                    first_half_targets = current_targets[1:mid_point]
                    first_results = process_batch_with_recovery(f, first_half_vectors, first_half_targets,
                                                              mid_point; max_retries=max_retries-retry_count, kwargs...)
                    
                    # Process second half
                    second_half_vectors = current_vectors[mid_point+1:end]
                    second_half_targets = current_targets[mid_point+1:end]
                    second_results = process_batch_with_recovery(f, second_half_vectors, second_half_targets,
                                                               length(second_half_vectors); max_retries=max_retries-retry_count, kwargs...)
                    
                    # Combine results
                    return vcat(first_results, second_results)
                else
                    # Cannot reduce further
                    println("      ❌ Cannot reduce batch size further (size=1)")
                    rethrow(e)
                end
                
                CUDA.reclaim()  # Force cleanup before retry
                
            else
                rethrow(e)
            end
        end
    end
    
    error("Maximum retries exceeded for batch processing")
end
```

The ultimate safety net! If a batch causes out-of-memory, this recursively splits it in half and processes each part separately (which may split again if needed). It's like a binary search for the maximum batch size your GPU can handle. Gives up after 3 retries to avoid infinite loops.

## Recursive Batch Recovery

```julia
function process_batch_with_recovery(f::Function, batch_vectors, batch_target_vals, 
                                   original_batch_size; max_retries::Int = 3, kwargs...)
    
    current_vectors = batch_vectors
    current_targets = batch_target_vals
    retry_count = 0
    
    while retry_count <= max_retries
        try
            return f(current_vectors, current_targets; kwargs...)
            
        catch e
            if isa(e, CUDA.OutOfGPUMemoryError) && retry_count < max_retries
                retry_count += 1
                
                # Reduce batch size by half
                new_size = max(1, length(current_vectors) ÷ 2)
                println("      🔄 OOM detected, reducing batch size to $new_size (attempt $retry_count)")
                
                if new_size < length(current_vectors)
                    # Split the batch and process recursively
                    mid_point = new_size
                    
                    # Process first half
                    first_half_vectors = current_vectors[1:mid_point]
                    first_half_targets = current_targets[1:mid_point]
                    first_results = process_batch_with_recovery(f, first_half_vectors, first_half_targets,
                                                              mid_point; max_retries=max_retries-retry_count, kwargs...)
                    
                    # Process second half
                    second_half_vectors = current_vectors[mid_point+1:end]
                    second_half_targets = current_targets[mid_point+1:end]
                    second_results = process_batch_with_recovery(f, second_half_vectors, second_half_targets,
                                                               length(second_half_vectors); max_retries=max_retries-retry_count, kwargs...)
                    
                    # Combine results
                    return vcat(first_results, second_results)
                else
                    # Cannot reduce further
                    println("      ❌ Cannot reduce batch size further (size=1)")
                    rethrow(e)
                end
                
                CUDA.reclaim()  # Force cleanup before retry
                
            else
                rethrow(e)
            end
        end
    end
    
    error("Maximum retries exceeded for batch processing")
end

```

The ultimate safety net. If a batch causes an out-of-memory error, this function:
1. Splits the batch in half
2. Processes each half separately (which may split again if needed)
3. Combines the results back together
4. Gives up after 3 retries to avoid infinite loops

It's like a binary search for the maximum batch size your GPU can handle with this specific data.

---

## The Big Picture

All these functions work together to make GPU computation robust and automatic. You don't need to manually figure out batch sizes or worry about running out of memory - the code adapts to your hardware and data automatically. If something goes wrong, it recovers gracefully instead of crashing. It's defensive programming at its finest!