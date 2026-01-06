@def title = "The mapreduce + Generator Trick to save memory"
@def published = "6 January 2026"
@def tags = ["julia"]

# The mapreduce + Generator Trick

**The trick:** When you pass a generator to `mapreduce`, Julia processes elements one at a time without materializing the full collection. This saves the big allocation.

> **Wait, does the `...` splat kill the generator?**
> 
> Nope! The splat just unpacks the generator into separate arguments for `mapreduce`. Think of it like this: instead of passing one iterable, you're passing multiple iterables as individual arguments. The generator still does its lazy thing - each `df.values` only gets computed when `mapreduce` asks for it. The splat is just syntactic sugar for turning `(a, b, c)` into three separate arguments instead of one tuple.

> **What does splat actually do? Some concrete examples:**
>
> Splat (`...`) unpacks a collection into individual arguments. Think of it as "unwrapping" things:
>
> ```julia
> # Without splat - passing a tuple/array as ONE argument
> max([1, 2, 3])  # Error! max wants separate numbers, not an array
>
> # With splat - unpacking into separate arguments  
> max([1, 2, 3]...)  # Same as: max(1, 2, 3) → 3
> ```
>
> **Common use cases:**
>
> 1. **Functions expecting multiple args:** `push!(arr, items...)` adds all items at once
> 2. **Variable number of collections:** `vcat(arrays...)` concatenates however many you have
> 3. **Unpacking tuples:** `f(point...)` turns `(x, y)` into `f(x, y)`
> 4. **With generators (your case!):** `mapreduce(f, op, (thing for thing in stuff)...)` processes each thing separately
>
> The key insight: splat turns *one thing containing many items* into *many separate arguments*.

## Your code's secret sauce

```julia
mapreduce(extrema, reducer, (df.values for df in dfs)...)
```

That `(df.values for df in dfs)` generator is the key! It means:

- ✅ Each `df.values` gets processed one at a time
- ✅ No intermediate array holding all the datasets
- ✅ Memory usage stays roughly constant regardless of how many dataframes you have

## The anti-pattern (what NOT to do)

```julia
# DON'T DO THIS - materializes everything first
all_data = [df.values for df in dfs]  # Big array allocation!
mapreduce(extrema, reducer, all_data...)
```

## What still allocates?

You still get small allocations:
- Each `extrema` call returns a tuple `(min, max)`
- The reducer creates new tuples as it combines results

But these are tiny compared to avoiding the full data collection.

## The pattern

This is a solid Julia idiom whenever you need to aggregate over multiple collections:

```julia
mapreduce(your_function, your_reducer, (item for item in collection)...)
```

The generator keeps memory usage flat while mapreduce handles the combining logic cleanly.