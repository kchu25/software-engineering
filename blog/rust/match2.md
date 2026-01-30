@def title = "Rust's Match: A Gentler Introduction"
@def published = "29 January 2026"
@def tags = ["rust"]

# Rust's Match: A Gentler Introduction

Think of `match` as a super-powered `if-else` chain. You give it a value, it checks that value against a list of patterns, and runs the code for whichever pattern fits first.

---

## The Coin-Sorting Machine Analogy

Imagine a machine that sorts coins. You drop a coin in, it slides down a track with different-sized holes, and falls through the first hole it fits.

`match` works the same way:
- You give it a value (the coin)
- It checks each pattern from top to bottom (the holes)
- When it finds a match, it runs that code and stops (coin falls through)

```rust
enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter,
}

fn value_in_cents(coin: Coin) -> u8 {
    match coin {
        Coin::Penny => 1,      // Is it a penny? Return 1
        Coin::Nickel => 5,     // Is it a nickel? Return 5
        Coin::Dime => 10,      // Is it a dime? Return 10
        Coin::Quarter => 25,   // Is it a quarter? Return 25
    }
}
```

**How it reads:** "Match `coin` against these patterns. If it's a Penny, return 1. If it's a Nickel, return 5..." and so on.

---

## Match vs If: What's the Difference?

With `if`, the condition must be true or false (a boolean):

```rust
if coin_value == 1 {
    println!("penny");
}
```

With `match`, you compare against **patterns**, which can be much richer:

```rust
match coin {
    Coin::Penny => 1,
    Coin::Nickel => 5,
    Coin::Dime => 10,
    Coin::Quarter => 25,
}
```

The pattern `Coin::Penny` isn't a boolean—it's asking "does `coin` have the shape/variant `Penny`?"

**Note on return values:** Each arm returns a value. In the example above, the `match` expression returns an integer. If you just want to do something without returning a meaningful value, all arms return `()` (the unit type):

```rust
match coin {
    Coin::Penny => println!("penny"),    // println! returns ()
    Coin::Nickel => println!("nickel"),  // println! returns ()
    Coin::Dime => println!("dime"),      // println! returns ()
    Coin::Quarter => println!("quarter"),// println! returns ()
}
// This whole match expression returns ()
```

All arms must return the **same type**. Here they all return `()`, so it's valid.

---

## Running Multiple Lines of Code

Short code? Just write it after `=>`:

```rust
Coin::Penny => 1,
```

Need multiple lines? Use curly braces:

```rust
Coin::Penny => {
    println!("Lucky penny!");
    1  // This is still the return value
}
```

---

## Extracting Data from Variants (Pattern Binding)

Here's where `match` gets interesting. Sometimes enum variants carry data inside them:

```rust
enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter(UsState),  // Quarters have a state!
}
```

When matching, you can **pull that data out** and give it a name:

```rust
fn value_in_cents(coin: Coin) -> u8 {
    match coin {
        Coin::Penny => 1,
        Coin::Nickel => 5,
        Coin::Dime => 10,
        Coin::Quarter(state) => {
            // `state` now holds the UsState value!
            println!("State quarter from {:?}!", state);
            25
        }
    }
}
```

When you call `value_in_cents(Coin::Quarter(UsState::Alaska))`:
1. Rust sees it's a `Quarter`
2. The pattern `Quarter(state)` matches, and `state` gets bound to `UsState::Alaska`
3. You can now use `state` in your code

**Think of it like unpacking a box**: The pattern describes what shape you expect, and gives names to the pieces inside.

---

## Option: Handling "Maybe There's a Value"

This is where people often get confused, so let's go slowly.

### The Problem Option Solves

Sometimes you don't have a value. Maybe a function couldn't find what it was looking for. Maybe the user didn't provide input. In many languages, you'd use `null`:

```javascript
// JavaScript
function findUser(id) {
    if (/* user exists */) return user;
    return null;  // No user found
}

let user = findUser(123);
user.name  // 💥 CRASH if user is null!
```

The problem? You might forget to check for `null`, and your program crashes.

### Rust's Solution: Option<T>

Rust doesn't have `null`. Instead, it has an enum called `Option`:

```rust
// This is the DEFINITION of the Option type (already in Rust's standard library)
enum Option<T> {
    Some(T),   // Variant 1: "I have a value, and here it is"
    None,      // Variant 2: "I have nothing"
}
```

That `<T>` just means "some type"—it could be `Option<i32>` (maybe an integer), `Option<String>` (maybe a string), etc.

### Creating Option Values

Here's the key distinction:

- **Defining an enum** = Declaring what variants exist (done once)
- **Creating a value** = Making an instance of one specific variant (done many times)

You don't "create an enum"—you create a **value** that is one of the enum's variants:

