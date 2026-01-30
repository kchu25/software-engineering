@def title = "Rust Ownership: References, Slices, and Practical Patterns"
@def published = "29 January 2026"
@def tags = ["rust"]

# Rust Ownership: References, Slices, and Practical Patterns

This continues from [ownership.md](/blog/rust/ownership/) and covers the practical side of borrowing that beginners need.

---

## References: Borrowing Without Taking Ownership

Remember how passing a `String` to a function moves it?

```rust
fn calculate_length(s: String) -> usize {
    s.len()
}

let s = String::from("hello");
let len = calculate_length(s);
// println!("{}", s);  // ❌ Error! s was moved
```

**References** solve this. The `&` symbol means "borrow this, don't take ownership":

```rust
fn calculate_length(s: &String) -> usize {  // Takes a reference
    s.len()
}

let s = String::from("hello");
let len = calculate_length(&s);  // Pass a reference with &
println!("{}", s);  // ✅ Works! s wasn't moved
```

### What Just Happened?

- `&s` creates a **reference** to `s` (like a pointer that can't be null)
- The function **borrows** `s` temporarily
- When the function ends, the borrow ends
- `s` still owns the data—nothing was moved

Think of it like lending a book: your friend can read it, but you still own it.

---

## `&` vs `&mut`: Shared vs Exclusive Borrowing

There are two kinds of references:

### Immutable Reference (`&T`) — "Read-only access"

```rust
let s = String::from("hello");
let r1 = &s;  // Immutable reference
let r2 = &s;  // Another one - totally fine!
println!("{} and {}", r1, r2);  // ✅ Multiple readers OK
```

You can have **as many `&T` references as you want**. They can all read, but none can modify.

### Mutable Reference (`&mut T`) — "Exclusive write access"

```rust
let mut s = String::from("hello");  // Note: s must be `mut`
let r = &mut s;                      // Mutable reference
r.push_str(" world");                // ✅ Can modify through r
println!("{}", r);  // "hello world"
```

You can have **exactly one `&mut T` reference at a time**. And while it exists, no other references (not even `&T`) are allowed.

### Why the Restriction?

This prevents **data races**. Imagine two pieces of code trying to modify the same data simultaneously—that's a recipe for bugs. Rust says: "Either many readers OR one writer, never both."

```rust
let mut s = String::from("hello");
let r1 = &s;      // Immutable borrow
let r2 = &s;      // Another immutable borrow - fine
// let r3 = &mut s;  // ❌ Error! Can't borrow mutably while borrowed immutably
println!("{}, {}", r1, r2);
```

---

## `let mut` vs `&mut`: They're Different Things!

This confuses many beginners:

```rust
let mut x = 5;  // x is a MUTABLE VARIABLE (can be reassigned)
x = 10;         // ✅ Fine, x is mutable

let r = &mut x; // r is a MUTABLE REFERENCE (can modify what it points to)
*r = 15;        // ✅ Modify x through r
```

| Syntax | Meaning |
|--------|---------|
| `let x = 5;` | Immutable variable (can't change x) |
| `let mut x = 5;` | Mutable variable (can reassign x) |
| `&x` | Immutable reference (can read, not write) |
| `&mut x` | Mutable reference (can read AND write) |

**Key insight**: To get a `&mut` reference, the original variable must be `mut`:

```rust
let s = String::from("hello");  // Not mutable
// let r = &mut s;  // ❌ Error! Can't mutably borrow an immutable variable

let mut s = String::from("hello");  // Mutable
let r = &mut s;  // ✅ Works
```

---

## The Dereference Operator (`*`)

When you have a reference and want to access the actual value, use `*`:

```rust
let x = 5;
let r = &x;
println!("{}", *r);  // Prints 5 - dereferencing r to get the value
```

For modifying through a mutable reference:

```rust
let mut x = 5;
let r = &mut x;
*r = 10;  // Dereference and assign
println!("{}", x);  // Prints 10
```

> **Wait, but I didn't use `*` earlier with strings?**
>
> Good catch! Rust has **automatic dereferencing** (called "deref coercion") for method calls. When you write `r.push_str("...")`, Rust automatically dereferences as needed. You only need explicit `*` for things like assignment or comparison with primitives.

---

## Slices: Borrowing Part of a Collection

A **slice** is a reference to a contiguous portion of a collection. It lets you borrow part of the data without copying.

### String Slices (`&str`)

```rust
let s = String::from("hello world");

let hello = &s[0..5];   // Slice from index 0 to 4
let world = &s[6..11];  // Slice from index 6 to 10

println!("{} {}", hello, world);  // "hello world"
```

The slice `&s[0..5]` doesn't copy "hello"—it's just a reference to that part of the string.

**Syntax shortcuts:**
```rust
let s = String::from("hello");
let slice = &s[0..2];  // "he"
let slice = &s[..2];   // Same - start from 0
let slice = &s[2..];   // "llo" - go to end
let slice = &s[..];    // Whole string
```

### Why `&str` Instead of `&String`?

This is a key pattern. When writing functions, prefer `&str` over `&String`:

```rust
// ❌ Less flexible - only accepts &String
fn first_word_bad(s: &String) -> &str {
    // ...
}

// ✅ More flexible - accepts &String AND &str
fn first_word(s: &str) -> &str {
    let bytes = s.as_bytes();
    for (i, &item) in bytes.iter().enumerate() {
        if item == b' ' {
            return &s[..i];
        }
    }
    &s[..]
}

let my_string = String::from("hello world");
first_word(&my_string);     // ✅ Works with &String
first_word(&my_string[..]); // ✅ Works with slice of String
first_word("hello world");  // ✅ Works with string literal (&str)
```

> **So `&str` is the "general purpose" string reference?**
>
> Exactly! A `&String` can automatically coerce to `&str`, but not vice versa. So `&str` accepts both.
>
> Think of it like this:
> - `String` = owned string data (you can modify it)
> - `&str` = borrowed view of string data (read-only)
>
> String literals like `"hello"` are already `&str` (they're baked into your program).

### Array Slices

Same concept works for arrays and vectors:

```rust
let a = [1, 2, 3, 4, 5];
let slice = &a[1..3];  // [2, 3] - type is &[i32]

let v = vec![1, 2, 3, 4, 5];
let slice = &v[1..3];  // Same - borrows part of the vector
```

---

## Practical Patterns: When to Use What

### Pattern 1: Read-only access → Use `&T`

```rust
fn print_length(s: &String) {  // Just reading, use &
    println!("Length: {}", s.len());
}

let s = String::from("hello");
print_length(&s);
println!("{}", s);  // s still valid
```

### Pattern 2: Need to modify → Use `&mut T`

```rust
fn add_exclamation(s: &mut String) {
    s.push_str("!");
}

let mut s = String::from("hello");
add_exclamation(&mut s);
println!("{}", s);  // "hello!"
```

### Pattern 3: Function takes ownership (consumes the value) → Use `T`

```rust
fn consume_and_transform(s: String) -> String {
    s.to_uppercase()  // Takes s, returns new String
}

let s = String::from("hello");
let s = consume_and_transform(s);  // s moved in, result moved out
// Old s is gone, but we have new s
```

### Pattern 4: Expensive to clone, need owned copy → Think twice, maybe borrow

```rust
// ❌ Expensive if data is large
fn process(data: Vec<i32>) {
    // ...
}
let v = vec![1, 2, 3, /* ... thousands more */];
process(v.clone());  // Cloning is expensive!

// ✅ Better - just borrow
fn process(data: &[i32]) {
    // ...
}
let v = vec![1, 2, 3, /* ... thousands more */];
process(&v);  // No clone needed
```

---

## Lifetime Annotations: A Quick Preview

Sometimes Rust can't figure out how long a reference should live:

```rust
// ❌ Won't compile - Rust doesn't know which reference's lifetime to use
fn longest(x: &str, y: &str) -> &str {
    if x.len() > y.len() { x } else { y }
}
```

You tell Rust explicitly with **lifetime annotations**:

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

The `'a` says: "The returned reference lives as long as the shorter of the two inputs."

> **This looks scary!**
>
> It does at first. But here's the mental model:
>
> - `'a` is just a name (like a variable name, but for lifetimes)
> - `&'a str` means "a reference that's valid for at least lifetime 'a"
> - When two parameters share the same `'a`, it means "these references must be valid for the same (overlapping) period"
>
> Most of the time, Rust figures out lifetimes automatically ("lifetime elision"). You only need to write them when Rust asks you to.

---

## Common Mistakes and Fixes

### Mistake 1: Returning a reference to local data

```rust
// ❌ Won't compile
fn create_string() -> &String {
    let s = String::from("hello");
    &s  // s is dropped here, reference would dangle!
}

// ✅ Fix: Return owned data
fn create_string() -> String {
    String::from("hello")  // Ownership moves to caller
}
```

### Mistake 2: Mutating while borrowing

```rust
let mut v = vec![1, 2, 3];
let first = &v[0];  // Immutable borrow
v.push(4);          // ❌ Error! Can't mutate while borrowed
println!("{}", first);

// ✅ Fix: Finish using the borrow first
let mut v = vec![1, 2, 3];
let first = v[0];   // Copy the value (i32 has Copy)
v.push(4);          // ✅ Now fine
println!("{}", first);
```

### Mistake 3: Multiple mutable borrows

```rust
let mut s = String::from("hello");
let r1 = &mut s;
let r2 = &mut s;  // ❌ Error! Can't have two &mut
println!("{}, {}", r1, r2);

// ✅ Fix: Use them sequentially
let mut s = String::from("hello");
{
    let r1 = &mut s;
    r1.push_str(" world");
}  // r1 goes out of scope
let r2 = &mut s;  // ✅ Now fine
r2.push_str("!");
```

---

## Quick Reference

| I want to... | Use | Example |
|--------------|-----|---------|
| Read data without owning | `&T` | `fn len(s: &String)` |
| Modify data without owning | `&mut T` | `fn append(s: &mut String)` |
| Take ownership (consume) | `T` | `fn consume(s: String)` |
| Borrow part of a string | `&str` | `&my_string[0..5]` |
| Borrow part of an array/vec | `&[T]` | `&my_vec[1..3]` |
| Copy the data entirely | `.clone()` | `let copy = s.clone()` |

---

## Mental Model Summary

Think of ownership like library books:

- **Owning** = You checked out the book. It's yours until you return it.
- **`&` borrowing** = A friend is reading over your shoulder. They can look, but you still have it.
- **`&mut` borrowing** = You handed the book to a friend to take notes. While they have it, you can't even look at it.
- **Moving** = You gave the book to someone else. You can't use it anymore.
- **Cloning** = You photocopied the entire book. Now there are two copies.
- **Slices** = Someone took a photo of one page. They can see that page, but don't have the book.

The borrow checker is the librarian making sure nobody breaks the rules!
