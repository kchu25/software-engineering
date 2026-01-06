@def title = "Julia Multiple Dispatch Tricks & Patterns"
@def published = "6 January 2026"
@def tags = ["julia"]

# Julia Multiple Dispatch Tricks & Patterns

Hey! You're thinking of some clever dispatch patterns in Julia. Let me walk you through the interesting ones, including that `Ref` trick.

## The `Ref` Trick - Dispatching on Values

This is probably what you're remembering! You can dispatch on *values* instead of just types by wrapping them in `Ref`:

```julia
# Dispatch on the value itself!
foo(x, ::Ref{:option1}) = "You chose option 1"
foo(x, ::Ref{:option2}) = "You chose option 2"

# Call it like this:
foo(42, Ref(:option1))  # "You chose option 1"
foo(42, Ref(:option2))  # "You chose option 2"
```

The `Ref` creates a singleton type for each value, so Julia can dispatch on it at compile time. Pretty neat!

## Val Types - The "Official" Way

Julia actually has `Val` types built-in for this exact pattern:

```julia
process(x, ::Val{:fast}) = "Fast algorithm"
process(x, ::Val{:slow}) = "Slow but accurate"

# Call with Val constructor:
process(data, Val(:fast))
```

This is the idiomatic way to do value-based dispatch. The compiler can often optimize away the `Val` wrapper entirely.

## Trait-Based Dispatch (Holy Traits Pattern)

This is a game-changer for generic programming. You dispatch based on properties of types:

```julia
# Define trait functions
IsIterable(::Type) = NotIterable()
IsIterable(::Type{<:AbstractArray}) = Iterable()

struct Iterable end
struct NotIterable end

# Dispatch on the trait
process(x) = process(IsIterable(typeof(x)), x)
process(::Iterable, x) = sum(x)  # For iterable things
process(::NotIterable, x) = x    # For non-iterable things

process([1,2,3])  # 6
process(42)       # 42
```

This lets you categorize types by behavior without inheritance!

## Dispatching on Type Parameters

You can dispatch on the parameters of parametric types:

```julia
# Different behavior for vectors of different types
foo(::Vector{Int}) = "Integer vector"
foo(::Vector{Float64}) = "Float vector"
foo(::Vector{T}) where T = "Vector of \$T"

# Dispatch on dimensionality
bar(::Array{T, 1}) where T = "1D array (vector)"
bar(::Array{T, 2}) where T = "2D array (matrix)"
bar(::Array{T, N}) where {T, N} = "\$N-D array"
```

## Function-Valued Arguments

Sometimes you want to dispatch on which *function* is passed:

```julia
apply_op(::typeof(+), x, y) = "Adding"
apply_op(::typeof(*), x, y) = "Multiplying"
apply_op(f, x, y) = "Using generic function"

apply_op(+, 1, 2)      # "Adding"
apply_op(*, 1, 2)      # "Multiplying"
apply_op(sin, 1, 2)    # "Using generic function"
```

## Empty Type Trick for Zero-Cost Flags

Use empty types as zero-cost flags:

```julia
struct Verbose end
struct Quiet end

function compute(x, ::Type{Verbose})
    println("Computing...")
    x^2
end

function compute(x, ::Type{Quiet})
    x^2
end

compute(5, Verbose)  # Prints and computes
compute(5, Quiet)    # Just computes
```

The type gets compiled away - zero runtime cost!

## Varargs with Type Constraints

Dispatch on the number and types of variable arguments:

```julia
# Exactly two arguments
foo(a::Int, b::Int) = a + b

# Three or more integers
foo(a::Int, b::Int, rest::Int...) = sum((a, b, rest...))

# Mix of types
bar(::Int, ::String, rest::Float64...) = "Got int, string, and floats"
```

## Combining Patterns

The real magic happens when you combine these:

```julia
# Trait + Val for algorithm selection
abstract type Algorithm end
struct FastAlgo <: Algorithm end
struct AccurateAlgo <: Algorithm end

compute(x, ::Val{:auto}) = compute(x, choose_algo(x))
compute(x, ::Type{FastAlgo}) = fast_compute(x)
compute(x, ::Type{AccurateAlgo}) = accurate_compute(x)

choose_algo(x::Vector{<:Integer}) = FastAlgo
choose_algo(x) = AccurateAlgo
```

## Pro Tips

- **Val vs Ref**: Use `Val` for value dispatch - it's the standard and optimizes better
- **Trait dispatch**: Great for when you can't modify the type hierarchy
- **Type parameters**: Specialize on `Vector{Int}` vs `Vector{<:Number}` carefully - the former is *much* more specific
- **Empty types**: When you need runtime flags, empty types have zero memory overhead
- **Don't over-engineer**: Sometimes a simple `if` statement is clearer than a clever dispatch pattern