```rust
// Creating VALUES of type Option<i32>
let has_a_number: Option<i32> = Some(5);   // A value: the Some variant holding 5
let has_nothing: Option<i32> = None;        // A value: the None variant

// Think of it like this:
// - Option<i32> is the TYPE (like a category)
// - Some(5) is a specific VALUE of that type
// - None is also a specific VALUE of that type
```

It's similar to how `true` and `false` are both values of type `bool`:

```rust
let a: bool = true;   // A value of type bool
let b: bool = false;  // Another value of type bool

let x: Option<i32> = Some(5);  // A value of type Option<i32>
let y: Option<i32> = None;     // Another value of type Option<i32>
```

### Why This Is Better Than Null

**You can't accidentally use an `Option<i32>` as if it were an `i32`:**

```rust
let maybe_number: Option<i32> = Some(5);

// ❌ This won't compile!
let result = maybe_number + 1;  // Error: can't add Option<i32> and i32
```

Rust forces you to explicitly handle "what if there's no value?" You can't just pretend it's always there.

### Using Match with Option

Here's a function that adds 1 to a number... if there is one:

```rust
fn plus_one(x: Option<i32>) -> Option<i32> {
    match x {
        None => None,           // Nothing in? Nothing out.
        Some(i) => Some(i + 1), // Got a number? Add 1, wrap it back in Some.
    }
}
```

Let's trace through it:

**Case 1: `plus_one(Some(5))`**
1. `x` is `Some(5)`
2. Does `Some(5)` match `None`? No.
3. Does `Some(5)` match `Some(i)`? Yes! And `i` becomes `5`.
4. We return `Some(5 + 1)` = `Some(6)`

**Case 2: `plus_one(None)`**
1. `x` is `None`
2. Does `None` match `None`? Yes!
3. We return `None`

```rust
let five = Some(5);
let six = plus_one(five);    // Some(6)
let none = plus_one(None);   // None
```

### The Key Insight

`Some(i)` in the pattern does two things:
1. **Checks**: Is this a `Some` variant?
2. **Extracts**: If yes, pull out the inner value and call it `i`

It's like saying "if there's something inside, take it out and call it `i`."

---

## You Must Handle Every Case (Exhaustiveness)

Rust won't let you forget a case. This code won't compile:

```rust
fn plus_one(x: Option<i32>) -> Option<i32> {
    match x {
        Some(i) => Some(i + 1),
        // ❌ Forgot to handle None!
    }
}
```

Error message:
```
error: non-exhaustive patterns: `None` not covered
```

Rust knows `Option<i32>` has two variants (`Some` and `None`), and you only handled one. This is a **feature**, not a bug—it prevents you from accidentally ignoring the "nothing" case.

---

## Catch-All Patterns: Handling "Everything Else"

Sometimes you only care about a few specific values. Use a catch-all for the rest:

### Using a variable name (when you need the value)

```rust
let dice_roll = 9;

match dice_roll {
    3 => add_fancy_hat(),
    7 => remove_fancy_hat(),
    other => move_player(other),  // Any other number: use it!
}
```

The `other` pattern matches anything not already matched, and binds that value to `other` so you can use it.

### Using `_` (when you don't need the value)

```rust
match dice_roll {
    3 => add_fancy_hat(),
    7 => remove_fancy_hat(),
    _ => reroll(),  // Anything else: just reroll, don't care what it was
}
```

The `_` pattern matches anything but **doesn't bind** the value. Use this when you genuinely don't care what the value is.

### Doing nothing for the catch-all

```rust
match dice_roll {
    3 => add_fancy_hat(),
    7 => remove_fancy_hat(),
    _ => (),  // Anything else: do nothing
}
```

The `()` is Rust's "nothing" value (called the unit type). It's like an empty statement.

---

## Order Matters!

Patterns are checked **top to bottom**. Once one matches, Rust stops checking.

```rust
match dice_roll {
    _ => do_default_thing(),  // ⚠️ This catches EVERYTHING!
    3 => add_fancy_hat(),     // Never reached!
    7 => remove_fancy_hat(),  // Never reached!
}
```

Rust will warn you about unreachable patterns. Always put your catch-all (`_` or `other`) **last**.

---

## Quick Summary

| Concept | What it means |
|---------|--------------|
| `match value { ... }` | Compare `value` against patterns |
| `Pattern => code` | If pattern matches, run code |
| `Coin::Penny => 1` | Match a specific variant |
| `Some(x) => ...` | Match and extract inner value |
| `other => ...` | Catch-all that binds the value |
| `_ => ...` | Catch-all that ignores the value |
| `_ => ()` | Catch-all that does nothing |

---

## The Mental Model

Think of `match` as asking a series of questions:

```rust
match my_option {
    None => /* "Is it None? If so, do this" */,
    Some(x) => /* "Is it Some? If so, take out the value (call it x) and do this" */,
}
```

The beauty is that Rust **makes sure you've answered all the questions**. You can't accidentally forget the "what if it's None?" case. That's the safety guarantee that makes `Option` better than `null`.
