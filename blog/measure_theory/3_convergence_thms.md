@def title = "Measure Theory 3: convergence theorems"
@def published = "5 October 2025"
@def tags = ["measure-theory"]


## 8. The Big Three: Convergence Theorems

Alright, here's where measure theory really shines. These convergence theorems let you interchange limits and integrals, which is something you can't always do with Riemann integration. These are absolutely essential for analysis, probability, and optimization.

### Monotone Convergence Theorem (MCT)

**Statement**: If $0 \leq f_1 \leq f_2 \leq \cdots$ are measurable functions and $f_n \to f$ pointwise, then:
$$\int f \, d\mu = \lim_{n \to \infty} \int f_n \, d\mu$$

**Translation**: For increasing sequences of non-negative functions, the limit of integrals equals the integral of the limit. You can pass the limit through the integral sign!

**Why it's awesome**: You don't need any dominating function or boundedness condition. Just monotonicity and non-negativity.

**Common use case**: Proving that $\sum_{n=1}^{\infty} \int f_n = \int \sum_{n=1}^{\infty} f_n$ for non-negative functions $f_n$. You let the partial sums be your increasing sequence!

### Fatou's Lemma

**Statement**: For any sequence of non-negative measurable functions $f_n \geq 0$:
$$\int \liminf_{n \to \infty} f_n \, d\mu \leq \liminf_{n \to \infty} \int f_n \, d\mu$$

**Translation**: The integral of the limit inferior is at most the limit inferior of the integrals.

**Mnemonic**: "Integral of liminf ≤ liminf of integrals"

**When to use it**: This is your fallback when you can't use MCT (because the sequence isn't monotone) but you still need some inequality to work with. It's a "one-way" inequality that often comes in handy.

### Dominated Convergence Theorem (DCT)

This is the workhorse of measure theory. You'll use this one constantly.

**Statement**: Suppose $f_n$ are measurable functions with $f_n \to f$ pointwise. If there exists an integrable function $g$ such that $|f_n(x)| \leq g(x)$ for all $n$ and all $x$ (the **domination condition**), then:
$$\lim_{n \to \infty} \int f_n \, d\mu = \int f \, d\mu$$

Moreover, $\int |f_n - f| \, d\mu \to 0$ (which means convergence in the $L^1$ norm).

**What's really going on**: If your sequence of functions is "controlled" by an integrable function and converges pointwise, then:
1. The limit is integrable
2. You can interchange the limit and the integral
3. The functions actually converge in $L^1$ norm (not just pointwise)

**Why "dominated"?** The dominating function $g$ prevents "mass from escaping to infinity." It keeps everything bounded in a way that ensures the convergence is well-behaved.

**Optimization analogy**: Think of gradient descent with a Lipschitz constraint. The Lipschitz constant (like a dominating function) ensures gradients don't blow up, which lets you prove convergence. Same idea here!

### When to Use Which Theorem

Here's a quick decision guide:

| Theorem | What You Need | When to Use It |
|---------|--------------|----------------|
| **MCT** | $0 \leq f_1 \leq f_2 \leq \cdots$ | Monotone increasing sequences, series of non-negative terms |
| **Fatou** | $f_n \geq 0$ | When you only need a one-sided inequality |
| **DCT** | $\|f_n\| \leq g$, $g$ integrable | Most general case, but you need domination |

---

## 9. DCT in Action: Classic Applications

Let me show you where DCT really shines.

### Application 1: Differentiating Under the Integral Sign

Suppose you have $f(x, t)$ that's integrable in $x$ for each $t$, and $\frac{\partial f}{\partial t}$ exists and is dominated by an integrable function $g(x)$:
$$\left|\frac{\partial f}{\partial t}(x, t)\right| \leq g(x)$$

Then you can differentiate under the integral:
$$\frac{d}{dt} \int f(x, t) \, dx = \int \frac{\partial f}{\partial t}(x, t) \, dx$$

**Proof sketch**: Apply DCT to the difference quotient $\frac{f(x, t+h) - f(x, t)}{h}$ as $h \to 0$.

This is huge in optimization and physics!

### Application 2: Interchanging Limit and Integral

Want to show that $\lim_{n \to \infty} \int f_n = \int \lim_{n \to \infty} f_n$?

Here's your checklist:
1. ✓ Check pointwise convergence: $f_n(x) \to f(x)$
2. ✓ Find a dominating function: $|f_n(x)| \leq g(x)$ with $\int g < \infty$
3. ✓ Apply DCT

**Classic mistake**: Forgetting to verify domination! Without it, mass can "escape" and the theorem fails.

