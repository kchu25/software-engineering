@def title = "Understanding Val in Julia: From Values to Types"
@def published = "7 October 2025"
@def tags = ["julia"]

# Understanding Val in Julia: From Values to Types

## The Big Idea in One Sentence

`Val` lets you move runtime decisions to compile time by turning values into types, enabling zero-overhead dispatch on specific values.

## The Problem: Runtime vs Compile Time

### Normal Dispatch on Types

In Julia, multiple dispatch normally works on **types**:

```julia
greet(x::Int) = "You gave me a number!"
greet(x::String) = "You gave me text!"

greet(42)      # "You gave me a number!"
greet("hello") # "You gave me text!"
```

The function picks the right method based on what **type** you pass in. This choice happens at **compile time** - Julia generates different machine code for each type.

### What If You Want to Dispatch on Specific Values?

Sometimes you want different behavior for specific **values**, not types:

```julia
# I want different behavior for :fast vs :slow
# But they're both Symbols - same type!

function compute(mode::Symbol, data)
    if mode == :fast
        # Use fast algorithm
        return simple_computation(data)
    elseif mode == :accurate
        # Use accurate algorithm
        return complex_computation(data)
    else
        error("Unknown mode")
    end
end
```

**The problem**: That `if` statement runs every single time. That's **runtime overhead**.

## Enter Val: Values Disguised as Types

`Val` is a simple type that wraps a value:

```julia
Val(:fast)      # Type: Val{:fast}
Val(:accurate)  # Type: Val{:accurate}
Val(3)          # Type: Val{3}
Val(true)       # Type: Val{true}
```

The crucial insight: `Val{:fast}` and `Val{:accurate}` are **different types**, even though `:fast` and `:accurate` are just values!

Now you can dispatch on them:

```julia
compute(::Val{:fast}, data) = simple_computation(data)
compute(::Val{:accurate}, data) = complex_computation(data)

# Use it
result = compute(Val(:fast), my_data)
```

> **Side note on `::Val{:fast}` syntax**: The `::` means "has type". When you write `compute(::Val{:fast}, data)`, you're saying "the first argument has type `Val{:fast}`, but I don't care about the actual value, just its type." Notice there's no variable name before the `::` - that's intentional! We're not using the value, only dispatching on its type. If you needed to access it, you'd write `compute(mode::Val{:fast}, data)` and then use `mode` in the function body. But since `Val` instances are empty (zero bytes), there's nothing to access anyway - the type is all that matters.

## Why This Is Magical

When Julia sees `compute(Val(:fast), my_data)`, it:

1. Recognizes the type is `Val{:fast}` at **compile time**
2. Picks the first method at **compile time**
3. Generates machine code that calls `simple_computation` directly
4. **No if-statements in the generated code!**

### The Performance Difference

Let's see the difference with a benchmark-style example:

```julia
# Runtime branching (slower)
function sum_strategy_runtime(arr, mode::Symbol)
    if mode == :simple
        total = 0.0
        for x in arr
            total += x
        end
        return total
    elseif mode == :squared
        total = 0.0
        for x in arr
            total += x^2
        end
        return total
    end
end

# Compile-time dispatch (faster)
function sum_strategy_compiled(arr, ::Val{:simple})
    total = 0.0
    for x in arr
        total += x
    end
    return total
end

function sum_strategy_compiled(arr, ::Val{:squared})
    total = 0.0
    for x in arr
        total += x^2
    end
    return total
end

# Usage
data = rand(1000)
sum_strategy_runtime(data, :simple)           # Has if-check overhead
sum_strategy_compiled(data, Val(:simple))     # No if-check, direct call
```

The second version compiles to tighter, faster machine code.

## Anatomy of Val

Let's look at what Val actually is:

```julia
# This is (roughly) how Val is defined in Base Julia
struct Val{T} end

# When you write Val(:fast), you're creating an instance of Val{:fast}
# The type parameter T is the value you're wrapping
```

The clever part: the value `:fast` becomes part of the **type signature** `Val{:fast}`, so Julia's dispatch mechanism can see it.

## Real-World Example: Matrix Storage Layouts

```julia
# Define a matrix type with configurable storage
struct Matrix2D{T, Layout}
    data::Vector{T}
    rows::Int
    cols::Int
end

# Different indexing strategies based on layout
function Base.getindex(m::Matrix2D{T, Val{:row_major}}, i::Int, j::Int) where T
    idx = (i - 1) * m.cols + j
    return m.data[idx]
end

function Base.getindex(m::Matrix2D{T, Val{:col_major}}, i::Int, j::Int) where T
    idx = (j - 1) * m.rows + i
    return m.data[idx]
end

# Create matrices with different layouts
A = Matrix2D{Float64, Val{:row_major}}(zeros(100), 10, 10)
B = Matrix2D{Float64, Val{:col_major}}(zeros(100), 10, 10)

# The right indexing method is chosen at compile time!
A[5, 3]  # Uses row-major indexing, no runtime check
B[5, 3]  # Uses col-major indexing, no runtime check
```

## Another Example: Dimension-Specific Operations

```julia
# Sum along different dimensions
function sum_along(arr::Array{T, N}, ::Val{:rows}) where {T, N}
    # Sum each row (dimension 1)
    return [sum(arr[i, :]) for i in 1:size(arr, 1)]
end

function sum_along(arr::Array{T, N}, ::Val{:cols}) where {T, N}
    # Sum each column (dimension 2)
    return [sum(arr[:, j]) for j in 1:size(arr, 2)]
end

function sum_along(arr::Array{T, N}, ::Val{:all}) where {T, N}
    # Sum everything
    return sum(arr)
end

# Usage
matrix = rand(5, 4)
sum_along(matrix, Val(:rows))  # [sum of row 1, sum of row 2, ...]
sum_along(matrix, Val(:cols))  # [sum of col 1, sum of col 2, ...]
sum_along(matrix, Val(:all))   # single number
```

