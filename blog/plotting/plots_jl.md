@def title = "Understanding Plot Recipes in Julia Plots.jl"
@def published = "6 October 2025"
@def tags = ["plotting", "julia"]


# Understanding Plot Recipes in Julia Plots.jl

## What's a Plot Recipe? (ELI5 Version)

Imagine you want to teach your robot how to draw different things. Instead of telling it "move pencil here, then there" every single time, you give it a **recipe** - like a cooking recipe but for drawing!

A plot recipe says: "When someone gives you THIS type of data, automatically turn it into THAT type of plot."

## The Magic Behind the Macros

Plots.jl uses macros (the `@` symbols) to generate a LOT of boring code for you. Let's unwrap what's actually happening.

### Example 1: The Simplest Recipe

```julia
using Plots

# This is what you write:
@recipe function f(::Type{Val{:myline}}, x, y, z)
    linewidth --> 3
    seriescolor --> :blue
    seriestype := :path
    x, y
end

# What this ACTUALLY does behind the scenes:
# 1. Creates a new plot type called :myline
# 2. When someone uses plot(x, y, seriestype=:myline)...
# 3. Set linewidth to 3 (if user didn't specify)
# 4. Set color to blue (if user didn't specify)
# 5. Actually draw it as a :path (line)
# 6. Return the x, y data to plot
```

**Key operators:**
- `-->` means "use this DEFAULT if user didn't specify"
- `:=` means "FORCE this value, ignore what user said"
- `x, y` at the end = "here's the data to actually plot"

### Example 2: A Custom Type Recipe

Let's say you have a custom data type:

```julia
# Your custom data structure
struct Histogram
    edges::Vector{Float64}
    counts::Vector{Int}
end

# Recipe tells Plots how to visualize it
@recipe function f(h::Histogram)
    # Set some defaults
    seriestype := :bar
    fillcolor --> :lightblue
    legend --> false
    
    # Return x and y data
    h.edges[1:end-1], h.counts
end

# Now you can just do:
my_hist = Histogram([0, 1, 2, 3], [5, 3, 8])
plot(my_hist)  # Automatically knows how to draw it!
```

**What happened:**
1. You created a `Histogram` type
2. The recipe tells Plots: "When you see a Histogram, draw it as bars"
3. No need to manually extract edges and counts every time!

### Example 3: User Recipe (Plot Layout)

```julia
@userplot CirclePlot

@recipe function f(cp::CirclePlot)
    # Extract the data (CirclePlot wraps it in cp.args)
    x, y, radius = cp.args
    
    # Create the circle points
    θ = range(0, 2π, length=100)
    circle_x = x .+ radius .* cos.(θ)
    circle_y = y .+ radius .* sin.(θ)
    
    # Style it
    aspect_ratio := :equal
    seriestype := :path
    linewidth --> 2
    
    # Return the circle coordinates
    circle_x, circle_y
end

# Usage:
circleplot(0, 0, 5)  # Draws a circle at origin with radius 5
```

**What `@userplot` does:**
1. Creates a function `circleplot(args...)`
2. Wraps your arguments into `CirclePlot(args)`
3. Passes it to your recipe
4. Your recipe processes it and returns plot data

## The Three Types of Recipes

### 1. **Type Recipes** - Convert custom types to plot data
```julia
@recipe function f(my_custom_type::MyType)
    # Extract x, y from your type
    # Return: x_data, y_data
end
```

### 2. **User Recipes** - Create new plot commands
```julia
@userplot MyPlot
@recipe function f(mp::MyPlot)
    # Process mp.args
    # Return: x_data, y_data
end
# Creates: myplot(args...) function
```

### 3. **Series Recipes** - Create new plot types
```julia
@recipe function f(::Type{Val{:mytype}}, x, y, z)
    # Transform data
    # Return: x_data, y_data
end
# Use with: plot(x, y, seriestype=:mytype)
```

## Real World Example: Error Bars

```julia
@userplot ErrorPlot

@recipe function f(ep::ErrorPlot)
    x, y, yerr = ep.args
    
    # Main points
    @series begin
        seriestype := :scatter
        markersize --> 6
        label --> "Data"
        x, y
    end
    
    # Error bars
    @series begin
        seriestype := :path
        linecolor --> :black
        label := ""
        
        # Create vertical lines for errors
        xerr = vec(vcat(x', x', fill(NaN, 1, length(x))))
        yerr_plot = vec(vcat((y .- yerr)', (y .+ yerr)', fill(NaN, 1, length(x))))
        xerr, yerr_plot
    end
end

# Usage:
errorplot([1, 2, 3], [2, 4, 3], [0.5, 0.3, 0.7])
```

**What `@series` does:**
- Lets you create MULTIPLE plot series in one recipe
- Each `@series begin...end` block = one thing drawn on the plot

## The Pattern Summarized

1. **Define what triggers the recipe** (a type, a Val type, or @userplot)
2. **Extract/process the data** 
3. **Set defaults with `-->`** (user can override)
4. **Force settings with `:=`** (user cannot override)
5. **Return x, y data** to actually plot
6. **Use `@series`** if you need to draw multiple things

## Why is the function always called `f`?

**YES, it's multiple dispatch!** The function name `f` is just a placeholder - the macro doesn't care what you call it. What matters is the **type signature**.

```julia
# These are ALL different functions due to multiple dispatch:

@recipe function f(::Type{Val{:myline}}, x, y, z)
    # Dispatch on Val{:myline}
end

@recipe function f(h::Histogram)
    # Dispatch on Histogram type
end

@recipe function f(cp::CirclePlot)
    # Dispatch on CirclePlot type
end

# Julia sees these as:
# - f(::Type{Val{:myline}}, ...)
# - f(::Histogram)
# - f(::CirclePlot)
# They're DIFFERENT functions!
```

**The macro transforms your `f` into something like:**

```julia
# What you write:
@recipe function f(h::Histogram)
    # ... recipe code ...
end

# What the macro generates (simplified):
RecipesBase.apply_recipe(plotattributes::Dict, h::Histogram) = begin
    # ... your recipe code inserted here ...
end
```

So `f` is just a **temporary name during the macro**. The macro:
1. Looks at your function signature
2. Extracts the type information
3. Generates the real function name (`apply_recipe`)
4. Uses **multiple dispatch** on the type to route to your code

**You could call it `plot_me` or `banana` - doesn't matter:**

```julia
@recipe function banana(h::Histogram)  # Works fine!
    seriestype := :bar
    h.edges[1:end-1], h.counts
end
```

The convention is `f` because:
- It's short
- Everyone uses it (convention)
- The name gets thrown away anyway

**The real magic is the type signature**, which tells Julia "when you see a Histogram, call THIS version of the recipe function."

## Why Macros?

The macros generate code that:
- Registers your recipe with Plots.jl
- Handles argument passing
- Manages attribute inheritance
- Creates helper functions
- Transforms your `f(type_signature)` into `apply_recipe(::Dict, type_signature)`

Without macros, you'd need to write ~50 lines of boilerplate for each recipe. With macros, you write 5-10 lines!