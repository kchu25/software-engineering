@def title = "Passing Functions to CUDA Kernels in Julia"
@def published = "27 October 2025"
@def tags = ["gpu-programming", "cuda", "julia"]

# The Ultimate Guide to Makie & CairoMakie in Julia

Hey there! Welcome to your friendly guide to creating beautiful, publication-ready plots in Julia using Makie. Think of Makie as the Swiss Army knife of plotting libraries—it's incredibly powerful, but once you get the hang of it, you'll wonder how you ever lived without it.

## Getting Started: The Basics

First things first, let's get you set up:

```julia
using CairoMakie  # This automatically loads Makie too!
CairoMakie.activate!()  # Use CairoMakie as the backend
```

**Why CairoMakie?** It's perfect for static, high-quality outputs (think papers, reports). If you want interactive plots, check out `GLMakie` instead, but we'll focus on CairoMakie here.

### Your First Figure

Everything in Makie starts with a `Figure`. Think of it as your canvas:

```julia
f = Figure(size = (800, 600), backgroundcolor = :white)
```

You can customize all sorts of things right from the start—size, background color, font family, resolution for publication quality, you name it.

## Understanding the Layout System: The GridLayout Magic

Here's where Makie really shines. Instead of fighting with subplot layouts, Makie gives you a **grid system** that's intuitive once you get it.

### The Mental Model

Think of your figure as a **grid of cells**. You can place anything in these cells:
- Axes (for plotting)
- Colorbars
- Legends
- Labels
- Even other grids (nested layouts!)

```julia
f = Figure()

# Create an axis in row 1, column 1
ax = Axis(f[1, 1], xlabel = "X Label", ylabel = "Y Label")

# Create another in row 1, column 2
ax2 = Axis(f[1, 2])

# Span multiple cells! This goes in row 2, across both columns
ax3 = Axis(f[2, 1:2])

f
```

### GridLayout: When You Need More Control

For complex layouts, you'll want to create explicit `GridLayout` objects. This is super useful when you want to group related plots together and control their spacing independently:

```julia
f = Figure(size = (1000, 700))

# Create separate GridLayouts
ga = f[1, 1] = GridLayout()  # Top-left section
gb = f[2, 1] = GridLayout()  # Bottom-left section
gc = f[1:2, 2] = GridLayout()  # Entire right side

# Now place axes in these grids
ax1 = Axis(ga[1, 1])
ax2 = Axis(gb[1, 1])
ax3 = Axis(gc[1, 1])

f
```

> **💡 Pro Tip: Cleaner Range Syntax**
> 
> Instead of writing `1:56, 57:100`, you can use `end` for more flexible indexing:
> ```julia
> ga = f[1:56, 1] = GridLayout()
> gb = f[57:end, 1] = GridLayout()  # From 57 to the last row
> gc = f[1:end, 2] = GridLayout()   # Entire column 2
> ```
> 
> But honestly? **For most cases, keep it simple!** Use small numbers (1, 2, 3) and adjust sizes later with `rowsize!` and `colsize!`. The grid doesn't need to match your data dimensions—it just needs to organize your visual elements. If you're thinking about 100+ rows in a layout, you might want to rethink your approach—perhaps use a single axis with multiple plot elements instead, or consider creating subplots programmatically in a loop.

