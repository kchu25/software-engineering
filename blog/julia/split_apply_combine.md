@def title = "Julia DataFrames: The Complete Ninja Guide 🥷"
@def published = "22 October 2025"
@def tags = ["julia", "dataframe"]

# Julia DataFrames: The Complete Ninja Guide 🥷

## The Philosophy: Split-Apply-Combine

DataFrames.jl follows the **split-apply-combine** pattern, which is incredibly intuitive once you get it:

1. **Split**: Divide your data into groups based on some criteria
2. **Apply**: Perform operations on each group independently
3. **Combine**: Merge the results back into a single DataFrame

The beauty is in how flexible and composable this becomes.

> **🧠 The Problem-Solving Philosophy Behind Split-Apply-Combine**
>
> This pattern comes from a fundamental insight about data analysis: **most real-world questions involve comparing subgroups**.
>
> Think about it:
> - "What's the average salary **by department**?"
> - "How did sales change **per region**?"
> - "Which customer **segments** have the highest retention?"
>
> Split-apply-combine formalizes this into a **reusable mental model**:
>
> **Instead of thinking**: "I need to loop through my data, find all rows where department='Engineering', calculate the mean, store it, then find all rows where department='Sales'..."
>
> **You think**: "I need to split by department, apply mean to each group, combine the results."
>
> This is powerful because:
> 1. **Declarative over imperative**: You describe *what* you want, not *how* to get it
> 2. **Composable**: Each step is independent and can be swapped/modified
> 3. **Parallelizable**: Groups are independent, so they can be processed in parallel
> 4. **Less error-prone**: No manual bookkeeping of which rows belong to which group
> 5. **Universal**: Works for simple aggregations AND complex analyses
>
> The pattern originated in Hadley Wickham's 2011 paper and has become the foundation of modern data manipulation (dplyr in R, pandas groupby, SQL GROUP BY). It's essentially a design pattern that **maps human thinking about grouped data** directly to code.
>
> The alternative (writing explicit loops with if-statements and dictionaries to track groups) is like building a house with raw materials instead of using pre-fabricated components - it works, but it's tedious and error-prone.

## Core Design Patterns

### Pattern 1: The Basic `groupby` → `combine`

```julia
using DataFrames

df = DataFrame(
    name = ["Alice", "Bob", "Alice", "Bob", "Charlie"],
    category = ["A", "B", "A", "A", "B"],
    value = [10, 20, 15, 25, 30]
)

# Group by name, calculate mean of value
result = combine(groupby(df, :name), :value => mean => :avg_value)
```

