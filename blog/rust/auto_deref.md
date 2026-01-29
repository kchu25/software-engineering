@def title = "Do Reference Expressions Return the Object in Rust?"
@def published = "29 January 2026"
@def tags = ["rust"]

# Do Reference Expressions Return the Object in Rust?

**Short answer: No.** A reference expression returns a *reference* to the object, not the object itself.

## What's the difference?

Think of it like this:

```rust
let book = String::from("The Rust Book");
let book_ref = &book;  // This is a reference - like a pointer to where the book lives
```

Here, `book_ref` doesn't get a copy of the book. It gets the *address* of where `book` lives in memory. It's like having directions to a library instead of carrying the actual library around with you.

## Why does this matter?

**Ownership stays put:**
```rust
let data = vec![1, 2, 3];
let reference = &data;  // data still owns the vector
// reference is just borrowing it
```

The original owner (`data`) keeps ownership. The reference just borrows it temporarily.

**You can't move through a reference:**
```rust
let x = String::from("hello");
let r = &x;
// You can't move x through r
// r.clone() gives you a clone of the String, not ownership of x
```

## Wait, but you can call methods on references just like the object?

**Yes! And that's because of Rust's automatic dereferencing.**

```rust
let s = String::from("hello");
let r = &s;

// These both work the same way:
r.len();  // works!
s.len();  // works!
```

When you call a method on a reference, Rust automatically "follows the pointer" for you. It's smart enough to know: "Oh, you want to call `.len()` on the String that this reference points to."

Behind the scenes, Rust is doing `(*r).len()`, but you don't have to write that. It just works.

**This is purely syntactic sugar.** The reference is still just a pointer—Rust just makes it ergonomic to use.

## The practical takeaway

When you write `&something`, you're creating a reference that *points to* `something`. You're not duplicating it or transferring ownership—you're just creating a lightweight way to access it.

And thanks to automatic dereferencing, you can use references almost like you'd use the original object. Rust handles the pointer-following for you, making references feel natural to work with.

This is actually Rust's superpower: you can pass references around cheaply without copying data or giving up ownership!