> **🎯 Controlling Proportional Sizes**
>
> Want specific proportions like 0.1 : 0.45 : 0.45? Here are your options:
> 
> **Option 1: Using `Relative()` (Exact proportions)**
> ```julia
> f = Figure()
> 
> # Create your axes first
> ax1 = Axis(f[1, 1], title = "Small top section")
> ax2 = Axis(f[2, 1], title = "Large middle section")
> ax3 = Axis(f[3, 1], title = "Large bottom section")
> 
> # THEN set the row sizes
> rowsize!(f.layout, 1, Relative(0.1))   # 10% of figure height
> rowsize!(f.layout, 2, Relative(0.45))  # 45% of figure height
> rowsize!(f.layout, 3, Relative(0.45))  # 45% of figure height
> 
> f
> ```
> 
> **Option 2: Using `Auto()` with weights (More flexible)**
> ```julia
> f = Figure()
> ax1 = Axis(f[1, 1])
> ax2 = Axis(f[2, 1])
> ax3 = Axis(f[3, 1])
> 
> rowsize!(f.layout, 1, Auto(0.1))   # Weight of 0.1
> rowsize!(f.layout, 2, Auto(0.45))  # Weight of 0.45
> rowsize!(f.layout, 3, Auto(0.45))  # Weight of 0.45
> # This gives you 0.1/(0.1+0.45+0.45) = 10%, etc.
> 
> f
> ```
> 
> **Option 3: Simpler weights (Recommended!)**
> ```julia
> f = Figure()
> ax1 = Axis(f[1, 1])
> ax2 = Axis(f[2, 1])
> ax3 = Axis(f[3, 1])
> 
> rowsize!(f.layout, 1, Auto(1))   # Weight 1
> rowsize!(f.layout, 2, Auto(4.5)) # Weight 4.5
> rowsize!(f.layout, 3, Auto(4.5)) # Weight 4.5
> # Or even simpler: Auto(2), Auto(9), Auto(9) for 2:9:9 ratio
> 
> f
> ```
> 
> **The key connection:** When you write `Axis(f[1, 1])`, you're placing an Axis in row 1, column 1 of `f.layout`. The `rowsize!` and `colsize!` functions control how big those rows and columns are. So your axes automatically follow the sizing rules you set!
> 
> **Understanding `rowsize!` and `colsize!` syntax:**
> ```julia
> rowsize!(layout, row_index, size_specification)
> colsize!(layout, col_index, size_specification)
> ```
> 
> Breaking it down:
> - **`layout`**: Which grid are you modifying? (`f.layout` for main figure, or `ga`, `gb` for nested grids)
> - **`row_index` / `col_index`**: Which row or column number? (1 for first row, 2 for second, etc.)
> - **`size_specification`**: How big should it be? Options:
>   - `Auto(weight)` - Proportional sizing with a weight
>   - `Relative(fraction)` - Exact percentage (0.0 to 1.0)
>   - `Fixed(pixels)` - Exact pixel size
> 
> **Examples to make it crystal clear:**
> ```julia
> f = Figure()
> 
> # Make row 1 take 20% of the figure height
> rowsize!(f.layout, 1, Relative(0.2))
> 
> # Make row 2 have twice the weight of default rows
> rowsize!(f.layout, 2, Auto(2))
> 
> # Make column 1 exactly 300 pixels wide
> colsize!(f.layout, 1, Fixed(300))
> 
> # Make column 2 take 30% of the figure width
> colsize!(f.layout, 2, Relative(0.3))
> ```
> 
> **For nested GridLayouts:**
> ```julia
> f = Figure()
> ga = f[1, 1] = GridLayout()  # Nested layout
> 
> ax1 = Axis(ga[1, 1])
> ax2 = Axis(ga[2, 1])
> 
> # Control the nested layout's rows (note: use 'ga', not 'f.layout')
> rowsize!(ga, 1, Auto(1))   # Row 1 of ga
> rowsize!(ga, 2, Auto(4))   # Row 2 of ga
> 
> f
> ```
> 
> **When to use what?**
> - `Relative()`: When you want exact percentages regardless of content
> - `Auto()`: When you want proportions but also respect minimum sizes of content (more flexible!)
> - `Fixed()`: When you want exact pixel sizes like `Fixed(100)` for a 100px row

**Pro tip:** Store your GridLayouts in variables (like `ga`, `gb`) if you plan to adjust gaps, add titles, or manipulate them later. It's way easier than hunting through nested indices!

## Scatter Plots: The Foundation

Scatter plots are your bread and butter. Here's how to make them shine:

```julia
f = Figure()
ax = Axis(f[1, 1], 
    xlabel = "Time (s)", 
    ylabel = "Response",
    title = "My Beautiful Scatter Plot")

# Basic scatter
x = 1:10
y = rand(10)
scatter!(ax, x, y)

f
```

