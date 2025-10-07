@def title = "Hidden Julia Tricks: The Uncommonly Known"
@def published = "7 October 2025"
@def tags = ["julia"]

# Hidden Julia Tricks: The Uncommonly Known

These are the Julia tricks that don't make it into most tutorials but can seriously level up your code. Some are subtle, some are powerful, all are surprisingly useful once you know them.

## 1. Generated Functions: Compile-Time Metaprogramming

Most people know about macros, but **generated functions** are Julia's secret weapon for performance.

### What Are They?

Generated functions let you write code that generates specialized code at compile time based on the *types* of arguments (not values).

```julia
@generated function unroll_sum(x::NTuple{N, T}) where {N, T}
    # This runs at COMPILE TIME
    # We can inspect N and generate custom code
    expr = :(x[1])
    for i in 2:N
        expr = :($expr + x[$i])
    end
    return expr
end

# Usage
unroll_sum((1, 2, 3, 4))  # Generates: x[1] + x[2] + x[3] + x[4]
```

The generated function creates a completely unrolled version for each tuple size. No loops at runtime!

### Why This Is Amazing

- **Zero runtime overhead**: The loop is eliminated at compile time
- **Type-driven specialization**: Different code for different types
- **Better than macros**: Macros operate on syntax, generated functions operate on types

### Real-World Example: Custom Dot Product

```julia
@generated function fast_dot(a::NTuple{N, T}, b::NTuple{N, T}) where {N, T}
    # Generate completely unrolled dot product
    terms = [:(a[$i] * b[$i]) for i in 1:N]
    return :(+($(terms...)))
end

fast_dot((1, 2, 3), (4, 5, 6))  # 32 (1*4 + 2*5 + 3*6)
```

This generates code equivalent to `a[1]*b[1] + a[2]*b[2] + a[3]*b[3]` with no loops!

## 2. Val Types: Turn Values into Types

`Val{x}` is a way to pass *values* as *type parameters*, enabling dispatch on values.

```julia
function process(::Val{:fast})
    println("Using fast algorithm")
    # fast implementation
end

function process(::Val{:accurate})
    println("Using accurate algorithm")
    # accurate implementation
end

process(Val(:fast))      # Dispatch based on the symbol!
process(Val(:accurate))
```

### Why This Matters

- **Zero-cost abstraction**: The choice happens at compile time
- **Better than runtime if-else**: No branching overhead
- **Configuration without runtime cost**

### Practical Use: Matrix Operations

```julia
function compute(A, ::Val{:row_major})
    # Optimized for row-major access
    for i in 1:size(A, 1), j in 1:size(A, 2)
        # process A[i, j]
    end
end

function compute(A, ::Val{:col_major})
    # Optimized for column-major access
    for j in 1:size(A, 2), i in 1:size(A, 1)
        # process A[i, j]
    end
end
```

The compiler generates different code for each version, no runtime checks!

## 3. Broadcasting Fusion: One Loop for Everything

Everyone knows `x .+ y`, but the real magic is **fusion**.

```julia
# These all fuse into a SINGLE loop
result = @. sqrt(abs(sin(x))) + cos(y)^2

# Equivalent to:
# for i in eachindex(x, y)
#     result[i] = sqrt(abs(sin(x[i]))) + cos(y[i])^2
# end
```

### The Secret Sauce

Broadcasting operations are **lazy** until you actually need the result. Julia builds a fusion tree and then executes everything in one pass.

```julia
x = 1:1000000
y = 1:1000000

# Bad: Creates 3 temporary arrays
result = sqrt.(abs.(sin.(x))) .+ cos.(y).^2

# Good: Single loop, no temporaries
result = @. sqrt(abs(sin(x))) + cos(y)^2
```

### Custom Broadcasting

You can make your own types broadcastable:

```julia
struct MyArray{T}
    data::Vector{T}
end

Base.broadcastable(x::MyArray) = x.data
Base.size(x::MyArray) = size(x.data)
Base.getindex(x::MyArray, i) = x.data[i]

# Now it just works!
a = MyArray([1, 2, 3])
b = a .+ 10  # [11, 12, 13]
```

## 4. The Mysterious `@inbounds` and `@simd`

These macros tell Julia to optimize loops aggressively.

### `@inbounds`: Skip Bounds Checking

```julia
function sum_unsafe(x)
    total = 0.0
    @inbounds for i in eachindex(x)
        total += x[i]  # No bounds check!
    end
    return total
end
```

**Warning**: Use only when you're 100% sure indices are valid. Otherwise, segfault city.

### `@simd`: Enable SIMD Vectorization

```julia
function sum_simd(x)
    total = 0.0
    @simd for i in eachindex(x)
        total += x[i]
    end
    return total
end
```

This tells LLVM "this loop is safe to vectorize, go wild!"

