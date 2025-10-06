@def title = "Measure Theory 1: from sigma algebra to measurable functions"
@def published = "5 October 2025"
@def tags = ["measure-theory"]


# Intuitive Guide to Measure Theory: From Simple Functions to DCT

## Why Should You Care About Measure Theory?

Here's the big picture: measure theory gives us a rigorous way to answer "How big is this set?" It generalizes length, area, and volume to much weirder sets, and lets us integrate functions that Riemann integration just can't handle.

**Here's the key insight** (especially relevant with your CS background): Riemann integration is like approximating a function with a fixed grid - think of it as using a fixed time-step discretization. Lebesgue integration is adaptive - it groups together all the points where the function takes similar values, no matter where those points are located. This turns out to be way more powerful!

---

## 1. Sigma-Algebras: Deciding What You Can Measure

### The Basic Idea
Before we can measure anything, we need to decide *which* sets we're allowed to measure. That's what a σ-algebra does.

A **σ-algebra** $\mathcal{F}$ on a set $X$ is just a collection of subsets of $X$ that plays nicely with the operations we care about:

1. $X \in \mathcal{F}$ - the whole space is in there
2. If $A \in \mathcal{F}$, then $A^c \in \mathcal{F}$ - complements are in there
3. If $A_1, A_2, \ldots \in \mathcal{F}$, then $\bigcup_{i=1}^{\infty} A_i \in \mathcal{F}$ - countable unions are in there

**Why these rules?** Well, if you can measure a set $A$, you should be able to measure "everything not in $A$" (that's the complement). And if you can measure a bunch of sets individually, you should be able to measure their union. Makes sense, right?


### Definitions: Measurable Set and Borel Set

**Measurable set:**
> A **measurable set** is any set that belongs to your chosen σ-algebra $\mathcal{F}$. In other words, if $A \in \mathcal{F}$, then $A$ is called measurable. The collection of all measurable sets depends on which σ-algebra you are working with.

**Borel set:**
> A **Borel set** is any set that belongs to the Borel σ-algebra $\mathcal{B}(\mathbb{R})$. The Borel σ-algebra is the smallest σ-algebra containing all open intervals in $\mathbb{R}$. Borel sets include all open sets, all closed sets, and any set you can build from open intervals using countable unions, countable intersections, and complements.

#### Note: What Does "Smallest σ-algebra" Mean?

##### Why the Borel σ-algebra Stands Out

##### Examples of Larger σ-algebras Containing All Open Intervals


##### What Does "Smallest" Mean? (Order on σ-algebras)

The word "smallest" here refers to inclusion: we can compare σ-algebras by set containment. If $\mathcal{A}$ and $\mathcal{B}$ are σ-algebras on the same set $X$, we say $\mathcal{A}$ is smaller than $\mathcal{B}$ if $\mathcal{A} \subseteq \mathcal{B}$ (that is, every set in $\mathcal{A}$ is also in $\mathcal{B}$).

So, the "smallest σ-algebra containing a collection of sets" is the one that is contained in every other σ-algebra that contains those sets. It's minimal with respect to inclusion—no extra sets except those required by the σ-algebra properties.

When we say the Borel σ-algebra is the "smallest σ-algebra containing all open intervals," we mean:

- It contains every open interval (and thus every open set),
- It is a σ-algebra (closed under complements and countable unions),
- And if any other σ-algebra contains all open intervals, it must also contain every set in the Borel σ-algebra.

In other words, the Borel σ-algebra is the intersection of all σ-algebras that contain the open intervals. It's the minimal collection that is a σ-algebra and includes the sets you started with—nothing extra except what closure under the σ-algebra operations forces you to include.

-----
The Borel σ-algebra is not the only σ-algebra containing all open intervals—it's just the smallest. There are many larger σ-algebras that also contain all open intervals. Two important examples:

- **The power set σ-algebra:** This is the collection of all subsets of $\mathbb{R}$ (the power set). It is a σ-algebra, contains all open intervals, and is much larger than the Borel σ-algebra. However, it includes many "wild" sets that are not Borel. Examples of "wild" sets:
    - **Vitali set:** Imagine picking one number from every possible "shift" of the rationals inside $[0,1]$, but never picking two numbers that differ by a rational. It turns out you can't assign a sensible length to this set—no matter how you try, it breaks the rules of what "length" should mean. (It's not Lebesgue measurable.)
    - **Non-measurable subsets of $[0,1]$:** Using a lot of mathematical "magic" (the Axiom of Choice), you can build sets inside $[0,1]$ that are so scrambled up, you can't say how long they are—not even zero or infinity! There's no way to measure them consistently.
    - **Sets with non-measurable characteristic functions:** For some of these wild sets, even the function that just says "is $x$ in the set or not?" (the characteristic function) is so weird that you can't integrate it using Lebesgue measure. It's like asking for the area under a curve that can't even be drawn!
          
  > **Note:** The Borel σ-algebra does **not** contain these wild sets! Sets like the Vitali set are so strange that they can't be built from open or closed sets using countable unions, intersections, and complements. That's why they're not Borel—they only show up in much bigger σ-algebras like the power set or the Lebesgue σ-algebra.


