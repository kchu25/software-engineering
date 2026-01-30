@def title = "Rust Enums vs Julia: Different Paths to the Same Goal"
@def published = "29 January 2026"
@def tags = ["rust"]

# Rust Enums vs Julia: Different Paths to the Same Goal

You're onto something! Rust enums and Julia's multiple dispatch are solving similar problems, just from opposite directions.

## The Core Idea

Rust enums let you say "this value is one of several distinct possibilities, each with potentially different data." Then you pattern match to handle each case:

## Why Can Enum Variants Hold Data? (And Why Is the Syntax So Clean?)

This is a reasonable question! In many languages (like C or Java), enums are just named constants—glorified integers:

```c
// C enum - just integers with names
enum Color { RED, GREEN, BLUE };  // RED=0, GREEN=1, BLUE=2
```

Rust's enums are fundamentally different: each variant can hold **its own data**. Why would you want this?

### The Problem: Related Data That Comes in Different Shapes

Imagine you're building a network library. An IP address can be either:
- **IPv4**: 4 numbers (like 192.168.1.1)
- **IPv6**: a longer string (like "::1")

These are conceptually the same thing (an IP address) but have **different structures**. Without data-holding enums, you'd need awkward workarounds:

```rust
// ❌ Ugly approach: separate types, no unification
struct IPv4 { octets: [u8; 4] }
struct IPv6 { addr: String }

// Now every function needs two versions or a trait...
fn connect_v4(ip: IPv4) { }
fn connect_v6(ip: IPv6) { }
```

Or worse:

```rust
// ❌ Really ugly: one struct with optional fields
struct IpAddr {
    v4_octets: Option<[u8; 4]>,  // Only used if it's v4
    v6_addr: Option<String>,     // Only used if it's v6
    is_v4: bool,                 // Which one is it?
}
// Gross! And easy to mess up.
```

### The Solution: Variants That Carry Data

Rust lets you bundle the "which kind" tag with the "what data" payload in one clean type:

```rust
// ✅ Clean: one type, two shapes
enum IpAddr {
    V4(u8, u8, u8, u8),
    V6(String),
}

// One function handles both!
fn connect(ip: IpAddr) {
    match ip {
        IpAddr::V4(a, b, c, d) => println!("Connecting to {}.{}.{}.{}", a, b, c, d),
        IpAddr::V6(addr) => println!("Connecting to {}", addr),
    }
}
```

### Why Is the Syntax So Simple?

Rust deliberately made this easy because **it's so useful**. The syntax `V4(u8, u8, u8, u8)` is shorthand for "this variant holds a tuple of four u8s." You don't need to define a separate struct—the data shape is declared inline.

Think of each variant as having an **anonymous, embedded struct**:

```rust
// What you write:
enum Message {
    Move { x: i32, y: i32 },   // Named fields (struct-like)
    Write(String),              // Single value (tuple-like)
    Quit,                       // No data (unit-like)
}

// Conceptually similar to:
struct MoveData { x: i32, y: i32 }
struct WriteData(String);
struct QuitData;
// ...but bundled into one type with less boilerplate
```

### The Payoff: Type Safety + Convenience

Because `IpAddr` is one type, you get:
1. **One variable** can hold either variant: `let addr: IpAddr = ...`
2. **One function signature** handles all cases: `fn process(ip: IpAddr)`
3. **Compiler-enforced handling**: `match` forces you to deal with every variant

This pattern is everywhere in Rust: `Option<T>` (value or nothing), `Result<T, E>` (success or error), and countless custom types.

### Wait, Are Variants Separate Structs?

**No!** This is a crucial point. When you write:

```rust
enum IpAddr {
    V4(u8, u8, u8, u8),
    V6(String),
}
```

`V4` is **not** a defined struct. It's just a variant with inline data. Rust automatically generates constructor functions:
- `IpAddr::V4(a, b, c, d)` - takes 4 u8s, returns an `IpAddr`
- `IpAddr::V6(s)` - takes a String, returns an `IpAddr`