The beauty of Julia is that all these patterns have zero or near-zero runtime cost. The compiler figures it out and generates specialized code for each case. Pretty cool, right?

## When to Use Dispatch vs. Internal Logic

Short answer: **Not always!** Here's the nuance:

### Use Dispatch When:

**Type-based differences** - This is dispatch's sweet spot:
```julia
# GOOD - fundamentally different algorithms
area(::Circle) = π * r^2
area(::Rectangle) = width * height
```

**Performance matters** - Dispatch helps the compiler specialize:
```julia
# GOOD - compiler can optimize each case
multiply(x::Float64, y::Float64) = x * y  # SIMD possible
multiply(x::BigFloat, y::BigFloat) = x * y  # Different code path
```

**Clear separation of concerns** - When methods are conceptually distinct:
```julia
# GOOD - each is its own thing
save(file::CSV, data) = # CSV logic
save(file::JSON, data) = # JSON logic
```

### Use Internal Logic When:

**Simple conditionals** - Don't over-engineer:
```julia
# GOOD - just use an if
function greet(name, formal=false)
    formal ? "Good day, \$name" : "Hey \$name!"
end

# OVERKILL - don't do this
greet(name, ::Val{true}) = "Good day, \$name"
greet(name, ::Val{false}) = "Hey \$name!"
```

**Complex business logic** - When the logic is intertwined:
```julia
# GOOD - the logic is naturally sequential
function calculate_price(item, customer)
    price = item.base_price
    if customer.is_member
        price *= 0.9
    end
    if item.on_sale
        price *= 0.8
    end
    if price > 100 && customer.loyal
        price -= 10
    end
    return price
end

# BAD - this would be a nightmare with dispatch
```

**Dynamic/runtime decisions** - When you don't know types at compile time:
```julia
# GOOD - the choice is runtime data
function process(data, algorithm_name::String)
    if algorithm_name == "fast"
        fast_algorithm(data)
    elseif algorithm_name == "accurate"
        accurate_algorithm(data)
    else
        error("Unknown algorithm")
    end
end
```

**Shared setup/teardown** - When methods would duplicate code:
```julia
# GOOD - shared logic
function analyze(data, method)
    validated = validate(data)  # Common to all
    normalized = normalize(validated)  # Common to all
    
    if method == :mean
        return mean(normalized)
    elseif method == :median
        return median(normalized)
    end
end

# BAD - would duplicate validation in each method
```

### The Gray Area: Configuration

This is where people debate. For configuration flags:
```julia
# Style 1: Internal logic (simpler to read)
function compute(x, verbose=false)
    verbose && println("Starting...")
    result = x^2
    verbose && println("Done!")
    return result
end

# Style 2: Dispatch (better performance, but verbose)
compute(x, ::Type{Verbose}) = compute_impl(x, true)
compute(x, ::Type{Quiet}) = compute_impl(x, false)
```

If the verbose flag is checked in a hot loop, dispatch wins. Otherwise, the `if` is fine and clearer.

### Performance Reality Check

Julia's compiler is smart, but:
- **Branch prediction is fast** - Modern CPUs handle predictable `if` statements well
- **Dispatch isn't free** - Multiple dispatch has lookup costs (though usually tiny)
- **Profile first** - Don't optimize prematurely

### Rules of Thumb

1. **Favor dispatch for type differences** - That's what Julia is designed for
2. **Use logic for value-based decisions** - Unless performance profiling says otherwise
3. **Keep it readable** - If dispatch makes code harder to understand, don't use it
4. **Avoid dispatch explosion** - If you'd need 20 methods, use internal logic
5. **Consider maintainability** - Will future you (or others) understand this?

### A Real Example

Let's say you're processing user input:

```julia
# DON'T DO THIS - dispatch overkill
process(::Val{:add}, a, b) = a + b
process(::Val{:subtract}, a, b) = a - b
process(::Val{:multiply}, a, b) = a * b
# ... 50 more operations

# DO THIS - simple dictionary
const OPERATIONS = Dict(
    :add => +,
    :subtract => -,
    :multiply => *
)

function process(op::Symbol, a, b)
    fn = get(OPERATIONS, op, nothing)
    fn === nothing && error("Unknown operation: \$op")
    return fn(a, b)
end
```

The dictionary version is clearer, easier to extend, and performance is fine for non-hot-path code.

### Bottom Line

Dispatch is a powerful tool, but it's not a hammer for every nail. Use it when it makes your code clearer, more composable, or genuinely faster. Use regular control flow when it's simpler and does the job. Julia gives you both - use them wisely!