- **The Lebesgue σ-algebra:** This is the collection of all Lebesgue measurable sets. It strictly contains the Borel σ-algebra, because it includes all Borel sets plus additional sets that can be constructed using the Lebesgue measure (for example, by adding subsets of Borel sets of measure zero).

In summary: any σ-algebra that contains the Borel σ-algebra (and thus all open intervals) is "larger" in the sense of set inclusion. The Borel σ-algebra is the minimal one, but there are many larger ones, each with their own uses in analysis and probability.

The phrase "containing all open intervals" by itself does not uniquely specify a single σ-algebra—there are many σ-algebras that contain all open intervals (for example, the power set of $\mathbb{R}$ is one). What makes the Borel σ-algebra special is that it is the **smallest** such σ-algebra: it contains all open intervals, but nothing more than what is forced by the σ-algebra properties (closure under complements and countable unions/intersections).

In other words, every other σ-algebra that contains all open intervals must also contain every Borel set, but the Borel σ-algebra doesn't include any "extra" sets beyond those required. This "minimality" is what makes the Borel σ-algebra stand out: it is the intersection of all σ-algebras containing the open intervals, so it is the most economical or "tightest" σ-algebra that still allows you to measure all open sets and anything you can build from them using σ-algebra operations.


**Standard example**: On $\mathbb{R}$, the Borel σ-algebra $\mathcal{B}(\mathbb{R})$ is the smallest σ-algebra containing all open intervals. Once you throw in all the intervals and close up under complements and countable unions, you get a huge collection that includes all intervals, all open sets, all closed sets, and many more bizarre sets.

### Visualizing σ-algebras: The Resolution Metaphor

Think of a σ-algebra as the **"resolution" or "granularity"** at which you can observe your space.

Imagine $X$ is a rectangular region, like a photograph:

```
┌─────────────────────────────┐
│                             │
│            X                │
│       (full space)          │
│                             │
└─────────────────────────────┘
```

**Example 1: Trivial σ-algebra** $\mathcal{F} = \{\emptyset, X\}$

You have zero resolution - you can only see the entire space or nothing at all.

```
Either:  ┌───────────┐     or:   ┌───────────┐
         │///////////│            │           │
         │/// X /////│            │  empty    │
         │///////////│            │           │
         └───────────┘            └───────────┘
```

**Example 2: Partition σ-algebra**

Say $X = A \cup B$ where $A$ and $B$ are disjoint. Then $\mathcal{F} = \{\emptyset, A, B, X\}$.

Now you have "one bit of resolution" - you can distinguish between two regions:

```
┌─────────────┬───────────────┐
│             │               │
│      A      │       B       │
│   (left)    │    (right)    │
│             │               │
└─────────────┴───────────────┘

You can measure:  ∅, A, B, or A∪B=X
```

**Example 3: Finer partition**

Divide $X$ into four quadrants. Now $\mathcal{F}$ contains $\emptyset$, each quadrant, all possible unions of quadrants, and $X$. That's 16 sets total.

```
┌──────────┬──────────┐
│    A     │    B     │
│          │          │
├──────────┼──────────┤
│    C     │    D     │
│          │          │
└──────────┴──────────┘

You can measure any union: A, B, A∪C, A∪B∪D, etc.
```

**The key insight**: A σ-algebra determines which subsets you can distinguish. Coarser σ-algebras give you less information. Finer σ-algebras give you more information.

**CS analogy**: Think of σ-algebras as different levels of **access control** or **observability**:
- Trivial σ-algebra: You can only query "is the set empty or not?"
- Partition σ-algebra: You can query "which partition class does a point belong to?"
- Borel σ-algebra on $\mathbb{R}$: You can query very detailed geometric properties

**How do you build a σ-algebra?** You start with some "basic" sets you want to measure (like intervals), then you:
1. Throw in all complements
2. Throw in all countable unions
3. Keep repeating until you're closed under these operations

This generates the σ-algebra "generated by" those basic sets.

---

## 2. Measures: Actually Assigning Sizes

Okay, so a σ-algebra tells us *which* sets we can measure. A **measure** tells us *how big* they are.

