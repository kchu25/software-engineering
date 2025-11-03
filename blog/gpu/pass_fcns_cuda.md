@def title = "Passing Functions to CUDA Kernels in Julia"
@def published = "2 November 2025"
@def tags = ["gpu-programming", "cuda", "julia"]

# Passing Functions to CUDA Kernels in Julia

## Overview
You can pass functions to CUDA kernels in Julia using several approaches. Functors (callable objects) are the preferred method for most use cases.

## Method 1: Functors (Recommended)

Create a callable struct that holds parameters and function logic.

```julia
using CUDA

struct LinearFunc
    a::Float32
    b::Float32
end

# Make it callable
(f::LinearFunc)(x) = f.a * x + f.b

function kernel!(y, x, f)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    if i <= length(x)
        @inbounds y[i] = f(x[i])
    end
    return nothing
end

# Usage
x = CuArray(1.0f0:10.0f0)
y = similar(x)
f = LinearFunc(2.0f0, 3.0f0)  # 2x + 3

@cuda threads=256 blocks=cld(length(x), 256) kernel!(y, x, f)
```

**Advantages:**
- Type-stable and concrete types enable optimal compilation
- Bundles function logic with parameters cleanly
- Zero runtime overhead (passed by value, inlined)
- Idiomatic Julia/CUDA pattern

## Method 2: Direct Function Passing

Pass functions directly for simple cases.

```julia
function apply_function!(y, x, f)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    if i <= length(x)
        @inbounds y[i] = f(x[i])
    end
    return nothing
end

# Built-in functions
@cuda threads=256 blocks=cld(length(x), 256) apply_function!(y, x, exp)

# Anonymous functions
@cuda threads=256 blocks=cld(length(x), 256) apply_function!(y, x, x -> 2x + 3)
```

**Best for:**
- Simple built-in functions (`exp`, `sin`, `cos`, etc.)
- Quick prototyping
- Functions without parameters

## Method 3: Inline Functions

Define functions that will be inlined into the kernel.

```julia
@inline my_exp(x) = exp(x)
@inline linear(x, a, b) = a * x + b

function kernel!(y, x, a, b)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    if i <= length(x)
        @inbounds y[i] = linear(x[i], a, b)
    end
    return nothing
end
```

## Important Considerations

### Type Stability
- Use concrete types (e.g., `Float32` not `Float64` unless needed)
- Avoid abstract types in performance-critical code
- Functors naturally enforce type stability

### GPU Compatibility
Functions passed to kernels must be GPU-compatible:
- ❌ No allocations
- ❌ No unsupported operations (I/O, system calls)
- ✅ Mathematical operations
- ✅ Control flow (if/else, loops)

### Performance
- Functors provide the best performance for parameterized functions
- Anonymous functions work but may have compilation overhead
- Built-in functions are optimized and efficient

## Quick Comparison

| Approach | Best For | Type Stable | Parameters |
|----------|----------|-------------|------------|
| **Functors** | Parameterized functions, production code | ✅ Yes | Easy |
| **Direct passing** | Built-ins, prototypes | ⚠️ Depends | Limited |
| **Inline functions** | Simple helpers | ✅ Yes | Manual |

## Recommendation

**Use functors** (Method 1) when:
- You need to pass parameters with your function
- Writing production/reusable code
- Performance is critical

**Use direct passing** (Method 2) when:
- Using simple built-in functions
- Rapid prototyping
- Parameters aren't needed

---

## Advanced & Exotic Techniques

### Function Pointers (Controversial!)

You can technically use function pointers, but this is **discouraged**:

```julia
function kernel_with_fptr!(y, x, fptr::Core.LLVMPtr{Cvoid})
    # This can work but is fragile and not recommended
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    if i <= length(x)
        # Calling through function pointer...
    end
    return nothing
end
```

**Why avoid:** 
- Prevents inlining and optimization
- Type-unstable
- Can break with Julia/CUDA.jl updates
- Performance penalty

### Multiple Dispatch on GPU

