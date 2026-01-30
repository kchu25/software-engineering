@def title = "if let and let else: When Match Is Overkill"
@def published = "29 January 2026"
@def tags = ["rust"]

# `if let` and `let else`: When Match Is Overkill

Sometimes you only care about **one** pattern. Writing a full `match` for that feels like overkill.

---

## The Problem: Too Much Boilerplate

Say you have an `Option<u8>` and you only want to do something if it's `Some`:

```rust
let config_max = Some(3u8);

match config_max {
    Some(max) => println!("The maximum is configured to be {}", max),
    _ => (),  // Do nothing for None... but we HAVE to write this!
}
```

That `_ => ()` is annoying. You're forced to handle a case you don't care about, just to satisfy the compiler's exhaustiveness requirement.

---

## The Solution: `if let`

`if let` lets you match on just one pattern and ignore everything else:

```rust
let config_max = Some(3u8);

if let Some(max) = config_max {
    println!("The maximum is configured to be {}", max);
}
```

**Read it as:** "If `config_max` matches the pattern `Some(max)`, then run this code."

Much cleaner! No boilerplate `_ => ()` needed.

---

## How `if let` Works

The syntax is:

```rust
if let PATTERN = EXPRESSION {
    // Code runs only if PATTERN matches
}
```

It's basically **syntax sugar** for a `match` with one arm you care about and a catch-all that does nothing:

```rust
// These two are equivalent:

// if let version
if let Some(x) = my_option {
    println!("{}", x);
}

// match version
match my_option {
    Some(x) => println!("{}", x),
    _ => (),
}
```

---

## `if let` with `else`

What if you want to do something when it **doesn't** match? Use `else`:

```rust
let coin = Coin::Quarter(UsState::Alaska);

if let Coin::Quarter(state) = coin {
    println!("State quarter from {:?}!", state);
} else {
    println!("Not a quarter");
}
```

This is equivalent to:

```rust
match coin {
    Coin::Quarter(state) => println!("State quarter from {:?}!", state),
    _ => println!("Not a quarter"),
}
```

---

## Real Example: Counting Non-Quarters

```rust
let mut count = 0;

// With match
match coin {
    Coin::Quarter(state) => println!("State quarter from {:?}!", state),
    _ => count += 1,
}

// With if let (same behavior)
if let Coin::Quarter(state) = coin {
    println!("State quarter from {:?}!", state);
} else {
    count += 1;
}
```

Both work. Use whichever reads better in context.

---

## The Trade-Off: No Exhaustiveness Checking

**With `match`:** The compiler ensures you handle every case. Forget one? Compilation error.

**With `if let`:** You're explicitly saying "I only care about this one pattern." The compiler won't warn you about unhandled cases.

Choose based on your situation:
- Use `match` when you need to handle multiple cases or want the compiler to catch forgotten cases
- Use `if let` when you genuinely only care about one pattern

---

## `let else`: Staying on the "Happy Path"

Sometimes you want to extract a value or **bail out early**. Here's a common pattern:

```rust
fn describe_state_quarter(coin: Coin) -> Option<String> {
    // Extract the state, or return early if it's not a quarter
    let state = if let Coin::Quarter(state) = coin {
        state
    } else {
        return None;
    };

    // Now we can use `state` knowing it exists
    if state.existed_in(1900) {
        Some(format!("{:?} is pretty old, for America!", state))
    } else {
        Some(format!("{:?} is relatively new.", state))
    }
}
```

This works, but it's a bit clunky. One branch returns a value, the other returns from the function entirely.

### `let else` Makes This Cleaner

Rust has `let else` for exactly this pattern:

```rust
fn describe_state_quarter(coin: Coin) -> Option<String> {
    let Coin::Quarter(state) = coin else {
        return None;  // Must diverge (return, break, panic, etc.)
    };

    // `state` is now available here!
    if state.existed_in(1900) {
        Some(format!("{:?} is pretty old, for America!", state))
    } else {
        Some(format!("{:?} is relatively new.", state))
    }
}
```

**Read it as:** "Let this pattern match, otherwise do this (and exit)."

### How `let else` Works

```rust
let PATTERN = EXPRESSION else {
    // This block MUST diverge (return, break, continue, panic!, etc.)
    // It cannot just "fall through" to the next line
};
// If the pattern matched, the bound variables are available here
```

The key rule: **the `else` block must diverge**. It can't just do nothing—it must exit the current flow (return from function, break from loop, panic, etc.).

### Why "Happy Path"?

With `let else`, your main code stays at the top level, reading straight down:

```rust
fn process(input: Option<Data>) -> Result<Output, Error> {
    let Some(data) = input else {
        return Err(Error::NoInput);
    };

    let validated = validate(data) else {
        return Err(Error::Invalid);
    };

    let result = compute(validated) else {
        return Err(Error::ComputeFailed);
    };

    Ok(result)
}
```

Each `let else` is a checkpoint: "if this doesn't work, bail out." The main logic flows straight down without nesting deeper and deeper.

---

## When to Use What?

| Situation | Use |
|-----------|-----|
| Handle all cases explicitly | `match` |
| Only care about one case, ignore the rest | `if let` |
| One case + do something for everything else | `if let` + `else` |
| Extract value or bail out early | `let else` |

---

## Quick Comparison

```rust
let maybe_value: Option<i32> = Some(42);

// match - handles all cases explicitly
match maybe_value {
    Some(v) => println!("Got {}", v),
    None => println!("Got nothing"),
}

// if let - only care about Some
if let Some(v) = maybe_value {
    println!("Got {}", v);
}

// if let + else - care about Some, do something else for None
if let Some(v) = maybe_value {
    println!("Got {}", v);
} else {
    println!("Got nothing");
}

// let else - extract or bail out
fn use_value(opt: Option<i32>) -> i32 {
    let Some(v) = opt else {
        return -1;  // bail out with default
    };
    v * 2  // use the extracted value
}
```

---

## Summary

- **`if let`** = "If this pattern matches, do something" (ignore non-matches)
- **`if let` + `else`** = "If this pattern matches, do X; otherwise do Y"
- **`let else`** = "Extract this value, or bail out early"

All three are shortcuts for common `match` patterns. They make your code more concise when you don't need full pattern matching power.

**Remember:** `if let` trades exhaustiveness checking for conciseness. Use `match` when you want the compiler to ensure you've handled all cases.
