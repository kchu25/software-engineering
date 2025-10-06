@def title = "Measure Theory 2: from simple functions to Lebesgue Integral"
@def published = "5 October 2025"
@def tags = ["measure-theory"]



## 4. Simple Functions: The Building Blocks

Alright, now we're getting to the good stuff. Simple functions are the foundation of Lebesgue integration.

A **simple function** takes only finitely many values:
$$s(x) = \sum_{i=1}^{n} a_i \mathbf{1}_{A_i}(x)$$

where:
- $a_i \in \mathbb{R}$ are distinct values
- $A_i \in \mathcal{F}$ are disjoint measurable sets
- $\mathbf{1}_{A_i}$ is the indicator function: equals 1 if $x \in A_i$, else 0

**Think of simple functions like this**: They're quantized or discretized versions of continuous functions. Like a histogram or a step function in image processing. Each "bin" is a measurable set $A_i$, and the function value is constant ($a_i$) on that bin.

**Why do simple functions matter so much?** Because of this beautiful theorem:

**Any non-negative measurable function $f: X \to [0, \infty]$ can be approximated from below by an increasing sequence of simple functions:**
$$0 \leq s_1 \leq s_2 \leq \cdots \leq f$$
with $s_n(x) \to f(x)$ pointwise for all $x$.

**How do you construct this sequence?** For $f \geq 0$, define:

Define $s_n(x)$ for $f \geq 0$ as follows (in GitHub-friendly format):

- If $f(x) < n$, let $k$ be the unique integer such that $\frac{k}{2^n} \leq f(x) < \frac{k+1}{2^n}$, and set $s_n(x) = \frac{k}{2^n}$.
- If $f(x) \geq n$, set $s_n(x) = n$.

This discretizes the range of $f$ into bins of width $1/2^n$. As $n$ increases, the bins get finer and $s_n$ gets closer to $f$.

---

## 5. Integrating Simple Functions

Here's where it all pays off. For a simple function $s(x) = \sum_{i=1}^{n} a_i \mathbf{1}_{A_i}(x)$, we define:

$$\int_X s  d\mu = \sum_{i=1}^{n} a_i \mu(A_i)$$

This is completely natural! The integral is just a weighted sum: the value $a_i$ times the "size" of the set where $s$ takes value $a_i$.

**Example**: If $s(x) = 3 \cdot \mathbf{1}([0,1]) + 5 \cdot \mathbf{1}([1,2])$ and $\mu$ is Lebesgue measure on $\mathbb{R}$:
$$\int s  d\mu = 3 \cdot 1 + 5 \cdot 1 = 8$$

The function has value 3 on an interval of length 1, and value 5 on an interval of length 1, so the total integral is $3 + 5 = 8$.

**Discrete connection**: For counting measure on a finite set $\{x_1, \ldots, x_n\}$:
$$\int s  d\mu = \sum_{i=1}^{n} s(x_i)$$
Integration literally becomes summation!

---

# The Lebesgue Integral for Non-negative Functions

## Riemann vs Lebesgue: Two Ways to Measure Area

### The Coin-Sorting Analogy

Imagine you have a pile of coins of different values and you want to know the total value.

**Riemann's approach** (sort by position):
- Line up all coins in a row
- Divide the row into sections
- In each section, approximate: "these coins are worth about $X$"
- Sum up: (number of coins in section 1) × (approximate value) + ...

**Lebesgue's approach** (sort by value):
- Sort coins by value first: all pennies together, all nickels together, all dimes together
- Count how many of each type you have
- Multiply: (number of pennies) × (1¢) + (number of nickels) × (5¢) + ...

### Applied to Integration

