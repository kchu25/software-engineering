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

## Where's the `->` operator? (For C/C++ folks)

If you're coming from C or C++, you might be wondering why there's no `->` operator in Rust.

**In C/C++, you have two operators:**
- `.` for calling methods on objects directly
- `->` for calling methods on pointers (which does `(*ptr).method()` for you)

```cpp
// C++ example
object.method();   // calling on object
ptr->method();     // calling on pointer (equivalent to (*ptr).method())
```

**Rust just uses `.` for everything:**

```rust
let p1 = Point { x: 0, y: 0 };
let p2 = Point { x: 3, y: 4 };

// All of these work:
p1.distance(&p2);        // calling on the value directly
(&p1).distance(&p2);     // calling on a reference
```

## How does this magic work?

First, let's understand what methods actually look like when they're defined.

**A method signature is just the "header" of a method**—it shows the method's name, what parameters it takes, and what it returns:

```rust
impl String {
    // Signature: fn len(&self) -> usize
    // Translation: "len takes a reference to self, returns a usize"
    fn len(&self) -> usize { ... }
    
    // Signature: fn push_str(&mut self, string: &str)
    // Translation: "push_str takes a mutable reference to self and a string slice"
    fn push_str(&mut self, string: &str) { ... }
    
    // Signature: fn into_bytes(self) -> Vec<u8>
    // Translation: "into_bytes takes ownership of self, returns a Vec"
    fn into_bytes(self) -> Vec<u8> { ... }
}
```

The signature is like a contract: "Here's what I need, here's what I'll give you back."

That first parameter—`self`, `&self`, or `&mut self`—is the key. It tells Rust what the method needs to receive.

**Now here's the magic:** When you call `object.method()`, Rust looks at the method's signature and automatically adjusts `object` to match:

```rust
let mut s = String::from("hello");

// len() is defined as: fn len(&self)
// So Rust automatically does: (&s).len()
s.len();

// push_str() is defined as: fn push_str(&mut self, ...)
// So Rust automatically does: (&mut s).push_str(" world")
s.push_str(" world");
```

**You can even call these methods on references directly:**

```rust
let r = &s;
r.len();  // r is already &s, method needs &self, perfect match!

let r = &mut s;
r.push_str("!");  // r is already &mut s, method needs &mut self, perfect match!
```

Rust figures this out because methods **declare exactly what they need** in their signature. Since the requirement is crystal clear, Rust can automatically add `&`, `&mut`, or `*` to make it work.

**Why this matters:** You don't have to think about whether you have a value or a reference when calling methods. Just use `.` and Rust handles it. This makes ownership much more ergonomic in practice.

## Why did Rust's designers make this choice?

This isn't just convenient syntax—it's a carefully designed solution to a fundamental tension in Rust's philosophy.

**The problem Rust faced:**

Rust wants you to be explicit about ownership and borrowing. That's the whole point—you should know whether you're moving, borrowing, or mutating. But if Rust forced you to write `(&object).method()` or `(&mut object).method()` everywhere, the code would be cluttered and frustrating:

```rust
// Imagine if you had to write this:
(&s).len()
(&mut s).push_str(" world")
(&(&s)).chars()
```

Yuck! This would make Rust painful to use, even though ownership tracking is valuable.

**Rust's solution: Make the common case ergonomic**

The designers realized something clever: **When calling methods, the ownership requirement is unambiguous.** The method signature explicitly says what it needs (`self`, `&self`, or `&mut self`), so there's no guessing involved.

Since there's no ambiguity, why make you write it out? Let the compiler figure it out!

**This preserves Rust's philosophy:**
- ✅ You're still being explicit about ownership (the method signature tells you)
- ✅ The borrow checker still validates everything
- ✅ But you get clean, readable code like `s.len()` instead of `(&s).len()`

**The wisdom:** Rust makes you explicit where it matters (function arguments, return values, variable bindings) but saves you from repetitive ceremony where the compiler can safely infer your intent. This is why Rust can enforce strict ownership rules without feeling like you're fighting the language constantly.

It's not magic—it's thoughtful language design that makes correctness ergonomic.

## The practical takeaway

When you write `&something`, you're creating a reference that *points to* `something`. You're not duplicating it or transferring ownership—you're just creating a lightweight way to access it.

And thanks to automatic dereferencing, you can use references almost like you'd use the original object. Rust handles the pointer-following for you, making references feel natural to work with.

This is actually Rust's superpower: you can pass references around cheaply without copying data or giving up ownership!