### Customizing Your Scatters

The fun part! You can control almost everything:

```julia
# Different marker types
scatter!(ax, x, y, 
    marker = :circle,      # or :rect, :diamond, :cross, :utriangle, etc.
    markersize = 20,       # size in pixels
    color = :red,          # or use :steelblue, RGB values, etc.
    strokecolor = :black,  # outline color
    strokewidth = 2)       # outline thickness

# Color by a variable (continuous)
colors = rand(10)
scatter!(ax, x, y, color = colors, colormap = :viridis)

# Different sizes per point
sizes = rand(10) .* 30
scatter!(ax, x, y, markersize = sizes)

# Transparency
scatter!(ax, x, y, alpha = 0.5)  # or use color = (:red, 0.5)
```

### Multiple Series with Legends

```julia
f = Figure()
ax = Axis(f[1, 1])

# Plot multiple series with labels
scatter!(ax, x1, y1, label = "Treatment", color = :blue)
scatter!(ax, x2, y2, label = "Control", color = :red)
scatter!(ax, x3, y3, label = "Placebo", color = :green)

# Add the legend
Legend(f[1, 2], ax)  # Places it in column 2

# Or place it within the axis
axislegend(ax, position = :rt)  # rt = right-top, also :lt, :lb, :rb

f
```

## Histograms: Distribution Visualization

Histograms in Makie are straightforward and flexible:

```julia
f = Figure()
ax = Axis(f[1, 1], xlabel = "Value", ylabel = "Count")

data = randn(1000)  # Random normal data

# Basic histogram
hist!(ax, data)

f
```

### Customizing Histograms

```julia
# Control the bins
hist!(ax, data, bins = 30)  # specific number of bins
hist!(ax, data, bins = -3:0.5:3)  # explicit bin edges

# Colors and styling
hist!(ax, data, 
    color = :steelblue,
    strokecolor = :black,
    strokewidth = 1)

# Normalization options
hist!(ax, data, normalization = :pdf)  # probability density
hist!(ax, data, normalization = :probability)  # sums to 1

# Horizontal histograms
hist!(ax, data, direction = :x)  # now bins are on y-axis
```

### Multiple Histograms (Overlapping or Dodged)

```julia
f = Figure()
ax = Axis(f[1, 1])

group1 = randn(1000)
group2 = randn(1000) .+ 2

# Overlapping with transparency
hist!(ax, group1, color = (:blue, 0.5), label = "Group 1")
hist!(ax, group2, color = (:red, 0.5), label = "Group 2")
axislegend(ax)

f
```

For side-by-side (dodged) histograms, you'll want to use `barplot!` with pre-computed bin counts, or check out the `AlgebraOfGraphics.jl` package which makes this easier.

## Boxplots: Taking Full Control

Now we're getting to the good stuff! Boxplots in Makie give you incredible control, including the whiskers.

### Basic Boxplot

```julia
using CairoMakie

f = Figure()
ax = Axis(f[1, 1], ylabel = "Value")

# Data: categories and values
categories = repeat(1:3, inner = 50)
values = randn(150) .+ categories

boxplot!(ax, categories, values)

# Label the categories
ax.xticks = (1:3, ["Control", "Treatment A", "Treatment B"])

f
```

### Customizing Whiskers: The Inside-Out Details

Here's where it gets really interesting. Makie's `boxplot` function has several parameters that control whiskers:

```julia
boxplot!(ax, categories, values,
    # Whisker range (default is 1.5 for 1.5*IQR)
    range = 1.5,  # This is the multiplier for IQR
    
    # Show outliers
    show_outliers = true,
    
    # Whisker style
    whiskerwidth = 0.5,  # Width relative to box
    
    # Box customization
    width = 0.8,  # Box width
    color = :lightblue,
    strokecolor = :black,
    strokewidth = 2)
```

### Understanding the `range` Parameter