In memory, an enum value has two parts: a **tag** (which variant is this?) plus the **data** (the variant's payload). The tag might be 0 for V4, 1 for V6. Then the same memory region is interpreted differently:
- If tag = 0: next 4 bytes = `(u8, u8, u8, u8)`
- If tag = 1: next bytes = `String`

You *could* define separate structs if you wanted:

```rust
struct V4Data(u8, u8, u8, u8);
struct V6Data(String);
enum IpAddr {
    V4(V4Data),
    V6(V6Data),
}
```

But the first version is cleaner—it's syntactic sugar for defining the tuple structure directly in the variant.

**Julia comparison**: Julia doesn't have this "inline anonymous struct" feature. You'd write separate named types:

```julia
struct IPv4
    octets::NTuple{4, UInt8}
end

struct IPv6
    addr::String
end
```

Each gets its own name in the type system. Rust's enum lets you skip the naming ceremony and bundle everything under one type.

```rust
enum IpAddr {
    V4(u8, u8, u8, u8),
    V6(String),
}

// Pattern matching decides what to do
match ip {
    IpAddr::V4(a, b, c, d) => /* handle v4 */,
    IpAddr::V6(addr) => /* handle v6 */,
}
```

Julia says "just define functions for different types, and I'll dispatch to the right one":

```julia
struct IPv4
    octets::NTuple{4, UInt8}
end

struct IPv6
    addr::String
end

# Multiple dispatch picks the right method
route(ip::IPv4) = # handle v4
route(ip::IPv6) = # handle v6
```

## Why They Feel Similar

Both are about **type-driven behavior**. You're saying "different types of data need different handling," and the language routes your code accordingly.

The big difference? **Where the branching happens:**
- Rust: branching is explicit (you write `match`)
- Julia: branching is implicit (the compiler picks the method)

## The Structural Difference

Rust enums are a **closed set**. When you define `enum Message`, you're saying these are ALL the possible variants, period. The compiler can verify you've handled every case in your pattern match. If you forget a variant, compilation fails.

**What does "closed set" mean?** It just means "fixed and complete at definition time." When you write the enum, you declare all possible variants upfront:

```rust
enum IpAddr {
    V4(u8, u8, u8, u8),
    V6(String),
}
```

That's it. Those are the only two possibilities. You can't add a `V7` variant later. The set is **closed**—locked in, finite, no extensions allowed.

Julia's approach is **open**. You can define new types and add methods for `route()` anytime, anywhere:

```julia
abstract type IpAddr end

struct IPv4 <: IpAddr
    octets::NTuple{4, UInt8}
end

struct IPv6 <: IpAddr
    addr::String
end

# Later, somewhere else in your code...
struct IPv7 <: IpAddr  # Sure, why not!
    future_stuff::Vector{UInt8}
end
```

The set of subtypes of `IpAddr` is **open**—you can extend it anytime.

**Why it matters:** With a closed set, the compiler can ask: "Did you handle V4? Did you handle V6? Yes to both? Great, you've covered everything." With an open set, the compiler can't make that guarantee because someone might define a new type tomorrow. If you call `route(x)` on a type with no matching method, you get a runtime `MethodError`, not a compile-time guarantee.

## The Rust Advantage: Data Bundling

Rust's clever trick is that each enum variant can carry **different shaped data**:

```rust
enum Message {
    Quit,                           // no data
    Move { x: i32, y: i32 },       // named fields
    Write(String),                  // single value
    ChangeColor(i32, i32, i32),    // tuple
}
```

Each variant has its own data structure, yet they're all unified under one type: `Message`. A function accepting `Message` can handle all variants through pattern matching.

In Julia, you'd need a union type or abstract type hierarchy:

```julia
abstract type Message end
struct Quit <: Message end
struct Move <: Message
    x::Int32
    y::Int32
end
```

But Julia's version is **open** (you can add more subtypes later), while Rust's enum is **closed** (the set of variants is fixed). The tradeoff: Rust gives compile-time exhaustiveness, Julia gives runtime extensibility.

## The Option Example

Now here's where Rust's enum philosophy really shines in practice. Remember how enums let you represent "one of several possibilities"? Rust applies this idea to solve one of programming's most common problems: **representing the absence of a value**.

Instead of having `null` (which can sneak into any type), Rust has an enum called `Option<T>` that explicitly says "this might be nothing":

```rust
let maybe_number: Option<i32> = Some(5);
// or
let nothing: Option<i32> = None;
```

`Option<T>` is either `Some(value)` or `None`. The key insight: `Option<T>` and `T` are **different types**. You **cannot** use an `Option<i32>` where an `i32` is expected. You must explicitly unwrap or pattern match to handle both cases:

```rust
match maybe_number {
    Some(n) => println!("Got {}", n),
    None => println!("Got nothing"),
}
```

This prevents the billion-dollar mistake: in languages with `null`, any reference might secretly be null, but the type system doesn't warn you. You can't tell if a function returns a value or might return null, leading to null pointer exceptions.

Julia would use `Union{T, Nothing}` and rely on `isnothing()` checks. The difference? Julia's approach is **voluntary** (you can forget the check), while Rust **forces** you to handle the `None` case through pattern matching, preventing null errors at compile time.

## Bottom Line

Rust enums + pattern matching ≈ Julia's multiple dispatch, but Rust gives you:
- Compile-time exhaustiveness checking
- A single type that encompasses multiple data shapes
- Forced null-safety through `Option<T>`

Julia gives you:
- More flexibility (open extension)
- Less ceremony
- Runtime dynamism

Both are powerful tools for "different data, different code." Rust just makes you declare all possibilities upfront, while Julia lets you add cases as you go.