## Practical Example: Algorithm Selection

```julia
abstract type SortStrategy end

# Different sorting algorithms
function sort_data(data, ::Val{:quick})
    println("Using quicksort")
    return sort(data, alg=QuickSort)
end

function sort_data(data, ::Val{:merge})
    println("Using mergesort")
    return sort(data, alg=MergeSort)
end

function sort_data(data, ::Val{:insertion})
    println("Using insertion sort")
    return sort(data, alg=InsertionSort)
end

# The user picks once, then no overhead
my_data = rand(1000)
sorted = sort_data(my_data, Val(:quick))
```

## When Should You Use Val?

### ✅ Good Use Cases

1. **Configuration that rarely changes**
   ```julia
   # Set at initialization, never changes
   model = NeuralNetwork{Val{:gpu}}(...)
   ```

2. **Compile-time optimization flags**
   ```julia
   compute(data, Val(:use_simd))
   ```

3. **Enabling/disabling features at compile time**
   ```julia
   struct Container{T, Val{:thread_safe}}
       # Thread-safe version uses locks
   end
   
   struct Container{T, Val{:fast}}
       # Fast version has no locks
   end
   ```

4. **Dimension specifications**
   ```julia
   reduce_along(array, Val(1))  # Reduce along dimension 1
   ```

### ❌ Bad Use Cases

1. **Values that change frequently**
   ```julia
   # DON'T DO THIS
   for mode in [:fast, :slow, :medium]
       compute(Val(mode), data)  # Creates new types constantly!
   end
   ```

2. **User input at runtime**
   ```julia
   # DON'T DO THIS
   user_choice = readline()  # User types "fast" or "slow"
   compute(Val(Symbol(user_choice)), data)  # Just use if-statements!
   ```

3. **Large or complex values**
   ```julia
   # DON'T DO THIS
   Val([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])  # Type signatures get huge!
   ```

4. **When the overhead doesn't matter**
   ```julia
   # If this only runs once, Val is overkill
   initialize_system(Val(:mode))  # Just use an if-statement
   ```

## The Technical Details

### How Val Creates Types

When you write `Val(:fast)`, Julia:

1. Takes the value `:fast`
2. Creates a type `Val{:fast}` where `:fast` is a **type parameter**
3. Constructs an instance of that type (which is empty, just a marker)

```julia
julia> typeof(Val(:fast))
Val{:fast}

julia> Val(:fast) === Val(:fast)
true  # Same singleton instance

julia> sizeof(Val(:fast))
0  # Takes no memory! Just a type marker
```

### Type Parameters Aren't Just For Types

Normally, type parameters hold types:

```julia
Array{Int, 2}      # Int is a type
Dict{String, Int}  # String and Int are types
```

But Julia allows **any bits type** as a type parameter:

```julia
Val{:symbol}       # A symbol
Val{42}            # An integer
Val{true}          # A boolean
Val{(1, 2, 3)}     # A tuple (if all elements are bits types)
```

This is the loophole that Val exploits!

### The Cost of Val

Each unique `Val{x}` creates a new type, which means:

- A new method gets compiled for each value
- More code generation and compilation time
- Larger binaries

So use Val judiciously - for things that have a small, fixed set of possible values.

## Comparing Approaches

Let's see the same functionality implemented three ways:

### Approach 1: Runtime If-Statement

```julia
function process(mode::Symbol, data)
    if mode == :fast
        return fast_algo(data)
    elseif mode == :accurate
        return accurate_algo(data)
    end
end

# Pros: Simple, flexible, works with any runtime value
# Cons: Runtime overhead, branch mispredictions possible
```

### Approach 2: Val Dispatch

```julia
process(::Val{:fast}, data) = fast_algo(data)
process(::Val{:accurate}, data) = accurate_algo(data)

# Usage: process(Val(:fast), data)

# Pros: Zero runtime overhead, compiler optimizes perfectly
# Cons: Must know value at compile time, creates multiple compiled methods
```

### Approach 3: Type Dispatch (Manual)

```julia
abstract type Mode end
struct Fast <: Mode end
struct Accurate <: Mode end

process(::Fast, data) = fast_algo(data)
process(::Accurate, data) = accurate_algo(data)

# Usage: process(Fast(), data)

# Pros: Same performance as Val, more explicit
# Cons: More boilerplate, need to define types manually
```

Val is essentially approach 3 with automatic type generation!

## Advanced Pattern: Val with Type Parameters

You can combine Val with other type parameters:

```julia
struct Optimizer{Algo, T}
    learning_rate::T
end

function step!(opt::Optimizer{Val{:sgd}}, grads)
    # Standard SGD
    return grads .* opt.learning_rate
end

function step!(opt::Optimizer{Val{:adam}}, grads)
    # Adam optimizer
    return complex_adam_computation(grads, opt.learning_rate)
end

# Create optimizers
sgd_opt = Optimizer{Val{:sgd}, Float64}(0.01)
adam_opt = Optimizer{Val{:adam}, Float64}(0.001)
```

## The Bottom Line

`Val` is Julia's way of saying: "If you know something at compile time, tell me, and I'll generate the fastest possible code."

It's a bridge between the flexibility of dynamic values and the performance of static types. Use it when:

- You have a small, fixed set of configuration options
- The choice doesn't change frequently
- You want zero-cost abstraction
- Performance matters in that code path

Don't use it when:

- The value comes from user input or changes dynamically
- You're just calling a function once (overhead doesn't matter)
- The set of possible values is large or unbounded

When used correctly, `Val` is one of Julia's most elegant performance tricks - turning what would be runtime conditionals into compile-time specialization.