> **What's IQR?** IQR stands for **Interquartile Range**—it's the distance between the 25th percentile (Q1) and 75th percentile (Q3). Basically, it's the height of the box in your boxplot! It represents the middle 50% of your data. Using 1.5 × IQR is a classic statistical convention from John Tukey for identifying outliers.

The `range` parameter controls how far the whiskers extend:

- `range = 1.5` (default): Whiskers extend to 1.5 × IQR from the quartiles
- `range = 0`: Whiskers extend to min/max of data (no outliers)
- `range = 2.0`: More conservative, fewer outliers

```julia
f = Figure()

# Compare different ranges
ax1 = Axis(f[1, 1], title = "range = 1.5 (default)")
boxplot!(ax1, categories, values, range = 1.5)

ax2 = Axis(f[1, 2], title = "range = 0 (min/max)")
boxplot!(ax2, categories, values, range = 0)

ax3 = Axis(f[1, 3], title = "range = 3.0 (conservative)")
boxplot!(ax3, categories, values, range = 3.0)

f
```

### Manual Control: Computing Your Own Whiskers

For ultimate control, you can compute the box plot statistics yourself and use `rangebars!`:

```julia
using Statistics

function my_boxplot_stats(data; whisker_range = 1.5)
    q1, q2, q3 = quantile(data, [0.25, 0.5, 0.75])
    iqr = q3 - q1
    
    # Compute whisker positions
    lower_fence = q1 - whisker_range * iqr
    upper_fence = q3 + whisker_range * iqr
    
    # Whiskers go to most extreme data point within fences
    lower_whisker = maximum(x -> x >= lower_fence ? x : -Inf, data)
    upper_whisker = minimum(x -> x <= upper_fence ? x : Inf, data)
    
    # Find outliers
    outliers = filter(x -> x < lower_fence || x > upper_fence, data)
    
    return (q1 = q1, q2 = q2, q3 = q3, 
            lower = lower_whisker, upper = upper_whisker,
            outliers = outliers)
end

# Use it
f = Figure()
ax = Axis(f[1, 1])

data = randn(100)
stats = my_boxplot_stats(data)

# Draw box
x_pos = 1
box_width = 0.4

# Use poly! for the box
poly!(ax, Point2f[(x_pos - box_width/2, stats.q1),
                   (x_pos + box_width/2, stats.q1),
                   (x_pos + box_width/2, stats.q3),
                   (x_pos - box_width/2, stats.q3)],
      color = :lightblue, strokecolor = :black, strokewidth = 2)

# Median line
lines!(ax, [x_pos - box_width/2, x_pos + box_width/2],
       [stats.q2, stats.q2], color = :black, linewidth = 3)

# Whiskers
linesegments!(ax, [Point2f(x_pos, stats.q3), Point2f(x_pos, stats.upper)],
              color = :black)
linesegments!(ax, [Point2f(x_pos, stats.q1), Point2f(x_pos, stats.lower)],
              color = :black)

# Whisker caps
whisker_cap = box_width / 4
linesegments!(ax, [Point2f(x_pos - whisker_cap, stats.upper),
                    Point2f(x_pos + whisker_cap, stats.upper)],
              color = :black)
linesegments!(ax, [Point2f(x_pos - whisker_cap, stats.lower),
                    Point2f(x_pos + whisker_cap, stats.lower)],
              color = :black)

# Outliers
if !isempty(stats.outliers)
    scatter!(ax, fill(x_pos, length(stats.outliers)), stats.outliers,
             color = :red, markersize = 8)
end

f
```

### Horizontal Boxplots

```julia
boxplot!(ax, values, categories, orientation = :horizontal)
```

### Grouped Boxplots

```julia
f = Figure()
ax = Axis(f[1, 1])

categories = repeat(1:3, inner = 50)
groups = repeat([1, 2], 75)  # Two groups
values = randn(150) .+ categories

boxplot!(ax, categories, values, 
    dodge = groups,  # This creates side-by-side boxes
    color = groups,  # Color by group
    colormap = [:blue, :red])

# Add legend
labels = ["Group A", "Group B"]
elements = [PolyElement(polycolor = c) for c in [:blue, :red]]
Legend(f[1, 2], elements, labels)

f
```