**Counterexample**: Consider $f_n(x) = n \cdot \mathbf{1}_{[0, 1/n]}(x)$ on $[0, 1]$.
- $f_n(x) \to 0$ pointwise for all $x > 0$ ✓
- But $\int_0^1 f_n \, dx = 1$ for all $n$ ✗
- So $\lim \int f_n = 1 \neq 0 = \int \lim f_n$

What went wrong? There's no integrable dominating function! The "mass" is concentrating near zero as $n$ increases, essentially escaping our control.

### Application 3: Series and Integration

For non-negative functions $f_n$, MCT gives you:
$$\int \sum_{n=1}^{\infty} f_n = \sum_{n=1}^{\infty} \int f_n$$

For general $f_n$, if $\sum_{n=1}^{\infty} \int |f_n| < \infty$, then you can use DCT with $g = \sum |f_n|$ to get:
$$\int \sum_{n=1}^{\infty} f_n = \sum_{n=1}^{\infty} \int f_n$$

This is incredibly useful when working with infinite series!

---

## 10. How DCT Actually Works (Proof Sketch)

Let me show you the key idea behind DCT without getting too bogged down in details.

**Given**: $f_n \to f$ pointwise, $|f_n| \leq g$, $\int g < \infty$.

**Goal**: Show $\int |f_n - f| \to 0$.

**Here's the clever trick**:

1. Since $f_n \to f$ pointwise, we have $|f_n - f| \to 0$ pointwise.

2. By the triangle inequality: $|f_n - f| \leq |f_n| + |f| \leq 2g$ (using domination).

3. Now apply Fatou's Lemma to the non-negative functions $2g - |f_n - f| \geq 0$:
   $$\int \liminf (2g - |f_n - f|) \leq \liminf \int (2g - |f_n - f|)$$

4. The left side becomes $\int 2g$ (since $|f_n - f| \to 0$).

5. The right side is $\int 2g - \limsup \int |f_n - f|$.

6. Therefore: $\int 2g \leq \int 2g - \limsup \int |f_n - f|$

7. Which means: $\limsup \int |f_n - f| \leq 0$

8. Since $\int |f_n - f| \geq 0$ always, we get $\int |f_n - f| \to 0$ ✓

**The key insight**: Fatou's Lemma provides the technical machinery, but the domination condition $|f_n| \leq g$ is what makes everything work. Without it, step 2 fails and the whole proof collapses!

---

## 11. Connecting to Your Background

### Discrete Math Connection

Here's something cool: on a countable set with counting measure, Lebesgue integration is literally just summation:
$$\int f \, d\mu = \sum_{x} f(x)$$

All the convergence theorems become theorems about interchanging limits and sums:
- **MCT**: $\sum \lim f_n = \lim \sum f_n$ for monotone $f_n \geq 0$
- **DCT**: $\sum \lim f_n = \lim \sum f_n$ if $|f_n| \leq g$ with $\sum g < \infty$

So all the measure theory you're learning has direct discrete analogs!

### Optimization Connection

**Gradient descent convergence**: If $\nabla f_n \to \nabla f$ pointwise and the gradients are uniformly bounded (dominated), DCT guarantees that:
$$\lim_{n \to \infty} \int \nabla f_n = \int \nabla f$$

The integrated cost function behaves nicely!

**Expectations in stochastic optimization**: Computing $\mathbb{E}[f(X)]$ is just integration with respect to a probability measure. DCT justifies interchanging limits and expectations when you have uniform integrability (which is basically domination).

**Variational problems**: Many problems in calculus of variations require you to show:
$$\frac{d}{dt} \int L(x, u(x, t), u'(x, t)) \, dx = \int \frac{\partial L}{\partial t} \, dx$$

This uses DCT (or closely related results) to differentiate under the integral sign.

---

## Summary: The Big Picture

Here's how everything fits together:

```
Measurable spaces (X, 𝓕)
         ↓
    Measures μ
         ↓
Measurable functions f
         ↓
  Simple functions
  (building blocks)
         ↓
Integration via approximation
         ↓
  Convergence theorems
   MCT → Fatou → DCT
```

**Key takeaways**:

1. **Simple functions** are the building blocks - integration is defined naturally on them as a weighted sum

2. **Lebesgue integration** extends to general functions by approximating from below with simple functions

3. **Convergence theorems** are what make measure theory powerful - they let you interchange limits and integrals under appropriate conditions

4. **DCT is your best friend** - whenever you have domination and pointwise convergence, you can freely interchange limits and integrals

5. **The framework is universal** - it works for discrete sums, continuous integrals, and everything in between!

The real power of measure theory is that it provides a rigorous, unified framework for integration that handles all the pathological cases that Riemann integration chokes on, while giving you powerful convergence theorems that are absolutely essential in analysis, probability, and optimization.