**What's happening**: 
- `groupby(df, :name)` creates a `GroupedDataFrame` (it doesn't copy data, just creates views!)
- `combine()` applies the operation to each group and stacks results

> **📝 The General Syntax of `combine`**
> 
> `combine` accepts multiple forms of arguments, which makes it incredibly flexible:
> 
> 1. **Column operations**: `:col => func => :output_name`
> 2. **Multiple columns**: `[:col1, :col2] => func => :output`
> 3. **Direct functions**: `nrow` (operates on the whole group DataFrame)
> 4. **No transformation**: `:col` (just keeps the column if uniform within groups)
> 5. **Multiple operations**: Mix and match all of the above!
>
> Functions like `nrow`, `proprow`, and `groupindices` are **special**: they operate on the entire group DataFrame, not specific columns, so you use them directly without the `=>` syntax. You can still rename them: `nrow => :count`.
>
> ```julia
> combine(gdf,
>     :value => mean => :avg,     # column operation
>     nrow,                        # special function (gives "nrow" column)
>     nrow => :count,              # special function renamed
>     :category                    # keep as-is (only works if uniform in each group!)
> )
> ```
>
> ⚠️ **Important**: Using `:col` without a function only works if that column has the same value for all rows within each group. If values vary within a group, you'll get an error. When in doubt, use `:col => first` or `:col => unique` to be explicit about what you want.

### Pattern 2: The `=>` Operator (The Secret Sauce)

The `=>` operator is your bread and butter. It follows this pattern:

```
source => function => destination
```

Examples:
```julia
# Single column transformation
combine(gdf, :value => sum => :total)

# Multiple columns to function
combine(gdf, [:value, :quantity] => ((v, q) -> sum(v .* q)) => :weighted_sum)

# Multiple outputs from one function
combine(gdf, :value => (x -> (min=minimum(x), max=maximum(x))) => AsTable)
```

### Pattern 3: Multiple Operations at Once

You can pass multiple transformations to `combine`:

```julia
combine(groupby(df, :category),
    :value => sum => :total,
    :value => mean => :average,
    :value => length => :count,
    :name => (x -> join(unique(x), ", ")) => :names
)
```

Each operation runs independently and gets merged into the output.

### Pattern 4: The `AsTable` Trick

When your function returns a named tuple or DataFrame row, use `AsTable`:

```julia
function stats(x)
    (mean = mean(x), 
     std = std(x), 
     median = median(x))
end

combine(groupby(df, :category), :value => stats => AsTable)
```

This unpacks the named tuple into separate columns!

### Pattern 5: Keeping Group Keys

Sometimes you want to perform operations but keep all original columns:

```julia
# Add a column with group means (broadcasting within groups)
transform(groupby(df, :category), :value => mean => :category_mean)

# This keeps all original rows!
```

**The difference**:
- `combine`: Returns one row per group (aggregation)
- `transform`: Returns same number of rows as input (broadcasting)
- `select`: Like transform but can drop columns

### Pattern 6: Multiple Grouping Columns

```julia
# Group by multiple columns
combine(groupby(df, [:category, :region]), 
    :value => sum => :total)
```

This creates groups for each unique combination of category and region.

### Pattern 7: Anonymous Functions

For quick operations:

```julia
# Coefficient of variation
combine(groupby(df, :category), 
    :value => (x -> std(x) / mean(x)) => :cv)

# Custom complex logic
combine(groupby(df, :name),
    [:value, :quantity] => ((v, q) -> begin
        total = sum(v .* q)
        avg = mean(v .* q)
        (total=total, avg=avg)
    end) => AsTable)
```

### Pattern 8: Using `@by` Macro (Shorthand)

DataFramesMeta.jl provides convenient macros:

```julia
using DataFramesMeta

# Instead of: combine(groupby(df, :category), :value => sum => :total)
@by(df, :category, :total = sum(:value))

# Multiple operations
@by(df, :category, 
    :total = sum(:value),
    :avg = mean(:value),
    :count = length(:value))
```

### Pattern 9: Conditional Aggregation

```julia
# Sum only values above threshold
combine(groupby(df, :category),
    :value => (x -> sum(x[x .> 10])) => :sum_above_10)

# Count with condition
combine(groupby(df, :category),
    :value => (x -> count(>(10), x)) => :count_above_10)
```

### Pattern 10: Window Functions

```julia
# Rank within groups
transform(groupby(df, :category),
    :value => (x -> ordinalrank(x, rev=true)) => :rank)

# Running sum within groups
transform(groupby(df, :category),
    :value => cumsum => :running_total)

# Difference from group mean
transform(groupby(df, :category),
    :value => (x -> x .- mean(x)) => :deviation_from_mean)
```

## Advanced Ninja Techniques

### Technique 1: Nested Grouping

```julia
# First group by category, then apply complex logic
by_category = groupby(df, :category)
result = combine(by_category) do subdf
    # Within each category, do another groupby
    by_name = groupby(subdf, :name)
    DataFrame(
        unique_names = length(by_name),
        total_value = sum(subdf.value)
    )
end
```

### Technique 2: `do` Block Syntax

For complex operations, use `do` blocks:

```julia
combine(groupby(df, :category)) do subdf
    # subdf is the DataFrame for this group
    # You can do ANYTHING here
    top_3 = sort(subdf, :value, rev=true)[1:min(3, nrow(subdf)), :]
    DataFrame(
        top_values = [top_3.value],
        top_names = [top_3.name]
    )
end
```

### Technique 3: The `ungroup` Pattern

Sometimes you need to work with the grouped structure:

```julia
gdf = groupby(df, :category)

# Access individual groups
first_group = gdf[1]

# Get group keys
keys(gdf)

# Number of groups
length(gdf)

# Convert back
ungroup_df = combine(gdf, identity)  # or just DataFrame(gdf)
```

### Technique 4: Column Selectors

```julia
# All numeric columns
combine(groupby(df, :category), 
    valuecols(df) .=> mean)

# Exclude certain columns
combine(groupby(df, :category), 
    Not(:id) .=> mean)

# Match pattern
combine(groupby(df, :category),
    r"^value" .=> sum)  # All columns starting with "value"
```

### Technique 5: Custom Aggregation Functions

```julia
# Weighted mean
weighted_mean(values, weights) = sum(values .* weights) / sum(weights)

combine(groupby(df, :category),
    [:value, :weight] => weighted_mean => :weighted_avg)

# Mode (most common value)
mode_value(x) = begin
    counts = countmap(x)
    argmax(counts)
end

combine(groupby(df, :category), :name => mode_value => :most_common)
```

## Common Gotchas & Solutions

### Gotcha 1: Scalar vs. Vector Returns

```julia
# This errors! Function returns vector but we said => :result (scalar)
combine(groupby(df, :category), :value => identity => :result)

# Fix: Don't give output name for vector, or use proper name
combine(groupby(df, :category), :value => identity)
# OR wrap in a container
combine(groupby(df, :category), :value => (x -> [x]) => :values)
```

### Gotcha 2: Missing Data

```julia
# Handle missing values
combine(groupby(df, :category),
    :value => (x -> mean(skipmissing(x))) => :avg)

# Or drop groups with missing
combine(groupby(dropmissing(df, :category), :category), 
    :value => mean => :avg)
```

### Gotcha 3: Empty Groups

```julia
# Some functions fail on empty vectors
safe_mean(x) = isempty(x) ? missing : mean(x)

combine(groupby(df, :category), :value => safe_mean => :avg)
```

## Performance Tips

1. **Use views when possible**: `groupby` creates views, which is fast
2. **Avoid row iteration**: Vectorized operations are much faster
3. **Type stability**: Make sure your functions return consistent types
4. **Pre-allocate**: For large operations, pre-allocate result containers
5. **Use `@views`**: When slicing in functions, use `@views` to avoid copying

```julia
# Slow
combine(groupby(df, :category)) do subdf
    sum([row.value for row in eachrow(subdf)])
end

# Fast
combine(groupby(df, :category), :value => sum => :total)
```

## The Mental Model

Think of it like this:

```
DataFrame
    ↓ groupby(:column)
GroupedDataFrame (like a collection of DataFrames)
    ↓ combine/transform/select
DataFrame (back to a single table)
```

- **combine**: I want summary statistics (fewer rows)
- **transform**: I want to add columns based on groups (same rows)
- **select**: I want to keep only certain columns after grouping (same rows)

## Quick Reference Table

| Operation | Rows in Output | Use Case |
|-----------|----------------|----------|
| `combine` | One per group | Aggregation |
| `transform` | Same as input | Add group-level info |
| `select` | Same as input | Transform + drop columns |
| `subset` | Filtered | Keep groups matching condition |

## Putting It All Together

```julia
using DataFrames, Statistics

sales = DataFrame(
    date = repeat(Date(2024,1,1):Day(1):Date(2024,1,10), inner=3),
    product = repeat(["A", "B", "C"], 10),
    region = rand(["North", "South"], 30),
    revenue = rand(100:1000, 30),
    units = rand(1:20, 30)
)

# Ninja-level analysis
result = combine(groupby(sales, [:product, :region]),
    :revenue => sum => :total_revenue,
    :units => sum => :total_units,
    [:revenue, :units] => ((r, u) -> sum(r) / sum(u)) => :revenue_per_unit,
    :date => (d -> (first=minimum(d), last=maximum(d))) => AsTable,
    nrow => :num_transactions
)

# Add rankings within product
transform!(groupby(result, :product),
    :total_revenue => (x -> ordinalrank(x, rev=true)) => :rank_in_product
)
```

Now go forth and aggregate! 🥷✨