## Building Complex Layouts: Putting It All Together

Let's create a multi-panel figure with everything we've learned. This follows the philosophy from the Makie layout tutorial: think in rectangular boxes!

```julia
f = Figure(size = (1200, 800), backgroundcolor = :white)

# Create main grid sections
ga = f[1, 1] = GridLayout()  # Top-left: Scatter with margins
gb = f[2, 1] = GridLayout()  # Bottom-left: Histogram
gc = f[1:2, 2] = GridLayout()  # Right side: Boxplot

# === Panel A: Scatter with marginal distributions ===
axtop = Axis(ga[1, 1])  # Top marginal
axmain = Axis(ga[2, 1], xlabel = "X", ylabel = "Y")  # Main scatter
axright = Axis(ga[2, 2])  # Right marginal

# Link axes so they zoom together
linkyaxes!(axmain, axright)
linkxaxes!(axmain, axtop)

# Generate data
x = randn(200)
y = randn(200)

# Plot
scatter!(axmain, x, y, color = (:steelblue, 0.5), markersize = 10)
hist!(axtop, x, bins = 30, color = :steelblue)
hist!(axright, y, bins = 30, direction = :x, color = :steelblue)

# Clean up marginal plots
hidedecorations!(axtop, grid = false)
hidedecorations!(axright, grid = false)
ylims!(axtop, low = 0)
xlims!(axright, low = 0)

# Tighten the layout
colgap!(ga, 10)
rowgap!(ga, 10)

# Add title
Label(ga[1, 1:2, Top()], "Scatter with Marginals",
      font = :bold, padding = (0, 0, 5, 0))

# === Panel B: Histogram ===
axhist = Axis(gb[1, 1], xlabel = "Value", ylabel = "Frequency")

# Multiple distributions
data1 = randn(500)
data2 = randn(500) .+ 1.5

hist!(axhist, data1, color = (:blue, 0.5), label = "Group 1", bins = 30)
hist!(axhist, data2, color = (:red, 0.5), label = "Group 2", bins = 30)
axislegend(axhist, position = :rt)

Label(gb[1, 1, Top()], "Distribution Comparison",
      font = :bold, padding = (0, 0, 5, 0))

# === Panel C: Boxplot ===
axbox = Axis(gc[1, 1], ylabel = "Response Value")

categories = repeat(1:4, inner = 50)
values = randn(200) .+ [0, 1, 2, 1][categories]

boxplot!(axbox, categories, values,
    color = :lightblue,
    whiskerwidth = 0.5,
    range = 1.5,
    show_outliers = true)

axbox.xticks = (1:4, ["Control", "Low", "High", "Recovery"])

Label(gc[1, 1, Top()], "Treatment Effects",
      font = :bold, padding = (0, 0, 5, 0))

# === Add panel labels ===
for (label, layout) in zip(["A", "B", "C"], [ga, gb, gc])
    Label(layout[1, 1, TopLeft()], label,
        fontsize = 26,
        font = :bold,
        padding = (0, 5, 5, 0),
        halign = :right)
end

# === Final adjustments ===
# Make left column narrower
colsize!(f.layout, 1, Auto(0.6))

f
```

## Advanced Layout Tips

### Controlling Gaps

```julia
# Row and column gaps for entire figure
rowgap!(f.layout, 20)
colgap!(f.layout, 20)

# For specific grids
rowgap!(ga, 5)
colgap!(ga, 10)

# For specific gaps
rowgap!(ga, 1, 20)  # Gap after row 1
```

### Controlling Sizes

```julia
# Relative sizing
colsize!(f.layout, 1, Auto(0.5))  # Half the weight of other Auto columns

# Fixed sizes
colsize!(f.layout, 1, Fixed(300))  # 300 pixels

# Relative to figure
colsize!(f.layout, 1, Relative(0.3))  # 30% of figure width

# For rows
rowsize!(f.layout, 1, Auto(1.5))  # 1.5x weight
```