You can leverage Julia's multiple dispatch in kernels:

```julia
struct ExpFunc end
struct LinearFunc
    a::Float32
    b::Float32
end

# Define behavior via dispatch
@inline apply(::ExpFunc, x) = exp(x)
@inline apply(f::LinearFunc, x) = f.a * x + f.b

function kernel!(y, x, f)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    if i <= length(x)
        @inbounds y[i] = apply(f, x[i])
    end
    return nothing
end

# Works with different function types!
@cuda kernel!(y, x, ExpFunc())
@cuda kernel!(y, x, LinearFunc(2.0f0, 3.0f0))
```

**Exotic benefit:** Same kernel code handles different functions via dispatch!

### Val Types for Compile-Time Selection

Use `Val` to select functions at compile time:

```julia
@inline select_op(::Val{:exp}, x) = exp(x)
@inline select_op(::Val{:sin}, x) = sin(x)
@inline select_op(::Val{:cos}, x) = cos(x)

function kernel!(y, x, ::Val{op}) where {op}
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    if i <= length(x)
        @inbounds y[i] = select_op(Val(op), x[i])
    end
    return nothing
end

# Generates specialized kernels for each operation
@cuda kernel!(y, x, Val(:exp))
@cuda kernel!(y, x, Val(:sin))
```

**Trade-off:** Creates separate kernel for each `Val` type (compilation overhead vs. runtime flexibility).

### Closures (Sometimes Work, Sometimes Don't)

Closures can be tricky on GPU:

```julia
function make_scaler(factor)
    return x -> factor * x  # Captures 'factor'
end

# May work, but...
f = make_scaler(2.0f0)
@cuda kernel!(y, x, f)
```

**Gotchas:**
- Closure must capture only GPU-compatible values
- Boxing/heap allocation = 💥 crash
- Type instability common
- Better to use functors explicitly

### Generated Functions (Expert Level)

Use `@generated` for ultra-specialized kernels:

```julia
@generated function apply_op(::Val{op}, x) where {op}
    if op == :exp
        return :(exp(x))
    elseif op == :log
        return :(log(x))
    else
        return :(x)
    end
end
```

**When to use:** Rare! Only when you need code generation based on types.

### Controversial: `@device_override`

Override how functions work on GPU vs CPU:

```julia
@device_override @inline my_func(x) = exp(x)  # GPU version
my_func(x) = expensive_cpu_computation(x)      # CPU version
```

**Controversy:** Can make code harder to reason about (different behavior on CPU/GPU).

---

## Performance Gotchas

### Kernel Recompilation
Passing different function types triggers recompilation:
```julia
@cuda kernel!(y, x, LinearFunc(1.0f0, 0.0f0))  # Compiles once
@cuda kernel!(y, x, LinearFunc(2.0f0, 0.0f0))  # Reuses compiled kernel ✅
@cuda kernel!(y, x, ExpFunc())                 # New compilation! ⚠️
```

### Type Piracy Risk
Don't make external types callable without careful consideration:
```julia
# Dangerous! You don't own Float32
(x::Float32)(y) = x * y  # Type piracy! ❌
```

### Union Types
Union types can work but may hurt performance:
```julia
function kernel!(y, x, f::Union{ExpFunc, LinearFunc})
    # Works but less optimal than concrete type
end
```

---

## Ecosystem-Specific Notes

### KernelAbstractions.jl
If using KernelAbstractions.jl for portable GPU code, functors work across CUDA, ROCm, oneAPI:
```julia
using KernelAbstractions

@kernel function my_kernel!(y, x, @Const(f))
    i = @index(Global)
    @inbounds y[i] = f(x[i])
end

# Same functor works on any GPU backend!
```

### Enzyme.jl Integration
Functors play nicely with automatic differentiation:
```julia
using Enzyme

# Can differentiate through custom functors!
Enzyme.autodiff(Reverse, gpu_computation!, Duplicated(y, dy), 
                Const(x), Const(my_func))
```