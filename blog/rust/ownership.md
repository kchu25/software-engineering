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

> **Wait, so there are TWO string types?**
>
> Yep! And the difference is crucial:
>
> **String literals (`&str`)** are baked into your compiled program. When you write `"hello"`, that text literally becomes part of your executable file. It sits in a special read-only memory section, which is why you can't change it. It's incredibly fast (no allocation needed), but completely inflexible—you have to know the exact text when you're writing your code.
>
> **`String` (the type)** is like a smart container that lives on the heap. It owns its data and can grow, shrink, and change. When you do `String::from("hello")`, Rust allocates memory on the heap, copies "hello" into it, and gives you a `String` that manages that memory.
>
> Think of it like this: A string literal is like a sign painted on a wall—permanent, fast to read, but you can't change it. A `String` is like a whiteboard—you can write, erase, and rewrite, but someone has to set it up and clean it up.
>
> **Why `&str` instead of just `str`?**
>
> Good catch! The type is actually `str`, but you'll almost never see it alone—it's always behind a reference (`&str`). Here's why: `str` is a "slice" that doesn't have a known size (it could be any length), and Rust needs to know sizes to put things on the stack. So you always access it through a reference (`&`), which IS a known size (just a pointer + length).
>
> When you write `let s = "hello";`, the type is actually `&str`—a reference to string data. The `&` means "I'm borrowing this, I don't own it."
>
> **Do you need the String library?**
>
> Nope! `String` is in Rust's standard library, which is automatically available. You don't need to import anything. Just use `String::from("text")` and you're good to go. The `::from` is just the syntax for calling a function that belongs to the `String` type.

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

> **What's a trait?**
>
> Think of a trait as a label that says "this type can do X." It's like an interface or a capability badge.
>
> The `Copy` trait means "this type is simple enough to just duplicate in memory." If your type has `Copy`, assignments make a real copy instead of a move. 
>
> Integers have `Copy` because copying 4 bytes is trivial. But `String` doesn't have `Copy` because it owns heap data—copying would mean duplicating all that heap memory, which could be expensive. Rust wants to make that explicit (with `.clone()`), not automatic.
>
> **How does `Copy` actually work?**
>
> It's automatic! You don't "apply" it—Rust does it for you based on the type:
>
> ```rust
> let x = 5;        // i32 has Copy
> let y = x;        // Rust sees "i32 has Copy" → makes a copy
> // Both x and y are valid!
>
> let s1 = String::from("hello");  // String doesn't have Copy
> let s2 = s1;                     // Rust sees "no Copy" → moves instead
> // s1 is now invalid!
> ```
>
> You don't write any special code. Rust checks: "Does this type have the `Copy` trait?" If yes → copy. If no → move. That's it.
>
> **So things without `Copy` always get moved?**
>
> Yep! That's the rule:
> - Has `Copy` → assignment/function call makes a copy, original stays valid
> - No `Copy` → assignment/function call moves it, original becomes invalid
>
> Most heap-allocated types (`String`, `Vec`, custom structs with heap data) don't have `Copy`, so they move by default. This prevents accidental expensive copies and prevents the double-free bug.
>
> You'll learn more about traits later, but for now: `Copy` = "safe and cheap to duplicate automatically."

## Functions and Ownership

Passing values to functions works just like assignment:

```rust
let s = String::from("hello");
takes_ownership(s);  // s is moved, can't use it anymore

let x = 5;
makes_copy(x);  // x is copied, still usable
```

> **Wait, so I can't use `s` after calling the function?**
>
> Exactly right! Once you pass `s` to `takes_ownership(s)`, ownership moves into the function. The `s` variable in `main` becomes invalid—you literally can't use it anymore. Try it and Rust will give you a compile error.
>
> ```rust
> let s = String::from("hello");
> takes_ownership(s);
> println!("{}", s);  // ERROR! s was moved
> ```
>
> But `x` works fine because integers have `Copy`. The function gets a copy, your original `x` stays valid.
>
> ```rust
> let x = 5;
> makes_copy(x);
> println!("{}", x);  // Totally fine! x is still 5
> ```
>
> This is the "tedious" part the article mentions—you have to be really careful about ownership when calling functions with heap data. That's why references (next chapter) are so important!

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

## How This Prevents Bugs

**The bugs Rust prevents:**

**1. Use-after-free**
```rust
let s1 = String::from("hello");
let s2 = s1;  // s1 is now invalid
println!("{}", s1);  // Compile error! Can't use freed memory
```
In C/C++, this would compile but crash at runtime. Rust catches it immediately.

**2. Double-free**
```rust
let s1 = String::from("hello");
let s2 = s1;  // Only s2 can free the memory
// When both go out of scope, only s2 calls drop
// s1 can't because it's invalid
```
Without moves, both `s1` and `s2` would try to free the same memory—corruption or crash. Rust makes this impossible.

**3. Memory leaks (mostly)**
```rust
{
    let s = String::from("hello");
    // Use s
}  // Automatic cleanup via drop - no manual free() needed
```
You can't forget to clean up because the compiler does it for you. No need to remember to call `free()`.

**4. Data races (with threads)**
The ownership rules extend to multi-threading. Only one thread can own mutable data at a time, preventing race conditions where two threads modify the same data simultaneously.

**The key insight:** Most memory bugs happen because multiple parts of code think they're responsible for the same memory. Ownership says "exactly ONE owner at a time." This simple rule, enforced at compile time, eliminates entire categories of bugs before your code ever runs.

The tradeoff? You have to think about ownership while writing code. But you catch bugs in seconds (compile errors) instead of hours (debugging crashes). And once it compiles, you know these memory bugs literally cannot happen.