A measure $\mu$ on $(X, \mathcal{F})$ is a function $\mu: \mathcal{F} \to [0, \infty]$ that satisfies:

1. $\mu(\emptyset) = 0$ - the empty set has size zero (obviously!)
2. **Countable additivity**: If $A_1, A_2, \ldots$ are disjoint sets in $\mathcal{F}$, then:
   $$\mu\left(\bigcup_{i=1}^{\infty} A_i\right) = \sum_{i=1}^{\infty} \mu(A_i)$$

That second property is the crucial one - if sets don't overlap, their total measure is just the sum of their individual measures.

**Common examples**:
- **Lebesgue measure** on $\mathbb{R}$: $\mu([a,b]) = b - a$ (just the length!)
- **Counting measure**: $\mu(A) = |A|$ (how many elements? possibly infinite)
- **Dirac measure** at point $x_0$: $\delta_{x_0}(A) = 1$ if $x_0 \in A$, else $0$ (all the "mass" is at one point)

**Connection to discrete math**: Counting measure on discrete sets turns integration into summation! Many results have discrete analogs.

---

## 3. Measurable Functions: Functions That Play Nice

Now we get to functions. Not every function is "measurable" - we need functions that respect the measurable structure.

A function $f: X \to \mathbb{R}$ is **measurable** if for every Borel set $B$ in $\mathbb{R}$:
$$f^{-1}(B) \in \mathcal{F}$$

In other words, pre-images of measurable sets in the range are measurable sets in the domain.

**Practical shortcut**: You don't need to check all Borel sets! Just check that $f^{-1}((a, \infty)) \in \mathcal{F}$ for all real numbers $a$. If that works, the function is measurable.

**Why do we care?** Because measurable functions are exactly the ones we can integrate. If $f$ isn't measurable, the whole integration machinery breaks down.

**Good news**: Almost every function you encounter in practice is measurable:
- All continuous functions ✓
- All piecewise continuous functions ✓
- Limits of measurable functions ✓
- Sums, products, compositions of measurable functions ✓

You have to work really hard (using the Axiom of Choice) to construct a non-measurable function!

### Visualizing Measurable Functions

Think of it this way: a function $f: X \to \mathbb{R}$ maps your domain to the real line.

```
Domain X                          Range ℝ
┌───────────┐                    ───────────────────►
│           │                        
│     •     │ ───f──►  •        
│   •   •   │ ───f──►    •      
│     •     │ ───f──►      •    
│           │                    
└───────────┘                    
```

For $f$ to be measurable: whenever you pick a measurable set $B$ in the range (on the right), the pre-image $f^{-1}(B)$ (the points in $X$ that map into $B$) must be measurable in $X$.

**Here's a concrete example**: Let $X = [0, 2]$ with Lebesgue measure, and consider this step function:

```
       f(x)
        │
      3 │     ┌─────────
        │     │
      2 │   ──┤
        │   │
      1 │ ──┤
        │
      0 └─┴─┴─┴────────► x
        0 1 2 3
        
f(x) = 1 on [0,1)
f(x) = 2 on [1,2)
f(x) = 3 on [2,3)
```

Is $f$ measurable? Let's use the practical test. For any threshold $a$, is $f^{-1}((a, \infty))$ measurable?

- $f^{-1}((0.5, \infty)) = [0, 3)$ ✓ (interval, so measurable)
- $f^{-1}((1.5, \infty)) = [1, 3)$ ✓ (interval, so measurable)
- $f^{-1}((2.5, \infty)) = [2, 3)$ ✓ (interval, so measurable)

Yes! All pre-images are intervals, which are definitely in the Borel σ-algebra. So $f$ is measurable.

### The Threshold Visualization

Here's another way to think about measurability that connects directly to image processing. For any threshold $a$, you can color the domain based on whether $f(x) > a$:

```
Threshold a = 1.5:

       f(x)                          Domain colored by f > 1.5
        │
      3 │     ┌─────────            ┌─────────┐
        │     │                     │░░░░░░░░░│  ← f > 1.5 here
      2 │   ──┤                     ├─────────┤
        │   │                       │░░░░░░░░░│  ← f > 1.5 here
      1 │ ──┤                       ├─────────┤
        │                           │         │  ← f ≤ 1.5 here
      0 └─┴─┴─┴────────► x         └─────────┘
        0 1 2 3                      0   1   2   3

The shaded region {x : f(x) > 1.5} = [1, 3) must be measurable!
```

$f$ is measurable if and only if these "level sets" $\{x : f(x) > a\}$ are measurable for every threshold $a$.

This is exactly what image segmentation or binary classification does - you threshold a function and ask if the resulting region is something you can measure!

---