> **What's happening under the hood with `@simd`?** When you use `@simd`, Julia adds **metadata** to the LLVM IR telling the compiler "this loop has no dependencies between iterations and is safe to vectorize." In the compilation pipeline:
> 
> 1. **Julia frontend**: The `@simd` macro marks the loop with special flags
> 2. **LLVM IR generation**: Julia emits IR with `!llvm.loop.vectorize.enable` metadata attached to the loop
> 3. **LLVM optimization passes**: The Loop Vectorizer pass sees this hint and tries to:
>    - Analyze if vectorization is safe (with `@simd`, it trusts you that it is)
>    - Determine the vector width (e.g., process 4 Float64s at once with AVX2, or 8 with AVX-512)
>    - Transform scalar operations into **SIMD instructions** (like `vaddpd` for vectorized addition)
>    - Generate code that processes multiple elements per iteration
> 4. **Code generation**: Instead of `add rax, rdx` (scalar add), you get `vaddpd ymm0, ymm1, ymm2` (add 4 doubles in parallel)
> 
> The key: `@simd` removes safety checks that would prevent vectorization. Without it, LLVM might be too conservative. With it, LLVM can unroll the loop and use vector registers (XMM, YMM, ZMM) to process 2, 4, 8, or even 16 elements simultaneously. This is why `@simd` can give 2-4x speedups on simple loops - you're literally computing multiple results per CPU instruction!

### The Power Combo

```julia
function ultra_fast_sum(x)
    total = 0.0
    @inbounds @simd for i in eachindex(x)
        total += x[i]
    end
    return total
end
```

Can be **2-4x faster** than naive loops for simple operations.

## 5. `@views`: Stop Allocating Slices

Array slicing in Julia allocates by default:

```julia
x = rand(1000)
y = x[1:100]  # Allocates new array!
```

Use `@views` to make slices non-allocating:

```julia
y = @views x[1:100]  # No allocation, just a view!

# Or for a whole block:
@views begin
    a = x[1:100]
    b = x[101:200]
    c = a .+ b  # Still works with broadcasting!
end
```

### Why This Matters

Views have almost zero overhead but avoid allocations. In hot loops, this is huge:

```julia
function process_columns_bad(A)
    for j in 1:size(A, 2)
        col = A[:, j]  # Allocates every iteration!
        # process col
    end
end

function process_columns_good(A)
    @views for j in 1:size(A, 2)
        col = A[:, j]  # Just a view, no allocation
        # process col
    end
end
```

## 6. `let` Blocks: Not Just For Scoping

Most people think `let` is just for scoping variables, but it's also a secret performance tool.

### Capturing Variables in Closures

```julia
# Bad: Captures reference to i
functions = [() -> i for i in 1:5]
[f() for f in functions]  # All return 5! 😱

# Good: let creates new binding
functions = [let i=i; () -> i; end for i in 1:5]
[f() for f in functions]  # [1, 2, 3, 4, 5] ✓
```

### Type Inference Helper

Sometimes Julia's compiler gets confused. `let` can help:

```julia
# Sometimes helps type inference
result = let x = complex_computation()
    process(x)
end
```

## 7. Multiple Return Values Are Tuples (Use It!)

Julia's multiple return syntax is just tuple unpacking sugar:

```julia
function stats(x)
    return minimum(x), maximum(x), mean(x)
end

min_val, max_val, mean_val = stats(data)
```

But you can be clever with this:

```julia
# Return named tuples for clarity
function stats(x)
    return (min=minimum(x), max=maximum(x), mean=mean(x))
end

s = stats(data)
println(s.min, s.max, s.mean)  # Named access!
```

### Splatting Returns

```julia
function bounds(x)
    return minimum(x), maximum(x)
end

# Splat into function call
clamp.(data, bounds(data)...)  # Clamp to min/max
```

## 8. `do` Syntax: Not Just For Files

Everyone sees `do` with file I/O:

```julia
open("file.txt", "r") do f
    read(f, String)
end
```

But `do` works with *any* function that takes a function as its first argument!

> **Wait, what's actually happening with `do`?** The `do` syntax is pure syntactic sugar that moves the first function argument to *after* the function call. It's confusing at first, so let's break it down:
>
> **Normal way** (function as first argument):
> ```julia
> open(f -> read(f, String), "file.txt", "r")
> #    ^^^^^^^^^^^^^^^^^^  first arg is a function
> ```
>
> **With `do` syntax**:
> ```julia
> open("file.txt", "r") do f
>     read(f, String)
> end
> ```
>
> These are **exactly equivalent**! The `do` block creates an anonymous function and moves it to the *first* argument position, shifting all other arguments left. The weird part: it looks like `f` appears "after" the function call, but it's actually the parameter of a function that gets passed as the *first* argument!
>
> **General pattern**:
> ```julia
> func(arg1, arg2) do x
>     # body using x
> end
> 
> # Is transformed into:
> func(x -> begin
>     # body using x
> end, arg1, arg2)
> ```
>
> So when you write `with_timing() do ... end`, the `do` block becomes the first (and only) argument. When you write `map(data) do x ... end`, the `do` block becomes the first argument and `data` becomes the second. It's a way to make code with callbacks more readable - instead of deeply nested lambdas, you write the callback last, like a code block.

### Custom Control Flow

