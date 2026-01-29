@def title = "Rust Ownership & Borrowing: A Mathematical View"
@def published = "29 January 2026"
@def tags = ["rust"]

# Rust Ownership & Borrowing: A Mathematical View

Let me formalize what's actually happening in Rust's ownership system, because the tutorials often make it sound more mysterious than it is.

## The Core Idea

Think of memory locations as a set $M$, values as a set $V$, and time steps as a set $T$ (e.g., discrete program points). At any point in time $t \in T$, we have two functions:

$$\text{contents}: M \times T \rightarrow V$$
$$\text{owner}: M \times T \rightarrow \text{Variables} \cup \{\perp\}$$

where $\perp$ means "no owner" (the memory is freed). The $\text{contents}$ function tells us what value is stored at each memory location.

**The fundamental rule**: For any memory location $m$ at any time $t$, there exists **at most one** variable that owns it.

$$|\{v \in \text{Variables} \mid \text{owner}(m, t) = v\}| \leq 1$$

That's it. One owner per piece of memory. When that owner goes out of scope, the memory is freed and both functions become undefined for that location.

## Moves (Transfer of Ownership)

When you write `let b = a;` for a non-Copy type, you're doing:

$$\text{owner}(m, t+1) = b \text{ and } \text{owner}(m, t) = \perp$$

where $m$ is the memory that $a$ used to own. Importantly, $\text{contents}(m, t) = \text{contents}(m, t+1)$—the **same value** is still there, just owned by a different variable. The ownership **transfers**—it's not copied. After the move, $a$ is invalidated.

```rust
let s1 = String::from("hello");
let s2 = s1;  // s1 moves into s2
// println!("{}", s1);  // ❌ Error! s1 is no longer valid
println!("{}", s2);  // ✅ Works fine
```

### The Copy Trait Exception

For types implementing `Copy` (like integers), the operation is different:

$$\text{Let } m_a, m_b \text{ be distinct memory locations}$$
$$\text{contents}(m_b, t+1) = \text{contents}(m_a, t)$$
$$\text{owner}(m_a, t+1) = a, \quad \text{owner}(m_b, t+1) = b$$

The value $v \in V$ is **duplicated** to a new location. Both variables remain valid because they own different memory containing the same value.

```rust
let x = 5;
let y = x;  // x is copied, not moved
println!("{}, {}", x, y);  // ✅ Both still valid!
```

> **When are moves actually useful?**
> 
> Moves shine when you're dealing with expensive or unique resources. Imagine you have a massive vector with a million elements, or a file handle, or a network connection. You don't want to accidentally duplicate these things—that would be slow (copying a million elements) or nonsensical (you can't have two "owners" of the same file handle).
> 
> With moves, you can pass these resources around your program efficiently. When you return a big data structure from a function, it just transfers ownership—no copying happens. When you push a value into a vector, it moves in and the vector becomes the new owner.
> 
> The real win is that Rust **forces** you to be explicit about what happens to your data. You can't accidentally have two parts of your code thinking they both own the same file handle. If you need shared access, you have to be deliberate about it (that's where borrowing comes in).
>
> **Where did this idea come from?**
>
> Actually, other languages *have* adopted similar ideas! C++ has move semantics (since C++11), and languages like Swift use similar ownership concepts. The insight came from decades of dealing with memory bugs in C and C++.
>
> The problem: C lets you do anything (leading to crashes), while languages like Java/Python use garbage collection (which adds runtime overhead and unpredictable pauses). Rust asked: "What if we could get C-level performance *and* memory safety by checking everything at compile time?"
>
> The key innovation wasn't moves themselves—it was making the ownership rules **mandatory and checked by the compiler**. C++ lets you opt into move semantics, but you can still shoot yourself in the foot. Rust says "no, *everything* follows these rules, no exceptions." It's stricter, but that strictness is what enables the compiler to guarantee safety without runtime costs.

## Borrowing: The Plot Twist

Borrowing lets you temporarily access data without taking ownership. We can model this with a new function:

$$\text{borrows}: M \times T \rightarrow \mathcal{P}(\text{References})$$

where $\mathcal{P}$ is the power set (set of all subsets).

### Immutable Borrowing (Shared References `&T`)

