@def title = "Julia DataFrames: Techniques & Ninja Tricks"
@def published = "7 October 2025"
@def tags = ["julia", "dataframe]

# Julia DataFrames: Techniques & Ninja Tricks

## Installation

```julia
using Pkg
Pkg.add("DataFrames")
using DataFrames
```

## Constructing DataFrames

### Method 1: Using Named Columns

```julia
df = DataFrame(
    name = ["Alice", "Bob", "Charlie"],
    age = [25, 30, 35],
    salary = [50000, 60000, 75000]
)
```

### Method 2: From a Matrix

```julia
# Create a matrix
matrix = [1 2 3; 4 5 6; 7 8 9]

# Convert to DataFrame with automatic column names
df = DataFrame(matrix, :auto)

# Or with custom column names
df = DataFrame(matrix, ["col1", "col2", "col3"])
```

### Method 3: From a Dictionary

```julia
dict = Dict(
    "name" => ["Alice", "Bob", "Charlie"],
    "age" => [25, 30, 35]
)
df = DataFrame(dict)
```

### Method 4: Empty DataFrame (Then Add Columns)

```julia
df = DataFrame()
df.name = ["Alice", "Bob"]
df.age = [25, 30]
```

### Method 5: From Named Tuples

```julia
df = DataFrame([
    (name="Alice", age=25, city="NYC"),
    (name="Bob", age=30, city="LA")
])
```

## Basic Operations

### Viewing Data

```julia
first(df, 5)      # First 5 rows
last(df, 3)       # Last 3 rows
describe(df)      # Summary statistics
names(df)         # Column names
nrow(df)          # Number of rows
ncol(df)          # Number of columns
size(df)          # Dimensions (rows, cols)
```

### Selecting Columns

```julia
df.name                    # Single column as vector
df[:, :name]              # Single column as vector
df[:, [:name, :age]]      # Multiple columns as DataFrame
select(df, :name, :age)   # Using select function
```

### Selecting Rows

```julia
df[1, :]                  # First row
df[1:3, :]               # Rows 1-3
df[df.age .> 25, :]      # Conditional selection
```

### Adding Columns

```julia
df.bonus = df.salary .* 0.1
df[!, :total] = df.salary .+ df.bonus
```

### Removing Columns

```julia
select!(df, Not(:bonus))           # Remove in-place
df2 = select(df, Not(:bonus))      # Create new DataFrame
```

## Ninja Tricks 🥷

### 1. Transform with Broadcasting (Avoid Loops!)

```julia
# Bad: Loop through rows
for i in 1:nrow(df)
    df[i, :doubled] = df[i, :age] * 2
end

# Good: Broadcasting
df.doubled = df.age .* 2
```

### 2. Chain Operations with Pipes

```julia
df |> 
    df -> filter(row -> row.age > 25, df) |>
    df -> select(df, :name, :salary) |>
    df -> sort(df, :salary, rev=true)
```

### 3. Use `transform` and `select` for Cleaner Code

```julia
# Add new columns without mutation
df2 = transform(df, :salary => (x -> x .* 1.1) => :new_salary)

# Multiple transformations at once
df2 = transform(df,
    :salary => (x -> x .* 1.1) => :raised_salary,
    :age => (x -> x .+ 1) => :age_next_year
)
```

### 4. ByRow for Element-wise Operations

```julia
# Apply function to each row
transform(df, :name => ByRow(uppercase) => :name_upper)

# Custom function on multiple columns
transform(df, [:age, :salary] => ByRow((a, s) -> s / a) => :salary_per_age)
```

### 5. GroupBy and Combine Power

```julia
# Group by category and aggregate
grouped = groupby(df, :department)
combine(grouped, :salary => mean => :avg_salary)

# Multiple aggregations
combine(grouped,
    :salary => mean => :avg_salary,
    :salary => sum => :total_salary,
    nrow => :count
)
```

### 6. Subset with Complex Conditions

```julia
# Using subset function (better than boolean indexing)
subset(df, :age => x -> x .> 25, :salary => x -> x .< 70000)

# Skip missing values automatically
subset(df, :age => x -> x .> 25, skipmissing=true)
```

### 7. In-Place Operations (Save Memory!)

```julia
# Most functions have in-place versions with !
sort!(df, :age)              # Sorts df directly
select!(df, Not(:temp_col))  # Removes column from df
transform!(df, :age => (x -> x .+ 1) => :age)  # Modifies df
```

### 8. Missing Data Handling

```julia
# Check for missing
any(ismissing, df.age)

# Remove rows with any missing
dropmissing(df)

# Remove rows with missing in specific columns
dropmissing(df, :age)

# Replace missing values
coalesce.(df.age, 0)  # Replace missing with 0
```

### 9. Rename Columns Efficiently

```julia
# Rename specific columns
rename(df, :old_name => :new_name)

# Rename multiple at once
rename(df, :name => :employee, :salary => :pay)

# Apply function to all column names
rename(lowercase, df)
rename(x -> x * "_2024", df)
```

### 10. Stack and Unstack (Reshape Data)

```julia
# Wide to long format
long_df = stack(df, [:col1, :col2], :id)

# Long to wide format
wide_df = unstack(long_df, :id, :variable, :value)
```

### 11. Joins Made Easy

```julia
df1 = DataFrame(id=[1,2,3], name=["A","B","C"])
df2 = DataFrame(id=[1,2,4], value=[10,20,40])

innerjoin(df1, df2, on=:id)      # Only matching rows
leftjoin(df1, df2, on=:id)       # All from df1
rightjoin(df1, df2, on=:id)      # All from df2
outerjoin(df1, df2, on=:id)      # All rows
```

### 12. Performance Tip: Use Views

```julia
# Create a view instead of copying
view_df = @view df[1:100, :]

# SubDataFrame for non-copying selection
sub_df = df[1:100, :]  # Makes a copy
sub_df = @view df[1:100, :]  # No copy, faster!
```

### 13. Macro Magic for Cleaner Syntax

```julia
using DataFramesMeta

# @select, @transform, @subset with cleaner syntax
@select(df, :name, :age)
@transform(df, :age_squared = :age .^ 2)
@subset(df, :age .> 25)

# Chain with @chain
@chain df begin
    @subset(:age .> 25)
    @transform(:bonus = :salary .* 0.1)
    @select(:name, :salary, :bonus)
end
```

### 14. Convert Back to Matrix or Array

```julia
# To matrix
matrix = Matrix(df)

# Specific columns to matrix
matrix = Matrix(select(df, [:age, :salary]))

# To array of arrays (column-wise)
arrays = [df[:, col] for col in names(df)]
```

### 15. Fast Iteration with eachrow

```julia
# Iterate over rows efficiently
for row in eachrow(df)
    println("$(row.name) is $(row.age) years old")
end

# Or use eachcol for columns
for (colname, col) in pairs(eachcol(df))
    println("Column $colname has mean $(mean(skipmissing(col)))")
end
```

## Pro Tips

- **Use `!` functions** to modify in-place and save memory
- **Use `.` broadcasting** instead of loops for vectorized operations
- **Use `@view`** when you don't need to modify data to avoid copies
- **Use `ByRow`** for row-wise operations in transform/select
- **Chain operations** with pipes `|>` or `@chain` for readable code
- **Use `DataFramesMeta.jl`** for SQL-like syntax and cleaner transformations

## Common Pitfalls to Avoid

1. **Don't forget the `.` for broadcasting**: `df.age * 2` vs `df.age .* 2`
2. **Use `:` vs `!` carefully**: `:` copies, `!` references the actual column
3. **Handle missing data**: Always consider `skipmissing=true` or `coalesce`
4. **Index with ranges**: `df[1:3, :]` not just `df[1:3]`