```julia
function with_timing(f)
    start = time()
    result = f()
    elapsed = time() - start
    println("Took $elapsed seconds")
    return result
end

# Use it with do!
result = with_timing() do
    # Long computation here
    sleep(2)
    42
end

# This is equivalent to:
# result = with_timing(() -> begin
#     sleep(2)
#     42
# end)
```

### Higher-Order Functions

```julia
# Instead of:
map(x -> x^2 + 2x + 1, data)

# You can write:
map(data) do x
    x^2 + 2x + 1
end

# Which transforms to:
# map(x -> x^2 + 2x + 1, data)
# The do block becomes the FIRST argument, data shifts to second!
```

Much more readable for complex functions!

## 9. `@.` vs `@__dot__`: The Secret Alias

`@.` is actually an alias for `@__dot__`. Why care? Because you can use it in code generation:

```julia
macro myfusion(expr)
    return :(@__dot__ $expr)
end

@myfusion sqrt(x) + sin(y)  # Fully broadcast!
```

## 10. `Base.@kwdef`: Easy Struct Defaults

Tired of writing constructors for default values?

```julia
# Old way
struct Config
    learning_rate::Float64
    batch_size::Int
    epochs::Int
    
    Config(;learning_rate=0.001, batch_size=32, epochs=100) =
        new(learning_rate, batch_size, epochs)
end

# New way with @kwdef
Base.@kwdef struct Config
    learning_rate::Float64 = 0.001
    batch_size::Int = 32
    epochs::Int = 100
end

# Use it
config = Config()  # All defaults
config = Config(epochs=200)  # Override one
```

## 11. `@eval`: Generate Methods Programmatically

Need to create many similar methods? Use `@eval`:

```julia
for op in [:sin, :cos, :tan]
    @eval begin
        function $(Symbol(:my_, op))(x)
            println("Computing $($op)")
            return $(op)(x)
        end
    end
end

# Now you have: my_sin, my_cos, my_tan
my_sin(π/2)  # Prints "Computing sin" then returns 1.0
```

### Real Example: Operator Overloading

```julia
for op in [:+, :-, :*, :/]
    @eval Base.$op(a::MyType, b::MyType) = MyType($(op)(a.value, b.value))
end
```

## 12. `invokelatest`: Dynamic Function Calls

When you define functions at runtime and need to call them:

```julia
function make_function()
    eval(:(new_func(x) = x^2))
end

make_function()
# new_func(5)  # Might not work due to world age!
Base.invokelatest(new_func, 5)  # ✓ Works!
```

This bypasses Julia's "world age" mechanism for dynamic code.

## 13. Field Access with `getproperty`

You can customize dot syntax:

```julia
struct LazyDict
    data::Dict{Symbol, Any}
end

function Base.getproperty(d::LazyDict, name::Symbol)
    data = getfield(d, :data)
    if haskey(data, name)
        return data[name]
    else
        return missing
    end
end

d = LazyDict(Dict(:x => 10, :y => 20))
d.x  # 10
d.z  # missing (instead of error!)
```

## 14. `@nospecialize`: Reduce Compilation Time

For functions that don't need specialization on every type:

```julia
function debug_print(@nospecialize(x))
    println("Debug: ", x)
end
```

This tells Julia "don't compile a specialized version for every type", reducing compile time. Great for debugging utilities and error handling.

## 15. The `ans` Variable in REPL

In the REPL, `ans` always holds the last computed value:

```julia
julia> 2 + 2
4

julia> ans * 10
40

julia> ans + 5
45
```

Great for interactive exploration!

## 16. `@code_warntype` Colors Mean Things

When debugging performance:

```julia
@code_warntype my_function(args)
```

**Color meanings:**
- Blue/cyan: Well-typed (good!)
- Yellow: Union types (okay-ish)
- Red: `Any` type (bad! performance killer!)

This is your first tool for finding type instabilities.

## 17. `LoopVectorization.@turbo`: Nuclear Option

Want the fastest loops possible? Use LoopVectorization.jl:

```julia
using LoopVectorization

function ultra_sum(x)
    total = 0.0
    @turbo for i in eachindex(x)
        total += x[i]
    end
    return total
end
```

`@turbo` combines `@inbounds`, `@simd`, loop reordering, and other dark magic. Can be **5-10x faster** than naive loops.

## 18. Symbols Are Singletons

Symbols like `:my_symbol` are interned - there's only one copy in memory:

```julia
:x === :x  # true (same object!)
"x" == "x"  # true (equal)
"x" === "x"  # false (different objects)
```

This makes symbols great for dispatch and dictionaries. They're also faster to compare.

## The Meta-Trick: Read the Manual

Julia's documentation has gems hidden in plain sight. The Performance Tips section alone is worth multiple read-throughs. And `@which`, `@edit`, and `methods()` let you learn from the standard library itself.

```julia
@which sort([1,2,3])  # Shows you which method is called
@edit sort([1,2,3])   # Opens the source code!
methods(sort)         # Shows all sort methods
```

The best Julia code is written by people who read other people's Julia code. The standard library is an excellent teacher.