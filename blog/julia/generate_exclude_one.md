@def title = "Memory-Efficient Exclude-One Vectors in Julia"
@def published = "15 October 2025"
@def tags = ["julia", "dataframe"]

# Memory-Efficient Exclude-One Vectors in Julia

## Problem
Generate "exclude-one" vectors (complement of each element) for multiple vectors, efficiently, for GPU operations.

## Solution: Flat Generator with Views

### Basic Exclude-One (Single Vector)
```julia
# Returns generator of views - memory efficient
exclude_one(x) = (view(x, [1:i-1; i+1:length(x)]) for i in 1:length(x))

# Usage:
x = [1, 2, 3, 4]
for excluded in exclude_one(x)
    # excluded is a view, no copying
end

# Collect when needed for GPU:
result = collect(exclude_one(x))  # Vector of views
```

### Batch Exclude-One (Multiple Vectors)
```julia
# Flat generator - yields all exclude-one vectors sequentially
exclude_one_batch(vectors) = (
    view(v, [1:i-1; i+1:length(v)]) 
    for v in vectors 
    for i in 1:length(v)
)

# Order: [v1\{1}, v1\{2}, ..., v2\{1}, v2\{2}, ..., v3\{1}, ...]

# Usage:
vectors = [[1,2,3], [4,5,6], [7,8,9]]
result = collect(exclude_one_batch(vectors))  # Vector of views
```

### Working with Grouped DataFrames
```julia
using DataFrames

# Single column
exclude_one_grouped(gdf::GroupedDataFrame, col::Symbol) = (
    view(group[!, col], [1:i-1; i+1:nrow(group)])
    for group in gdf
    for i in 1:nrow(group)
)

# Multiple columns (returns tuples of views)
exclude_one_grouped_multi(gdf::GroupedDataFrame, cols) = (
    tuple((view(group[!, col], [1:i-1; i+1:nrow(group)]) for col in cols)...)
    for group in gdf
    for i in 1:nrow(group)
)

# Multiple columns with named tuples
exclude_one_grouped_named(gdf::GroupedDataFrame, cols) = (
    NamedTuple{tuple(cols...)}(
        tuple((view(group[!, col], [1:i-1; i+1:nrow(group)]) for col in cols)...)
    )
    for group in gdf
    for i in 1:nrow(group)
)

# Usage:
df = DataFrame(category = [1,1,1,2,2,2], value = [10,20,30,40,50,60])
gdf = groupby(df, :category)
result = collect(exclude_one_grouped(gdf, :value))
```

## Key Properties

### Memory Efficiency
- **Views**: No data copying until needed
- **Generators**: Lazy evaluation - elements created on demand
- **length()** on views: Allocation-free (just reads metadata)

### Generator vs Nested Generator
```julia
# Flat generator (what we want):
(f(v,i) for v in vectors for i in 1:length(v))
# → Single-level: [item1, item2, item3, ...]

# Nested generator (different structure):
((f(v,i) for i in 1:length(v)) for v in vectors)
# → Two-level: [[items from v1], [items from v2], ...]
```

### Iteration Order
The leftmost `for` is the outer loop:
```julia
for v in vectors          # Processes each vector completely
    for i in 1:length(v)  # Before moving to next vector
        yield view(v, ...)
    end
end
```

## Converting to GPU Format
```julia
# Collect to vector of views (minimal allocation):
gpu_input = collect(exclude_one_batch(vectors))

# Or fully materialize if needed:
gpu_input = [collect(v) for v in exclude_one_batch(vectors)]

# Convert to matrix for GPU (if needed):
matrix_form = hcat(collect.(exclude_one(x))...)'
```

## Performance Notes
- Views add negligible overhead
- Generators don't allocate until iterated
- Indexing into views is allocation-free
- Only pay memory cost when you `collect()` for GPU transfer

### Accessing Length of Generator Elements
```julia
gen = exclude_one_batch(vectors)

# Length check is allocation-free:
for v in gen
    n = length(v)  # NO allocation - just reads view metadata
    # Views store indices, length() just counts them
end

# This is safe and efficient:
lengths = [length(v) for v in gen]  # Only allocates the integer vector

# Views maintain metadata:
x = [1, 2, 3, 4, 5]
v = view(x, [1, 2, 4, 5])
length(v)  # → 4 (allocation-free, reads stored indices)
v[1]       # → 1 (allocation-free, indexed access to parent)
```

**Important**: `length()` on a view (SubArray) just reads metadata - the view stores its indices and parent array pointer, so getting the length is just counting the indices. No data materialization occurs.

### Generator Laziness - Views Created On Demand
```julia
gen = exclude_one_batch(vectors)  # NO views created yet!

# Views are created one-at-a-time during iteration:
for v in gen
    # v is created RIGHT NOW, used, then can be garbage collected
    # Next iteration creates the next view
end

# Only when you collect():
result = collect(gen)  # NOW all views are created and stored

# This means:
gen1 = exclude_one_batch(vectors)  # Virtually free
gen2 = exclude_one_batch(vectors)  # Also virtually free
# No duplication until you iterate/collect!
```

**Key insight**: The generator is just a recipe. Views are created **lazily** as you iterate, one at a time. If you iterate through a generator twice, the views are created twice (but this is cheap since views are just metadata). Only `collect()` materializes all views at once into memory.all views at once into memory.