# From Lebesgue Integration to Stochastic Processes

## The Bridge: Why We Need Measure Theory for Stochastic Calculus

The journey from Lebesgue integration to the Ornstein-Uhlenbeck process reveals a beautiful progression:

```
Lebesgue Integration
    ↓
Probability Spaces (special measure spaces)
    ↓
Random Variables (measurable functions)
    ↓
Stochastic Processes (indexed families of RVs)
    ↓
Brownian Motion (continuous-time random walk)
    ↓
Stochastic Differential Equations
    ↓
Ornstein-Uhlenbeck Process (mean-reverting diffusion)
```

Let's walk through each step.

---

## Step 1: Probability Spaces as Measure Spaces

**Recall**: A measure space is $(X, \mathcal{F}, \mu)$ where:
- $X$ is a set
- $\mathcal{F}$ is a σ-algebra (collection of measurable sets)
- $\mu$ is a measure with $\mu(X)$ possibly infinite

**Probability space**: A special measure space $(\Omega, \mathcal{F}, \mathbb{P})$ where:
- $\Omega$ is the **sample space** (set of all possible outcomes)
- $\mathcal{F}$ is the **σ-algebra of events**
- $\mathbb{P}$ is a **probability measure** with $\mathbb{P}(\Omega) = 1$

**The connection**: Every probability measure is a finite measure! This means all the Lebesgue integration theory we developed applies immediately to probability.

### Example: Coin Flips

- $\Omega = \{\text{HH}, \text{HT}, \text{TH}, \text{TT}\}$ (flip twice)
- $\mathcal{F} = 2^\Omega$ (all subsets)
- $\mathbb{P}(\{\text{HH}\}) = 1/4$, etc.

This is a discrete probability space, but it's still a measure space!

---

## Step 2: Random Variables are Measurable Functions

**Recall**: A measurable function is $f: X \to \mathbb{R}$ such that $f^{-1}(B) \in \mathcal{F}$ for all Borel sets $B$.

**Random variable**: A measurable function $X: \Omega \to \mathbb{R}$ where:
- Input: outcome $\omega \in \Omega$ (random)
- Output: real number $X(\omega)$ (the "value" of the random quantity)

**Why measurability matters**: We need $\{X \in B\} = \{\omega : X(\omega) \in B\} \in \mathcal{F}$ to compute probabilities like $\mathbb{P}(X \in B)$.

### Example: Sum of Two Dice

- $\Omega = \{1, 2, 3, 4, 5, 6\} \times \{1, 2, 3, 4, 5, 6\}$
- $X(\omega_1, \omega_2) = \omega_1 + \omega_2$ (the sum)
- $\mathbb{P}(X = 7) = \mathbb{P}(\{(1,6), (2,5), (3,4), (4,3), (5,2), (6,1)\}) = 6/36$

$X$ is a random variable because it's a measurable function!

---

## Step 3: Expected Value is Lebesgue Integration

**The key insight**: For a random variable $X: \Omega \to \mathbb{R}$:

$$\mathbb{E}[X] = \int_\Omega X \, d\mathbb{P}$$

This is **exactly** the Lebesgue integral with respect to the probability measure $\mathbb{P}$!

### For Simple Random Variables

If $X = \sum_{i=1}^n a_i \mathbf{1}_{A_i}$ (simple function), then:

$$\mathbb{E}[X] = \sum_{i=1}^n a_i \mathbb{P}(A_i)$$

This is the "weighted sum" formula you learned in intro probability—it's just the Lebesgue integral of a simple function!

### For General Random Variables

If $X$ is non-negative:

$$\mathbb{E}[X] = \sup \left\{ \mathbb{E}[s] : s \text{ simple, } 0 \leq s \leq X \right\}$$

Exactly the definition of the Lebesgue integral for non-negative functions!

### Key Properties (from Lebesgue theory)

- **Linearity**: $\mathbb{E}[aX + bY] = a\mathbb{E}[X] + b\mathbb{E}[Y]$
- **Monotone Convergence**: If $X_n \uparrow X$, then $\mathbb{E}[X_n] \to \mathbb{E}[X]$
- **Dominated Convergence**: If $|X_n| \leq Y$ and $X_n \to X$, then $\mathbb{E}[X_n] \to \mathbb{E}[X]$

All of these come from Lebesgue integration theorems!

---

## Step 4: Stochastic Processes (Functions of Time and Randomness)

**Definition**: A stochastic process is a collection of random variables $\{X_t : t \in T\}$ indexed by time $t$.

