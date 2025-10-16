@def title = "GPU Memory Management for batched processing tasks -- II"
@def published = "16 October 2025"
@def tags = ["julia", "gpu-programming"]

# GPU Memory Management Guide 

This code provides a comprehensive set of utilities for managing GPU memory when computing Banzhaf values. Think of it as a safety system that prevents your GPU from running out of memory while processing large datasets.

---

## Memory Management Functions

### Safe GPU Allocation

```julia
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

**What it does:** This is a wrapper function that safely executes GPU computations. Instead of manually freeing memory (which can cause crashes), it lets Julia's garbage collector handle cleanup naturally. After the computation finishes, it calls `CUDA.reclaim()` to gently suggest freeing up unused memory, but doesn't force it.

---

### Batch Processing with Smart Memory Management

```julia
function process_in_batches(f::Function, vectors, target_vals; batch_size=nothing, kwargs...)
    
    # Handle regular vectors (collections)
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

**What it does:** This is the main coordinator for batch processing. When you have too much data to process at once, it breaks the work into smaller chunks. Here's the smart part: if you don't specify a batch size, it automatically figures out the optimal size based on available GPU memory. It first tries to process everything in one go, and if that fails due to memory issues, it automatically switches to batching mode by cutting the batch size in half.

---

### Automatic Recovery from Memory Errors

```julia
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

**What it does:** This is the resilient workhorse that actually processes the batches. It's adaptive and self-healing. If a batch succeeds, it tries to increase the batch size by 20% to speed things up. If it runs out of memory, it cuts the batch size in half and tries again. It keeps going until all vectors are processed, adjusting its strategy based on what's actually working. Think of it as a smart loader that learns the GPU's limits in real-time.

---

### Intelligent Batch Size Estimation

```julia
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

**What it does:** This function is like a smart planner that looks at your data before processing. It analyzes how big your vectors are, checks how consistent they are in size, and estimates how much memory each will need. If your vectors are all similar sizes, it uses the average for estimation. If they vary a lot, it's more conservative and plans for larger vectors (70% average, 30% maximum size). Finally, it calculates how many vectors can fit in available GPU memory, ensuring it doesn't exceed safe limits.

---

## GPU Utilities

### Optimal Thread Configuration

```julia
function get_optimal_launch_config(problem_size::Int, max_threads::Int=DEFAULT_THREADS_PER_BLOCK)
    threads = min(max_threads, problem_size)
    blocks = cld(problem_size, threads)
    return threads, blocks
end
```

**What it does:** When launching GPU kernels, you need to organize work into threads and blocks. This function calculates the best configuration for your problem size. It figures out how many threads per block to use (capped at the maximum) and how many blocks you need to cover all the work.

---

### Safe Kernel Launching

```julia
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

**What it does:** This wraps GPU kernel launches with safety checks and error handling. If you don't specify thread/block configuration, it automatically calculates the optimal setup. It catches any errors during kernel execution and provides helpful error messages with the kernel name, making debugging easier.

---

## Data Validation

### Input Validation

```julia
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
```

**What it does:** Before processing, this function performs sanity checks on your input data. It verifies that vectors aren't empty, that you have the same number of vectors as target values, that no vector is too long for safe processing, and that all target values are valid numbers (not infinity or NaN). This catches problems early before they cause cryptic GPU errors.

---

### GPU Array Validation

```julia
function validate_gpu_arrays(d_sums, d_vec_ids, target_vals)
    vec_id_range = extrema(Array(d_vec_ids))
    @assert vec_id_range[1] >= 1 "Vector IDs must be >= 1, got $(vec_id_range[1])"
    @assert vec_id_range[2] <= length(target_vals) "Vector IDs must be <= $(length(target_vals)), got $(vec_id_range[2])"
end
```

**What it does:** This validates GPU arrays to ensure vector IDs are within valid bounds. It prevents array out-of-bounds errors by checking that all vector IDs are between 1 and the number of target values. This is crucial for preventing crashes during GPU kernel execution.

---

## GPU Monitoring and Debugging

### Memory Information Display

```julia
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
```

**What it does:** This is a diagnostic tool that prints a nice summary of GPU memory status. It shows total, used, and free memory in megabytes and percentages. You can add a label to identify different points in your code. Super useful for tracking down memory leaks or understanding memory usage patterns.

---

### Memory Monitoring Wrapper

```julia
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
```

**What it does:** This is like putting a stopwatch and memory tracker around any function. It captures memory state before and after execution, measures how long it takes, and reports the memory change. Perfect for profiling and understanding which operations consume the most memory and time.

---

### Force GPU Cleanup

```julia
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
```

**What it does:** When you need to aggressively free GPU memory, this function forces both GPU and CPU garbage collection, then waits a moment for everything to settle. It shows you memory stats before and after so you can see how much was reclaimed. Useful when transitioning between memory-intensive operations.

---

### Batch Size Recommendation

```julia
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

**What it does:** This is a helper function that tells you the best batch size to use based on current GPU memory availability. It takes a conservative approach by planning for the worst case (largest vectors) and calculates how many can fit in memory. It prints a detailed breakdown showing available memory, memory per vector, and the recommended batch size, helping you make informed decisions about processing strategies.

---

## Summary

This entire module is designed to make GPU computing robust and failure-resistant. The key philosophy is:

1. **Adaptive**: Automatically adjusts batch sizes based on available memory
2. **Resilient**: Recovers from out-of-memory errors by reducing workload
3. **Safe**: Validates inputs and handles cleanup properly
4. **Observable**: Provides detailed monitoring and debugging tools

You can use these functions to process large datasets on GPUs without worrying about memory crashes. The system will automatically figure out the best strategy and recover from problems as they occur.