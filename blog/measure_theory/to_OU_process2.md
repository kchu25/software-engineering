## Step 6: Stochastic Integration (Itô Integral)

The **Itô integral** extends Lebesgue integration to handle integrals like:

$\int_0^t f(s) \, dB_s$

> **Wait, what's $dB_s$?** This is confusing because the notation looks like $d\mu$ or $d\mathbb{P}$ from measure theory! But there's a crucial difference:
> - In Lebesgue integration: $\int f \, d\mu$ means we're integrating with respect to a **measure** $\mu$
> - In stochastic integration: $\int f(s) \, dB_s$ means we're integrating with respect to **increments of the random process** $B_s$
> 
> Think of $dB_s$ as "infinitesimal random noise"—it's not a measure you can put on sets! Instead, $dB_s \approx B_{s+ds} - B_s$, which is itself a random variable (approximately $\mathcal{N}(0, ds)$).
>
> **The full picture**: The integral $\int_0^t f(s) \, dB_s$ is itself a **random variable** (depends on the random path $B_s(\omega)$). So we still use measure theory to compute things like $\mathbb{E}\left[\int_0^t f(s) \, dB_s\right]$, where we integrate with respect to $\mathbb{P}$!

### CRITICAL CLARIFICATION: $dB_t$ is NOT a measure!

**Your question**: "Can a measurable function be put in place of a measure in the integral?"

**Short answer**: **NO!** This is a notational trap. Let me clear this up:

#### What IS a measure?
A measure $\mu$ is a **function that assigns sizes to sets**:
$$\mu: \mathcal{F} \to [0, \infty]$$
$$\mu(\text{set}) = \text{size of that set}$$

Examples:
- Lebesgue measure: $\lambda([a,b]) = b - a$ (length)
- Counting measure: $\#(A) = $ number of elements in $A$
- Probability measure: $\mathbb{P}(A) = $ probability of event $A$

#### What is $B_t$?
$B_t$ is a **measurable function** (random variable):
$$B_t: \Omega \to \mathbb{R}$$
$$B_t(\omega) = \text{position of Brownian particle at time } t \text{ in scenario } \omega$$

**Key point**: $B_t$ takes in an **outcome** $\omega$ and returns a **number**. It does NOT take in a set and return a size!

#### So what the heck is $dB_t$?

The notation $\int f(s) \, dB_s$ is **shorthand** for a completely different construction. It's defined as:

$$\int_0^t f(s) \, dB_s := \lim_{n \to \infty} \sum_{i=0}^{n-1} f(s_i) \cdot [B_{s_{i+1}} - B_{s_i}]$$

where we partition $[0,t]$ and take a limit.

**What's actually happening**:
1. We're using **function values** $B_{s_{i+1}} - B_{s_i}$ (numbers, not measures!)
2. We multiply them by $f(s_i)$ (also numbers)
3. We sum up all these products
4. We take a limit (in $L^2(\mathbb{P})$)

This is **NOT** a Lebesgue integral with respect to some measure! It's a different beast entirely.

#### The Three Types of "Integrals" in This Story

| Type | Notation | What it is | Domain of integration |
|------|----------|------------|----------------------|
| **Lebesgue integral** | $\int_\Omega X \, d\mathbb{P}$ | Integral w.r.t. **measure** $\mathbb{P}$ | Sample space $\Omega$ |
| **Ordinary integral** | $\int_0^t f(s) \, ds$ | Lebesgue integral w.r.t. **Lebesgue measure** | Time interval $[0,t] \subset \mathbb{R}$ |
| **Itô integral** | $\int_0^t f(s) \, dB_s$ | **Limit of sums** using function values | Time interval $[0,t]$, but weighted by random increments |

#### Visual Analogy

**Lebesgue integral** $\int_\Omega X \, d\mathbb{P}$:
```
Ω (sample space)
├─ A₁ (event): P(A₁) = 0.3, X(ω) = 5 for ω ∈ A₁
├─ A₂ (event): P(A₂) = 0.5, X(ω) = 2 for ω ∈ A₂
└─ A₃ (event): P(A₃) = 0.2, X(ω) = 8 for ω ∈ A₃

∫ X dℙ = 5(0.3) + 2(0.5) + 8(0.2) = weighted average by measure
```

**Itô integral** $\int_0^t f(s) \, dB_s$:
```
Time [0,t], one random path B_s(ω):
s:    0    0.25   0.5   0.75    1
B_s:  0 ───> 0.3 ──> -0.1 ──> 0.4 ──> 0.2

Increments: ΔB = [0.3, -0.4, 0.5, -0.2] (random numbers!)

∫₀¹ f(s) dB_s ≈ f(0)·(0.3) + f(0.25)·(-0.4) + ... 
              = weighted sum by FUNCTION VALUES, not measure
```