**Two ways to view it**:
1. **Fix $\omega$**: $t \mapsto X_t(\omega)$ is a **sample path** (one realization)
2. **Fix $t$**: $\omega \mapsto X_t(\omega)$ is a **random variable** at time $t$

```
Sample paths (different ω):
   X_t(ω)
     |     ω₁: ___/\___/\____
     |    ω₂: __/\__/\/\___
     |   ω₃: ___/\/\__/\__
     |__________________________t
```

**Measurability requirements**:
- For each $t$, $X_t$ must be a measurable function (random variable)
- We often require the whole path $t \mapsto X_t(\omega)$ to be measurable (technical condition)

---

## Step 5: Brownian Motion (The Fundamental Building Block)

**Brownian motion** $B_t$ is a continuous-time stochastic process with:
1. $B_0 = 0$
2. **Independent increments**: $B_{t+s} - B_s$ is independent of $(B_u : u \leq s)$
3. **Gaussian increments**: $B_t - B_s \sim \mathcal{N}(0, t-s)$
4. **Continuous paths**: $t \mapsto B_t(\omega)$ is continuous for (almost) every $\omega$

> **Notation clarification**: Here, $B_t$ is a **random variable** (a measurable function $\Omega \to \mathbb{R}$). For each fixed time $t$, $B_t$ maps outcomes $\omega \in \Omega$ to real numbers. When we write $dB_t$ in the next section, it's **not** a probability measure $d\mathbb{P}$—it's an infinitesimal increment of this random process. Think of $dB_t$ as shorthand for "a tiny random change" $B_{t+dt} - B_t$.

### Intuition: A Continuous Random Walk

Think of a drunk person walking along a line:
- Each tiny time step $dt$, they move randomly: $dB_t \sim \mathcal{N}(0, dt)$
- Over time $[0, t]$, these infinitesimal steps accumulate to $B_t \sim \mathcal{N}(0, t)$

```
   B_t
    |      ___
    |   __/   \__    ← one sample path
    |  /         \__/
    | /
    |/__________________t
```

**Why we need measure theory**:
- Brownian paths are **continuous but nowhere differentiable** (pathological!)
- Riemann integration can't handle $\int_0^t f(B_s) \, ds$ rigorously
- We need Lebesgue integration to define path integrals

---

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

**Problem**: $dB_s$ is not a function—it's infinitesimal white noise!

**Solution**: Define it as a limit of Riemann-like sums:

$\int_0^t f(s) \, dB_s = \lim_{n \to \infty} \sum_{i=0}^{n-1} f(t_i) (B_{t_{i+1}} - B_{t_i})$

where $0 = t_0 < t_1 < \cdots < t_n = t$ is a partition.

**Key differences from Lebesgue**:
- The integrand $f$ can depend on the Brownian path itself!
- The limit is taken in $L^2(\mathbb{P})$ (mean-square convergence)
- Requires adaptedness: $f(s)$ can only depend on $(B_u : u \leq s)$ (no peeking into the future!)

**Properties** (from measure theory):
- $\mathbb{E}\left[\int_0^t f(s) \, dB_s\right] = 0$ (martingale property)
- **Itô isometry**: $\mathbb{E}\left[\left(\int_0^t f(s) \, dB_s\right)^2\right] = \mathbb{E}\left[\int_0^t f(s)^2 \, ds\right]$

The second property is pure Lebesgue integration on the right side!

---

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

## Step 7: Stochastic Differential Equations (SDEs)

An SDE is an equation of the form:

$$dX_t = \mu(X_t, t) \, dt + \sigma(X_t, t) \, dB_t$$

**Interpretation**:
- $\mu(X_t, t) \, dt$: deterministic **drift** (Lebesgue integral part)
- $\sigma(X_t, t) \, dB_t$: random **diffusion** (Itô integral part)

**Integral form**:

$$X_t = X_0 + \int_0^t \mu(X_s, s) \, ds + \int_0^t \sigma(X_s, s) \, dB_s$$

The first integral is a standard Lebesgue integral, the second is an Itô integral!

---

## Step 8: The Ornstein-Uhlenbeck Process

**Definition**: The OU process satisfies:

$$dX_t = -\theta X_t \, dt + \sigma \, dB_t$$

where $\theta > 0$ is the **mean reversion speed** and $\sigma > 0$ is the **volatility**.

**Integral form**:

$$X_t = X_0 + \int_0^t (-\theta X_s) \, ds + \int_0^t \sigma \, dB_s$$