### Linking Axes

This is super useful for synchronized zooming/panning:

```julia
# Link x-axes
linkxaxes!(ax1, ax2, ax3)

# Link y-axes
linkyaxes!(ax1, ax2)
```

## Saving Your Masterpiece

```julia
# Save as PNG
save("myplot.png", f, px_per_unit = 2)  # High resolution

# Save as PDF (vector graphics!)
save("myplot.pdf", f)

# Save as SVG
save("myplot.svg", f)

# Control resolution
save("myplot.png", f, px_per_unit = 3)  # Even higher resolution
```

## Quick Reference: Common Customizations

### Axis Attributes

```julia
ax = Axis(f[1, 1],
    xlabel = "X Label",
    ylabel = "Y Label",
    title = "My Title",
    xlabelsize = 20,
    ylabelsize = 20,
    xticklabelsize = 14,
    yticklabelsize = 14,
    xticks = 0:2:10,  # Custom tick positions
    yticks = ([-1, 0, 1], ["Low", "Med", "High"]),  # Custom labels
    limits = (0, 10, -5, 5),  # (xmin, xmax, ymin, ymax)
    aspect = 1)  # Square aspect ratio
```

### Colors

```julia
# Named colors
color = :red
color = :steelblue

# RGB
color = RGB(0.2, 0.4, 0.8)

# With alpha
color = (:red, 0.5)

# Colormaps (for continuous data)
colormap = :viridis
colormap = :plasma
colormap = :RdBu  # Diverging
colormap = Reverse(:viridis)  # Reverse a colormap
```

### Line Styles

```julia
lines!(ax, x, y,
    color = :blue,
    linewidth = 2,
    linestyle = :solid)  # or :dash, :dot, :dashdot

# Custom patterns
linestyle = [0, 10, 5, 5]  # Advanced: on, off, on, off pattern in pixels
```

## Pro Tips and Gotchas

1. **The Bang (!)**: Functions with `!` modify existing objects. `scatter!` adds to an existing axis, `scatter` creates a new one.

2. **Updating Plots**: You can store plot objects and update them:
   ```julia
   s = scatter!(ax, x, y)
   s.color = :red  # Updates the plot
   ```

3. **Observables**: For animations or interactive updates, use `Observable`:
   ```julia
   data = Observable(Point2f[(1,1), (2,2)])
   scatter!(ax, data)
   data[] = Point2f[(1,2), (2,1)]  # Updates automatically!
   ```

4. **Theme**: Set default styles for everything:
   ```julia
   set_theme!(Theme(
       fontsize = 18,
       Axis = (xlabelsize = 20, ylabelsize = 20),
       palette = (color = [:red, :blue, :green],)
   ))
   ```

5. **Aspect Ratios**: For equal x and y scaling:
   ```julia
   ax.aspect = DataAspect()  # 1 data unit = 1 data unit
   ax.aspect = 1  # Same as DataAspect
   ```

## Troubleshooting

**Plot isn't showing?** Remember to return `f` at the end, or call `display(f)`.

**Layout looks weird?** Check your gaps with `colgap!` and `rowgap!`, and consider using `Auto()` for column/row sizes.

**Legend covering data?** Use `Legend(f[1, 2], ax)` to place it outside, or adjust `axislegend(position = :rt)`.

**Need more space around labels?** Makie auto-calculates protrusions, but you can set them manually: `ax.xticklabelpad = 10`.

## Where to Learn More

- **Official Docs**: https://docs.makie.org/stable/
- **Examples**: https://beautiful.makie.org/
- **Discourse**: https://discourse.julialang.org/c/domain/viz/
- **GitHub**: https://github.com/MakieOrg/Makie.jl

Happy plotting! Remember: Makie's layout system might feel different at first, but once you think in grids and layouts, you'll be creating publication-quality figures faster than you ever thought possible. 🎨📊