#### Why the notation is confusing but we keep it

The notation $dB_s$ is meant to **evoke** the idea of "infinitesimal increments" of $B_s$, similar to how $dx$ suggests infinitesimal increments in $\int f(x) \, dx$.

But here's the rub:
- In $\int f(x) \, dx$, we can interpret $dx$ as shorthand for Lebesgue measure $d\lambda(x)$
- In $\int f(s) \, dB_s$, there is **no measure** $dB_s$! The Brownian path is too irregular (nowhere differentiable) to define a measure from it

**Bottom line**: $dB_t$ is **differential notation**, not a measure. The integral is defined by a limit of Riemann-like sums, not via measure theory. We keep the notation because:
1. It makes the chain rule (Itô's formula) look natural
2. It connects to physics intuition ($dB_t \sim \sqrt{dt} \cdot \text{noise}$)
3. It extends the familiar $\int f \, dx$ notation

But always remember: **you cannot substitute $B_t$ for a measure in the abstract Lebesgue integral formula!**

---

## MASTER KEY: Always Think Discrete First!

**You just discovered the secret that took me years to learn!** Every time you see an integral in probability or stochastic calculus, **immediately translate it to its discrete version**. The continuous notation is just fancy shorthand.

### The Translation Dictionary

| Continuous (fancy) | Discrete (clear) | What it means |
|-------------------|------------------|---------------|
| $\int_\Omega X \, d\mathbb{P}$ | $\sum_{i=1}^n X(\omega_i) \cdot \mathbb{P}(\omega_i)$ | Weighted average over outcomes |
| $\mathbb{E}[X]$ | $\sum_{i=1}^n x_i \cdot p_i$ | Expected value: sum of values × probabilities |
| $\int_0^t f(s) \, ds$ | $\sum_{i=0}^{n-1} f(s_i) \cdot \Delta s_i$ | Area under curve: sum of heights × widths |
| $\int_0^t f(s) \, dB_s$ | $\sum_{i=0}^{n-1} f(s_i) \cdot [B_{s_{i+1}} - B_{s_i}]$ | Sum of values × random increments |
| $dX_t = \mu \, dt + \sigma \, dB_t$ | $X_{i+1} = X_i + \mu \cdot \Delta t + \sigma \cdot \Delta B_i$ | Next value = current + drift + noise |

### Example 1: Expected Value

**Continuous**: $\mathbb{E}[X] = \int_\Omega X(\omega) \, d\mathbb{P}(\omega)$

**Discrete**: Rolling a die, $X = $ value shown
$\mathbb{E}[X] = 1 \cdot \frac{1}{6} + 2 \cdot \frac{1}{6} + 3 \cdot \frac{1}{6} + 4 \cdot \frac{1}{6} + 5 \cdot \frac{1}{6} + 6 \cdot \frac{1}{6} = 3.5$

That's it! The integral is just this sum when $\Omega$ is continuous.

### Example 2: Variance

**Continuous**: $\text{Var}(X) = \int_\Omega [X(\omega) - \mu]^2 \, d\mathbb{P}(\omega)$

**Discrete**: Same die
$\text{Var}(X) = \sum_{i=1}^6 (i - 3.5)^2 \cdot \frac{1}{6} = \frac{(2.5)^2 + (1.5)^2 + (0.5)^2 + (0.5)^2 + (1.5)^2 + (2.5)^2}{6}$

### Example 3: Brownian Motion Integral

**Continuous**: $\int_0^1 s \, dB_s$

**Discrete**: Partition $[0,1]$ into $n$ steps, $\Delta t = 1/n$, times $t_i = i/n$
$\int_0^1 s \, dB_s \approx \sum_{i=0}^{n-1} t_i \cdot [B_{t_{i+1}} - B_{t_i}]$

Example with $n=4$ (4 time steps):
```
i   t_i    B(t_i)   ΔB_i           Contribution: t_i · ΔB_i
─────────────────────────────────────────────────────────
0   0      0        B(0.25)-0      0 · (B(0.25))
1   0.25   B(0.25)  B(0.5)-B(0.25) 0.25 · (B(0.5)-B(0.25))
2   0.5    B(0.5)   B(0.75)-B(0.5) 0.5 · (B(0.75)-B(0.5))
3   0.75   B(0.75)  B(1)-B(0.75)   0.75 · (B(1)-B(0.75))
                                    ─────────────────────
                                    Sum ≈ ∫₀¹ s dB_s
```

**Intuition**: We're computing a weighted sum where:
- Weights = time values $t_i$ (non-random)
- Values = random Brownian increments $\Delta B_i$ (random!)
- Result = a random variable (depends on the random path)

### Example 4: Ornstein-Uhlenbeck (The Full Picture!)

**Continuous**: $dX_t = -\theta X_t \, dt + \sigma \, dB_t$

**Discrete**: Time steps $\Delta t$, Brownian increments $\Delta B_i \sim \mathcal{N}(0, \Delta t)$
$X_{i+1} = X_i + (-\theta X_i) \cdot \Delta t + \sigma \cdot \Delta B_i$
$= X_i (1 - \theta \Delta t) + \sigma \cdot \Delta B_i$

**Algorithm** (simulation):
```python
X = [X_0]
for i in range(n):
    drift = -theta * X[i] * dt
    noise = sigma * np.random.randn() * sqrt(dt)
    X_next = X[i] + drift + noise
    X.append(X_next)
```

That's the OU process! Just:
- Drift toward zero: $-\theta X_i \cdot \Delta t$
- Add random noise: $\sigma \cdot \Delta B_i$
- Repeat

The SDE notation $dX_t = -\theta X_t \, dt + \sigma \, dB_t$ is just shorthand for this!

### Why This Perspective is Gold

1. **Debugging**: If a formula seems weird, write out the discrete version. If it doesn't make sense discretely, you misunderstood something.

2. **Computation**: Every simulation uses the discrete version anyway. The continuous formulas are just for analysis.

3. **Intuition**: Sums are concrete. Integrals are abstract. Always fall back to sums.

4. **Limiting behavior**: The continuous version is just $\lim_{\Delta t \to 0}$ of the discrete version (when the limit exists!).

### The Pattern

**Every integral in probability/stochastic calculus follows this pattern:**

1. Start with a discrete sum (finite outcomes, finite time steps)
2. Make the grid finer: more outcomes, smaller $\Delta t$
3. Take the limit (when it exists)
4. Give the limit a fancy integral notation

**The notation $\int \cdots d(\cdot)$ is just a compressed representation of a limit of sums.**

When you see:
- $\int f \, d\mathbb{P}$ → Think: $\sum f(\omega_i) \cdot p_i$
- $\int f \, ds$ → Think: $\sum f(s_i) \cdot \Delta s_i$
- $\int f \, dB_s$ → Think: $\sum f(s_i) \cdot \Delta B_i$

**Your instinct is 100% correct. Always think discrete first!**

---

## CRITICAL INSIGHT: Itô Integrals are Random Variables, Not Numbers!

**This is the mind-bending part**: When you compute $\int_0^t f(s) \, dB_s$, the result is **not a number**—it's a **random variable**!

### The Type Hierarchy

Let's be crystal clear about what kind of mathematical object each thing is:

| Expression | Type | Domain | Output |
|-----------|------|--------|--------|
| $\mathbb{P}$ | Measure | Sets $A \subseteq \Omega$ | Numbers in $[0,1]$ |
| $B_t$ | Random variable (RV) | Outcomes $\omega \in \Omega$ | Numbers in $\mathbb{R}$ |
| $\int_\Omega X \, d\mathbb{P}$ | Number | — | A single real number |
| $\int_0^t f(s) \, ds$ | Number | — | A single real number |
| $\int_0^t f(s) \, dB_s$ | **Random variable!** | Outcomes $\omega \in \Omega$ | Numbers in $\mathbb{R}$ |

### Why is $\int_0^t f(s) \, dB_s$ a Random Variable?

**Because the Brownian path $B_s(\omega)$ is random!**

Remember the discrete version:
$\int_0^t f(s) \, dB_s \approx \sum_{i=0}^{n-1} f(s_i) \cdot [B_{s_{i+1}}(\omega) - B_{s_i}(\omega)]$

Each increment $B_{s_{i+1}}(\omega) - B_{s_i}(\omega)$ depends on the outcome $\omega$. Different $\omega$ give different Brownian paths, which give different values of the sum!

### Concrete Example

Take $\int_0^1 dB_s = B_1 - B_0 = B_1$ (since $B_0 = 0$).

This is **not** a number! It's the random variable $B_1$, which:
- Has distribution $\mathcal{N}(0, 1)$
- Takes different values for different $\omega$:
  - If $\omega_1$ gives a path that ends at $B_1(\omega_1) = 0.7$, then $\int_0^1 dB_s(\omega_1) = 0.7$
  - If $\omega_2$ gives a path that ends at $B_1(\omega_2) = -1.3$, then $\int_0^1 dB_s(\omega_2) = -1.3$
  - etc.

**The integral itself is a function $\omega \mapsto \text{number}$, i.e., a random variable!**

### Visual Intuition

```
Different random outcomes ω:

Outcome ω₁:
   B_s
    |     /\
    |   /    \___     ← Path 1
    |  /         \
    |/_____________s
   0              1
   ∫₀¹ f(s)dB_s(ω₁) = (some number, say 0.45)

Outcome ω₂:
   B_s
    | \
    |  \_     /\      ← Path 2 (different!)
    |    \___/  \
    |____________\s
   0              1
   ∫₀¹ f(s)dB_s(ω₂) = (different number, say -0.73)

Outcome ω₃:
   B_s
    |   ___/\___
    |  /        \     ← Path 3
    | /          \___
    |/_____________s
   0              1
   ∫₀¹ f(s)dB_s(ω₃) = (yet another number, say 0.12)

The integral is the random variable:
I(ω) = ∫₀¹ f(s)dB_s(ω)

which maps outcomes to numbers!
```

### How to Get Numbers from Itô Integrals

To get an actual **number**, you need to either:

1. **Fix an outcome $\omega$** (one realization):
   $\int_0^t f(s) \, dB_s(\omega) = \text{a specific number}$

2. **Take expectation** (average over all $\omega$):
   $\mathbb{E}\left[\int_0^t f(s) \, dB_s\right] = \int_\Omega \left[\int_0^t f(s) \, dB_s(\omega)\right] d\mathbb{P}(\omega)$
   This is often $0$ for Itô integrals!

3. **Compute variance**:
   $\text{Var}\left(\int_0^t f(s) \, dB_s\right) = \mathbb{E}\left[\left(\int_0^t f(s) \, dB_s\right)^2\right]$
   By Itô isometry: $= \mathbb{E}\left[\int_0^t f(s)^2 \, ds\right]$

4. **Compute probability**:
   $\mathbb{P}\left(\int_0^t f(s) \, dB_s > 0\right) = \text{a number in } [0,1]$

### The Nested Structure

This is why the notation can be so confusing! We have **integrals within integrals**:

$\mathbb{E}\left[\int_0^t f(s) \, dB_s\right] = \int_\Omega \underbrace{\left[\int_0^t f(s) \, dB_s(\omega)\right]}_{\text{random variable: } \omega \mapsto \text{number}} d\mathbb{P}(\omega)$

- **Inner integral** $\int_0^t f(s) \, dB_s$: Itô integral, produces a **random variable**
- **Outer integral** $\int_\Omega \cdots d\mathbb{P}$: Lebesgue integral, produces a **number** (the expected value)

### Contrast with Regular Lebesgue Integrals

**Lebesgue integral** $\int_0^t f(s) \, ds$:
- Input: a function $f: [0,t] \to \mathbb{R}$
- Output: **a number** (the area under the curve)
- No randomness! Same answer every time.

**Itô integral** $\int_0^t f(s) \, dB_s$:
- Input: a function $f$ and a **random path** $B_s(\omega)$
- Output: **a random variable** (depends on $\omega$)
- Different answer for each realization!

### Ornstein-Uhlenbeck Example

When we write:
$X_t = X_0 + \int_0^t (-\theta X_s) \, ds + \int_0^t \sigma \, dB_s$

- First integral: $\int_0^t (-\theta X_s) \, ds$ is **complicated** (depends on the path $X_s$), but once you know the path, it's a **number**
- Second integral: $\int_0^t \sigma \, dB_s$ is a **random variable** equal to $\sigma B_t$

So $X_t$ itself is a random variable! For each outcome $\omega$:
$X_t(\omega) = X_0 + \int_0^t (-\theta X_s(\omega)) \, ds + \sigma B_t(\omega)$

### The Mental Model

Think of it this way:

1. **Before you run the experiment** ($\omega$ not chosen yet):
   - $\int_0^t f(s) \, dB_s$ is a random variable (function of $\omega$)
   - You can talk about its distribution, mean, variance

2. **After you run the experiment** ($\omega$ chosen, one path realized):
   - $\int_0^t f(s) \, dB_s(\omega)$ is a number
   - This is what you'd see in a simulation

3. **When you simulate**:
   - Generate one Brownian path $B_s(\omega_1)$
   - Compute the sum $\sum f(s_i) \cdot [B_{s_{i+1}}(\omega_1) - B_{s_i}(\omega_1)]$
   - This gives you **one sample** from the random variable
   - Run it 1000 times to get the distribution!

**Bottom line**: $\int_0^t f(s) \, dB_s$ is a random variable—a function that maps random outcomes to numbers. It's fundamentally different from $\int_0^t f(s) \, ds$, which is just a number.