### What Does It Model?

1. **Mean reversion**: The term $-\theta X_t$ pulls the process back toward $0$
   - If $X_t > 0$, the drift is negative (pulls down)
   - If $X_t < 0$, the drift is positive (pulls up)

2. **Random noise**: The term $\sigma \, dB_t$ adds Brownian fluctuations

```
   X_t
    |    ___      ___
    |   /   \    /   \     ← oscillates around 0
    |__/     \__/     \____
    | /               \
    |/___________________t
         mean = 0
```

### Applications

- **Finance**: Interest rate models (Vasicek model)
- **Physics**: Velocity of a particle in a viscous fluid (original Langevin equation)
- **Neuroscience**: Membrane potential of neurons
- **Machine learning**: Continuous-time gradient descent with noise

### Explicit Solution (using Itô calculus)

The solution is:

$$X_t = e^{-\theta t} X_0 + \sigma \int_0^t e^{-\theta(t-s)} \, dB_s$$

**Key properties** (from measure theory):
- $\mathbb{E}[X_t] = e^{-\theta t} X_0$ (exponential decay to 0)
- $\text{Var}(X_t) = \frac{\sigma^2}{2\theta}(1 - e^{-2\theta t}) \to \frac{\sigma^2}{2\theta}$ as $t \to \infty$
- **Stationary distribution**: $X_\infty \sim \mathcal{N}(0, \sigma^2/(2\theta))$

All of these are computed using Lebesgue integration and Itô isometry!

---

## The Full Circle: Why Lebesgue Integration is Essential

Let's trace how Lebesgue integration appears at each step:

1. **Probability spaces**: $\mathbb{P}$ is a measure, so we integrate w.r.t. $\mathbb{P}$

2. **Random variables**: Measurable functions, integrable w.r.t. $\mathbb{P}$

3. **Expected values**: $\mathbb{E}[X] = \int_\Omega X \, d\mathbb{P}$ (Lebesgue integral)

4. **Variance**: $\text{Var}(X) = \mathbb{E}[X^2] - (\mathbb{E}[X])^2$ (two Lebesgue integrals)

5. **Path integrals**: $\int_0^t f(X_s) \, ds$ (Lebesgue integral over time)

6. **Itô isometry**: $\mathbb{E}\left[\left(\int_0^t f(s) \, dB_s\right)^2\right] = \int_0^t \mathbb{E}[f(s)^2] \, ds$ (Lebesgue integral)

7. **Computing means/variances of SDEs**: All require Lebesgue integration

8. **Stationary distributions**: Involve integrating w.r.t. the invariant measure

### Why Riemann Integration Fails

- **Brownian paths are nowhere differentiable**: Can't use Riemann sums reliably
- **Sets of measure zero matter**: The rationals (measure 0) vs irrationals (measure 1) distinction is crucial in probability
- **Limit theorems fail**: Dominated/Monotone Convergence Theorem don't hold for Riemann integrals
- **General measure spaces**: Probability theory needs abstract spaces (path space, function spaces), not just $\mathbb{R}^n$

---

## The Big Picture

```
Simple Functions
    ↓  (approximate from below)
Lebesgue Integral for Non-negative Functions
    ↓  (extend to signed functions)
General Lebesgue Integration
    ↓  (specialize: μ → ℙ, measure 1)
Probability Theory (Expected Values)
    ↓  (index by time)
Stochastic Processes
    ↓  (continuous-time limit)
Brownian Motion
    ↓  (integrate w.r.t. dB)
Itô Calculus
    ↓  (solve differential equations)
Stochastic Differential Equations
    ↓  (specific example)
Ornstein-Uhlenbeck Process
```

**The foundation**: Everything rests on the ability to integrate measurable functions w.r.t. measures—exactly what Lebesgue gave us!

---

## Key Takeaways

1. **Probability is applied measure theory**: Every probability concept has a measure-theoretic foundation

2. **Random variables are measurable functions**: All the function properties (continuity, limits, convergence) carry over

3. **Expected value is integration**: $\mathbb{E}[\cdot]$ is just $\int \cdot \, d\mathbb{P}$

4. **Stochastic processes need Lebesgue**: Pathological behavior (nowhere differentiable paths) requires the full power of Lebesgue integration

5. **OU process is the payoff**: A concrete, useful model built on the entire tower of abstraction

The Ornstein-Uhlenbeck process isn't just a random formula—it's the culmination of a rigorous mathematical framework that starts with measuring sets and integrating simple functions!