**Riemann**: Partition the **domain** (x-axis)
```
     y
     |     function f(x)
   4 |        ___
   3 |    ___/   \___
   2 |   /           \
   1 |  /             \
   0 |_/_________________x
       |  |  |  |  |  |
       x₁ x₂ x₃ x₄ x₅ x₆  ← slice the x-axis
```
- Cut the x-axis into small intervals [x₁,x₂], [x₂,x₃], ...
- On each interval, pick a height (say, the function's value somewhere in that interval)
- Area ≈ (width of interval) × (height) for each piece

**Lebesgue**: Partition the **range** (y-axis)
```
     y
   4 |--------  y₄        ← horizontal slices
   3 |--------  y₃
   2 |--------  y₂
   1 |--------  y₁
   0 |_________________x
       
   Ask: "Where is f(x) between y₁ and y₂?"
        "Where is f(x) between y₂ and y₃?"
```
- Cut the y-axis into small intervals [y₁,y₂], [y₂,y₃], ...
- For each y-interval, find **all x-values where f(x) lands in that interval**
- Measure the **size** (length, area, volume, etc.) of those x-values
- Area ≈ (height of y-interval) × (measure of {x : y₁ ≤ f(x) < y₂})

### A Concrete Example

Let $f(x) = \begin{cases} 2 & x \in [0, 0.3] \cup [0.7, 1] \\ 3 & x \in (0.3, 0.7) \end{cases}$

```
   y
 3 |        ___________
 2 |________|         |______
 1 |
 0 |________________________x
   0      0.3       0.7    1
```

**Riemann thinking** (slice by x):
- "From x=0 to x=0.3 (width 0.3), height is 2" → contributes $0.3 \times 2 = 0.6$
- "From x=0.3 to x=0.7 (width 0.4), height is 3" → contributes $0.4 \times 3 = 1.2$
- "From x=0.7 to x=1 (width 0.3), height is 2" → contributes $0.3 \times 2 = 0.6$
- Total: $0.6 + 1.2 + 0.6 = 2.4$

**Lebesgue thinking** (group by y-value):
- "Where is f equal to 2? On two disjoint pieces: [0, 0.3] and [0.7, 1]"
  - Total measure: $0.3 + 0.3 = 0.6$
  - Contributes: $2 \times 0.6 = 1.2$
- "Where is f equal to 3? On one piece: (0.3, 0.7)"
  - Total measure: $0.4$
  - Contributes: $3 \times 0.4 = 1.2$
- Total: $1.2 + 1.2 = 2.4$

**Key difference**: 
- Riemann processes each x-interval separately, even if they have the same height
- Lebesgue **collects all x-values with the same height**, no matter where they are!

This is the power of "sorting by value": even if f(x)=2 appears in scattered, disjoint pieces across the domain, Lebesgue groups them together by their common y-value.

### Why Lebesgue Handles Pathology Better

**The Dirichlet function**:

Dirichlet function (GitHub-friendly):

  f(x) = 1 if x is rational
  f(x) = 0 if x is irrational

**Riemann fails**: 
- Pick any interval [a, b]
- It contains both rationals AND irrationals (densely!)
- You can't approximate f consistently on any interval
- Every Riemann sum oscillates wildly between 0 and 1

**Lebesgue succeeds**:
- "Where does f equal 0?" → on all irrationals in [0,1]
- "Where does f equal 1?" → on all rationals in [0,1]
- The irrationals have measure 1, the rationals have measure 0
- Integral = $(0 \times \mu(\text{irrationals})) + (1 \times \mu(\text{rationals})) = 0 \times 1 + 1 \times 0 = 0$

By sorting by **value** rather than **position**, Lebesgue can separate the "good" set (irrationals, measure 1) from the "bad" set (rationals, measure 0), even though they're hopelessly intermingled on the x-axis!

### The Key Insight

- **Riemann**: "Partition the input space, measure output"
- **Lebesgue**: "Partition the output space, measure input"

This is why Lebesgue integration naturally extends to weird measure spaces (probability spaces, infinite-dimensional spaces, fractal sets) while Riemann is stuck on nice intervals.

---

## Definition


Here, $\mu$ is the **measure** on $(X, \mathcal{F})$—it assigns a non-negative size to each measurable set in $\mathcal{F}$. It is *not* a function you integrate, but rather the rule that tells you how to measure the size of sets (like length, area, probability, etc.).

<sup>**Footnote:** The measurable function $f$ is what you put inside the integral (the integrand)—it's the thing you're "measuring". The measure $\mu$ is like the "ruler" or measuring system that tells you how big each set is. The Lebesgue integral $\int f \, d\mu$ combines both: it sums up the values of $f$ using $\mu$ as the way to measure the domain.</sup>

For a **non-negative measurable** function $f: X \to [0, \infty]$:

$$\int_X f \, d\mu = \sup \Set{\int_X s \, d\mu : s \text{ simple, } 0 \leq s \leq f }$$

## The Core Intuition

Think of measuring the area under a complicated curve. You can't measure it directly, so instead you:

1. **Build staircases underneath the curve** (simple functions $s$ with $s \leq f$)
2. **Make them taller and taller**, getting closer to the actual curve
3. **Take the supremum** as your staircases approach the space under $f$

**Key insight**: Even if $f$ is wildly complicated, we can always approximate it from below using simple functions, and these we *already know how to integrate*.

---

## Visual Picture: Approximating from Below

Imagine $f$ is a bumpy, continuous function. We approximate it with increasingly fine simple functions that **always stay below** $f$:

```
Target function f(x):
    |     ___
    |    /   \___
    |   /        \___
    |  /             \
    |_/___________________


Step 1: Rough approximation s₁ (2 steps)
    |     ___
    |    /   \___        ← f is here (target)
    |   /____    \___
    |  |    |        |   ← s₁ stays below
    |__|____|________|___
       a₁   a₂


Step 2: Better approximation s₂ (4 steps)
    |     ___
    |    /   \___        ← f is here
    |   /____|___|\___
    |  | ___|   | \__|  ← s₂ gets closer, still ≤ f
    |__|_|__|___|__|_|__
       b₁ b₂ b₃  b₄


Step 3: Even finer s₃ (8 steps)
    |     ___
    |    /   \___        ← f is here
    |   /_|__|__|\___
    |  |_||_||__||_\||  ← s₃ even closer, still ≤ f
    |__|_||_||__|_|_||_
       (8 intervals)
```

**The key relationship**: At every point $x$, we have:
$$s_1(x) \leq s_2(x) \leq s_3(x) \leq \cdots \leq f(x)$$

As the steps get finer: $s_n \uparrow f$ (pointwise), and therefore:
$$\int s_1 \, d\mu \leq \int s_2 \, d\mu \leq \int s_3 \, d\mu \leq \cdots \to \int f \, d\mu$$

---

## Alternative Formulation

If $(s_n)$ is any sequence of simple functions with $s_n \uparrow f$ (meaning $s_n(x)$ increases to $f(x)$ at each point), then:

$$\int_X f \, d\mu = \lim_{n \to \infty} \int_X s_n \, d\mu$$

This limit always exists (though it might be $\infty$) because the sequence of integrals is **monotone increasing** and bounded above by $\sup$.

---

## Example 1: A Simple Case

Let $f(x) = x$ on $[0, 1]$ with Lebesgue measure.

**Simple function approximations** (one possible sequence):

- $s_1(x) = \begin{cases} 0 & x \in [0, 1/2) \\ 1/2 & x \in [1/2, 1] \end{cases}$

- $s_2(x) = \frac{k}{4}$ for $x \in [k/4, (k+1)/4)$, $k = 0, 1, 2, 3$

- $s_3(x) = \frac{k}{8}$ for $x \in [k/8, (k+1)/8)$, $k = 0, 1, \ldots, 7$

**The connection**: At any point $x \in [0,1]$:
- $s_1(x) \leq x$ (the staircase is below the line)
- $s_2(x) \leq x$ (finer staircase, still below)
- $s_3(x) \leq x$ (even finer, still below)
- As $n \to \infty$: $s_n(x) \to x$ from below

Therefore:
$$\int_0^1 s_n \, dx \to \int_0^1 x \, dx = \frac{1}{2}$$

---

## Example 2: An Unbounded Function

Let $f(x) = \frac{1}{\sqrt{x}}$ on $(0, 1]$ with Lebesgue measure.

**Approximation from below**:
$$s_n(x) = \min\left(\frac{1}{\sqrt{x}}, n\right)$$

**The connection**: 
- Each $s_n$ **truncates** $f$ at height $n$
- $s_n(x) \leq f(x)$ for all $x$ (we're capping the height)
- $s_1(x) \leq s_2(x) \leq s_3(x) \leq \cdots$ (increasing caps)
- As $n \to \infty$: $s_n(x) \to f(x)$ at every point

Each $s_n$ is bounded, so we can integrate it:
$$\int_0^1 s_n \, dx \to \int_0^1 \frac{1}{\sqrt{x}} \, dx = 2$$

Even though $f$ blows up at $0$, the integral exists and equals $2$.

---

## Example 3: When the Integral is Infinite

Let $f(x) = \frac{1}{x}$ on $(0, 1]$ with Lebesgue measure.

**Truncated approximations**:
$$s_n(x) = \min\left(\frac{1}{x}, n\right)$$

**The connection**:
- $s_n(x) \leq f(x)$ everywhere (truncating at height $n$)
- $s_n \uparrow f$ as $n \to \infty$

Computing:
$$\int_0^1 s_n \, dx = \int_{1/n}^1 \frac{1}{x} \, dx + \int_0^{1/n} n \, dx = \ln(n) + \frac{1}{n} \to \infty$$

So $\int_0^1 \frac{1}{x} \, dx = \infty$ in the Lebesgue sense.

**Interpretation**: Even our best simple approximations from below have infinite integral, so $f$ itself has infinite integral.

---

## Why This Definition Works

✓ **Monotonicity**: If $f \leq g$, then $\int f \leq \int g$ (every simple function under $f$ is also under $g$)

✓ **Linearity for sums**: $\int (f + g) = \int f + \int g$ (when both sides make sense)

✓ **Matches Riemann**: For nice functions like polynomials, this gives the same answer as Riemann integration

✓ **Handles pathology**: Works even when $f$ is discontinuous everywhere!

✓ **Defines integral uniquely**: The supremum gives a single well-defined value (possibly $\infty$)

---

## The Big Picture

```
Simple functions s with s ≤ f
         ↓
    ∫ s dμ  (we know how to compute this)
         ↓
    Take supremum over all such s
         ↓
    ∫ f dμ  (defines the integral of f)
```

The beauty: we've reduced integrating *any* non-negative measurable function to integrating simple functions, which we already understand!
The beauty: we've reduced integrating *any* non-negative measurable function to integrating simple functions, which we already understand!
### Riemann vs Lebesgue: The Big Picture

**Riemann integration**: You partition the domain (the x-axis) into little intervals and approximate the function's height on each interval.

**Lebesgue integration**: You partition the range (the y-axis) into little intervals and measure the sets where the function takes those values.

**From a CS perspective**: 
- Riemann asks: "For each x-bucket, what's f(x)?"
- Lebesgue asks: "For each y-value, what's the size of the set {x : f(x) ≈ y}?"

The Lebesgue approach handles discontinuities way better. For example, the Dirichlet function (equals 1 on rationals, 0 on irrationals) is Lebesgue integrable (with integral 0) but not Riemann integrable at all!

---

## 7. General Functions (Including Negative Values)

What about functions that can be negative? Easy - split them into positive and negative parts.

For any measurable function $f: X \to \mathbb{R}$, define:
- $f^+(x) = \max(f(x), 0)$ (the positive part)
- $f^-(x) = \max(-f(x), 0)$ (the negative part)

Note that $f = f^+ - f^-$ and both $f^+$ and $f^-$ are non-negative.

If at least one of $\int f^+ d\mu$ or $\int f^- d\mu$ is finite, we can define:
$$\int_X f   d\mu = \int_X f^+   d\mu - \int_X f^-   d\mu$$

If **both** are finite, we say $f$ is **integrable** (or $f \in L^1$, which is the space of integrable functions).

---