You can have **multiple** immutable borrows at once:

$$|\text{borrows}(m, t)| \geq 0$$

But here's the constraint: while immutable borrows exist, the owner **cannot mutate** $m$:

$$|\text{borrows}(m, t)| > 0 \implies \text{write}(m, t) = \text{false}$$

```rust
let s = String::from("hello");
let r1 = &s;  // First immutable borrow
let r2 = &s;  // Second immutable borrow - fine!
println!("{} and {}", r1, r2);  // ✅ Multiple readers OK
// s.push_str("world");  // ❌ Can't mutate while borrowed
```

### Mutable Borrowing (Exclusive Reference `&mut T`)

You can have **exactly one** mutable borrow, and **no** immutable borrows:

$$|\text{mut\_borrows}(m, t)| \leq 1$$

$$|\text{mut\_borrows}(m, t)| = 1 \implies |\text{borrows}(m, t)| = 0$$

When a mutable borrow exists, even the owner can't access the data—total exclusivity.

```rust
let mut s = String::from("hello");
let r = &mut s;  // Mutable borrow
r.push_str(" world");  // ✅ Can mutate through r
// println!("{}", s);  // ❌ Owner can't access while mutably borrowed
// let r2 = &mut s;  // ❌ Can't have two mutable borrows
println!("{}", r);  // ✅ Works fine
```

## The Lifetime Constraint

For any reference $r$ that borrows memory $m$ at time $t$:

$$\text{valid}(r, t) \implies \text{owner}(m, t) \neq \perp$$

Translation: references cannot outlive the data they point to. Rust's borrow checker enforces that the lifetime of every reference is a **subset** of the lifetime of what it's borrowing:

$$\text{lifetime}(r) \subseteq \text{lifetime}(\text{owner}(m))$$

## Example: Why This Prevents Dangling Pointers

```rust
let r;
{
    let x = 5;
    r = &x;  // ❌ Compiler error!
}
// x is dropped here, so r would be dangling
```

Mathematically: $\text{lifetime}(r) \not\subseteq \text{lifetime}(x)$ because $r$ lives longer than $x$. Rejected!

```rust
let x = 5;
let r;
{
    r = &x;  // ✅ Works! x outlives r
    println!("{}", r);
}
// x is still alive here
```

## The Invariant That Makes It Work

At **compile time**, Rust proves:

$$\forall m \in M, \forall t \in T: \Big(|\text{mut\_borrows}(m, t)| = 1 \implies |\text{borrows}(m, t)| = 0\Big)$$

$$\land \Big(|\text{mut\_borrows}(m, t)| + |\text{borrows}(m, t)| > 0 \implies \text{owner}(m, t) \neq \perp\Big)$$

This invariant **guarantees** no data races and no use-after-free errors at runtime. It's provably safe!

> **Is this the infamous "fighting the borrow checker"?**
>
> Yes, absolutely. This is exactly what people complain about when learning Rust. The borrow checker is enforcing all those mathematical rules we wrote above—at compile time, on every line of code you write.
>
> The pain comes from a few sources:
>
> 1. **It catches bugs you didn't know you had.** In other languages, you've probably written code with subtle lifetime issues or potential data races that just happened to work most of the time. Rust says "nope, prove to me this is safe."
>
> 2. **Valid designs that are hard to express.** Sometimes you're doing something totally safe (you know the references won't overlap in practice), but the borrow checker can't prove it statically. Classic example: splitting a mutable reference into multiple non-overlapping parts.
>
> 3. **Different mental model.** If you're coming from garbage-collected languages, you're used to "create whatever references you want, the runtime will sort it out." Rust makes you think about ownership upfront.
>
> The good news? After a few weeks, these rules become intuitive. You start designing your code differently—in ways that happen to align with what the borrow checker wants. And then you realize your code has fewer bugs than it used to in other languages. The pain is the learning curve, not a permanent state.

## Summary

- **Ownership**: A bijection (at most) between memory and variables
- **Moving**: Transferring that bijection
- **Borrowing**: Temporary, restricted access that maintains the invariants
- **Lifetimes**: Ensuring references don't outlive their referents

The "magic" is that Rust checks all of this at compile time through lifetime analysis, so you get memory safety with zero runtime cost.