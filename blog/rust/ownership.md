@def title = "Rust Ownership, Simplified"
@def published = "28 January 2026"
@def tags = ["rust"]

# Rust Ownership, Simplified

## The Big Idea

Ownership is Rust's superpower for managing memory without a garbage collector or manual memory management. Think of it like this: every piece of data has exactly one owner at a time, and when that owner disappears, the data gets cleaned up automatically.

Three simple rules:
- Every value has one owner
- Only one owner at a time
- When the owner goes away, the value gets dropped

## Stack vs Heap: A Quick Refresher

**The Stack** is like a stack of plates—last in, first out. Super fast, but only works for data with a known, fixed size.

**The Heap** is more flexible but slower. When you need space, the memory allocator finds a spot and gives you back a pointer (an address). Think of it like getting seated at a restaurant—someone finds you a table and you remember where it is.

Why does this matter? Because ownership is really about managing heap data.

## How Ownership Actually Works

### String Literals vs String Type

```rust
let s = "hello";  // String literal - lives in the program itself
```

This is hardcoded into your executable. Fast, but immutable and you need to know it at compile time.

```rust
let mut s = String::from("hello");
s.push_str(", world!");  // Now we can grow it!
```

The `String` type lives on the heap, so it can grow and change. But someone needs to clean it up when we're done.

### The Magic Moment: Automatic Cleanup

```rust
{
    let s = String::from("hello");
    // use s
}  // <- s goes out of scope, memory automatically freed
```

When `s` goes out of scope, Rust calls a special function called `drop` that cleans up the memory. No garbage collector needed, no manual `free()` calls. Just works.

## The Move: Not What You'd Expect

Here's where Rust gets interesting:

```rust
let x = 5;
let y = x;  // Both x and y are valid - simple copy
```

Integers are small and live on the stack, so copying is cheap. Both variables work fine.

But watch what happens with heap data:

```rust
let s1 = String::from("hello");
let s2 = s1;  // s1 is now INVALID!

println!("{}", s1);  // ERROR! Can't use s1 anymore
```

Why? A `String` is really three things on the stack: a pointer to heap data, a length, and a capacity. When you do `let s2 = s1`, Rust copies those three things but NOT the actual text data on the heap.

If both `s1` and `s2` pointed to the same heap data, they'd both try to free it when they go out of scope—a nasty bug called a "double free." So Rust invalidates `s1` entirely. We say `s1` was **moved** into `s2`.

### When You Actually Want a Copy

```rust
let s1 = String::from("hello");
let s2 = s1.clone();  // Deep copy - both valid

println!("s1 = {}, s2 = {}", s1, s2);  // Works!
```

Use `.clone()` when you need an actual copy of heap data. It's explicit because it can be expensive.

### Types That Do Copy

Some types are so simple they just get copied automatically:
- Integers (`i32`, `u64`, etc.)
- Booleans
- Floating-point numbers
- Characters
- Tuples of these types

These have the `Copy` trait. If a type implements `Copy`, the old variable stays valid after assignment.

## Functions and Ownership

Passing values to functions works just like assignment:

```rust
let s = String::from("hello");
takes_ownership(s);  // s is moved, can't use it anymore

let x = 5;
makes_copy(x);  // x is copied, still usable
```

Same with return values—they transfer ownership:

```rust
fn gives_ownership() -> String {
    String::from("yours")  // Ownership moves to the caller
}

let s = gives_ownership();  // s now owns the string
```

## The Tedious Part

Having to move ownership in and out of functions gets annoying:

```rust
fn calculate_length(s: String) -> (String, usize) {
    let length = s.len();
    (s, length)  // Return the string back so caller can still use it
}
```

This is clunky. The good news? Rust has **references** (coming up in the next chapter) that let you use values without taking ownership.

## Mental Model

Think of ownership like holding a book:
- Only one person can hold it at a time (one owner)
- You can hand it to someone else (move)
- You can photocopy pages (clone)
- When everyone's done with it, it gets returned to the library (drop)
- Some things are like pamphlets—so cheap you can just make copies (Copy types)

The compiler enforces these rules at compile time, so you can't accidentally create memory bugs. It feels restrictive at first, but it's what makes Rust safe and fast.