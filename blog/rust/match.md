@def title = "Understanding Rust's Match (and why the weird terminology)"
@def published = "29 January 2026"
@def tags = ["rust"]

# Understanding Rust's Match (and why the weird terminology)

## Why is it called "arms"? (You're right, it IS weird)

Honestly, "arms" is just programming jargon that stuck. It comes from formal computer science terminology for pattern matching constructs. You could call them "branches," "cases," "options," or "clauses" and it would make just as much sense—probably more sense!

The term probably comes from visualizing the control flow like a tree with branches, or "arms" extending out. But yeah, when you first encounter it, it feels like arbitrary vocabulary.

Each arm is just:
```rust
pattern => code_to_run
```

**Better mental model**: Think of them as "branches" in a decision tree, or just "cases" like in a switch statement.

## Why does match have to do with enums?

It doesn't *have* to—but enums are where match really shines. Here's why they're taught together:

### The problem enums solve

An enum says: "this value is ONE of these specific possibilities, nothing else."

```rust
enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter,
}
```

A `Coin` can ONLY be one of those four things. Not a String, not a number, not some other random variant.

### Why match is perfect for enums

**Match forces you to handle every possibility.** The compiler literally won't let you forget a case:

```rust
match coin {
    Coin::Penny => 1,
    Coin::Nickel => 5,
    // ❌ Compiler error: you forgot Dime and Quarter!
}
```

This is HUGE for safety. With enums + match, you can't accidentally forget to handle a case. No runtime surprises.

### The comparison happens automatically

```rust
match coin {                    // ← The value you're checking
    Coin::Penny => 1,          // Rust checks: is coin a Penny?
    Coin::Nickel => 5,         // If not, is it a Nickel?
    Coin::Dime => 10,          // If not, is it a Dime?
    Coin::Quarter => 25,       // If not, is it a Quarter?
}
```

Rust checks each pattern from top to bottom. First match wins, runs its code, done.

## Match executes ONLY ONE arm (no fall-through!)

**Critical point**: Unlike `switch` in C/C++/JavaScript, Rust's `match` executes **only the first matching arm** and then exits immediately. There is no "fall-through" behavior.

```rust
let x = 1;

match x {
    1 => println!("one"),      // ✅ This runs
    1 => println!("also one"), // ❌ This NEVER runs (and Rust warns: unreachable pattern)
    _ => println!("other"),
}
// Output: "one" (just once!)
```

### Comparison with C's switch (which DOES fall through)

```c
// C code - has fall-through!
switch (x) {
    case 1: printf("one\n");    // runs
    case 2: printf("two\n");    // ALSO runs! (fall-through)
    case 3: printf("three\n");  // ALSO runs!
    default: printf("other\n"); // ALSO runs!
}
// Without `break`, C executes ALL cases after the first match!
```

### Rust's match is safer by design

```rust
let x = 1;

match x {
    1 => {
        println!("one");
        println!("still in the same arm");
    }
    2 => println!("two"),   // Never reached when x=1
    _ => println!("other"), // Never reached when x=1
}
// Output:
// one
// still in the same arm
// (then match exits - no fall-through to other arms)
```

**Why this matters**: You never need to remember to add `break` statements. Each arm is isolated. When one arm matches and runs, the `match` is done.

### What if you want multiple patterns to run the same code?

Use the `|` (or) operator to combine patterns into a single arm:

```rust
let x = 1;

match x {
    1 | 2 | 3 => println!("one, two, or three"), // Matches 1, 2, OR 3
    4..=10 => println!("four through ten"),
    _ => println!("something else"),
}
```

This isn't fall-through—it's one arm with multiple patterns.

## But you can use match on other things too!

Match isn't just for enums—it works on regular types like numbers, strings, whatever:

```rust
let dice_roll = 9;  // Just a regular integer

match dice_roll {
    1 => println!("one"),
    2 => println!("two"),
    _ => println!("something else"),  // _ means "anything else"
}
// This prints: "something else"
```

Since `dice_roll` is 9, it doesn't match 1 or 2, so it falls through to the `_` catch-all pattern.

### More examples with different types:

```rust
// Match on a string
let text = "hello";
match text {
    "hello" => println!("hi there!"),
    "bye" => println!("goodbye!"),
    _ => println!("huh?"),
}

// Match on ranges
let age = 25;
match age {
    0..=12 => println!("child"),
    13..=19 => println!("teen"),
    20..=64 => println!("adult"),
    _ => println!("senior"),
}
```

The Rust book teaches match with enums because that's where it's most powerful—the compiler ensures you've covered all cases. But match is a general-purpose tool!

## The real insight

Enums define a closed set of possibilities. Match ensures you handle all of them. Together they prevent a whole class of bugs where you forget to handle a case. That's why they're taught together—they're a power couple.

## Match MUST handle all enum cases (exhaustiveness)

**When you match on an enum, you MUST handle every variant.** The compiler enforces this:

```rust
enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter,
}

// ❌ This won't compile - missing Dime and Quarter!
match coin {
    Coin::Penny => 1,
    Coin::Nickel => 5,
}
// Compiler error: "non-exhaustive patterns: `Coin::Dime` and `Coin::Quarter` not covered"
```

You have two ways to satisfy the compiler:

### Option 1: List every variant explicitly
```rust
match coin {
    Coin::Penny => 1,
    Coin::Nickel => 5,
    Coin::Dime => 10,
    Coin::Quarter => 25,
}
```

### Option 2: Use a catch-all for the rest
```rust
match coin {
    Coin::Penny => 1,
    _ => 0,  // Handles Nickel, Dime, Quarter - anything that's not Penny
}
```

**Important**: For regular types (like numbers or strings), you don't need all cases—you can just use `_` to catch everything else. But for enums, the compiler forces exhaustiveness because it knows exactly what all the possibilities are.

That's the safety feature: you can't accidentally forget to handle a case!

---

## Match returns a value (it's an expression!)

Unlike `switch` in many languages, Rust's `match` is an **expression**—it returns a value. This is incredibly useful:

```rust
let coin = Coin::Dime;

let value = match coin {
    Coin::Penny => 1,
    Coin::Nickel => 5,
    Coin::Dime => 10,
    Coin::Quarter => 25,
};

println!("Value: {} cents", value); // Value: 10 cents
```

You can use `match` directly in assignments, function returns, or anywhere you need a value:

```rust
fn describe_number(n: i32) -> &'static str {
    match n {
        0 => "zero",
        1..=9 => "single digit",
        10..=99 => "double digit",
        _ => "big number",
    }
    // No semicolon after match = it's the return value!
}
```

**Important**: All arms must return the same type!

```rust
// ❌ This won't compile - mismatched types
let result = match x {
    1 => "one",      // &str
    2 => 2,          // i32 - different type!
    _ => "other",
};
```

---

## Destructuring: Pulling data out of enums

Enums can hold data inside their variants. `match` lets you **destructure** (extract) that data:

### What is destructuring?

**Destructuring** means breaking apart a composite data structure to access its individual pieces. Think of it like unpacking a box—you take out each item and give it a name.

It's the opposite of *constructing*:
```rust
// Constructing: putting pieces together
let point = (3, 5);           // Build a tuple from two values
let user = User { name, age }; // Build a struct from fields

// Destructuring: taking pieces apart
let (x, y) = point;           // Extract values from tuple
let User { name, age } = user; // Extract fields from struct
```

**Destructuring works on:**
- Tuples
- Structs
- Enums
- Arrays and slices
- Nested combinations of all the above

### Destructuring in `match` (enums)

```rust
enum Message {
    Quit,                       // No data
    Move { x: i32, y: i32 },   // Named fields (like a struct)
    Write(String),              // Single value (tuple-like)
    ChangeColor(i32, i32, i32), // Multiple values
}

let msg = Message::Move { x: 10, y: 20 };

match msg {
    Message::Quit => println!("Quit"),
    Message::Move { x, y } => println!("Move to ({}, {})", x, y), // Extract x and y!
    Message::Write(text) => println!("Text: {}", text),           // Extract the String!
    Message::ChangeColor(r, g, b) => println!("RGB: {}, {}, {}", r, g, b),
}
// Output: Move to (10, 20)
```

### The classic example: Option<T>

`Option` is just an enum with two variants:

```rust
enum Option<T> {
    Some(T),  // Contains a value of type T
    None,     // Contains nothing
}
```

Destructuring lets you safely extract the value:

```rust
let maybe_number: Option<i32> = Some(42);

match maybe_number {
    Some(n) => println!("Got a number: {}", n), // n is now 42
    None => println!("Got nothing"),
}
```

### Result<T, E> works the same way

```rust
let result: Result<i32, &str> = Ok(100);

match result {
    Ok(value) => println!("Success: {}", value),
    Err(e) => println!("Error: {}", e),
}
```

---

## Match guards: Adding extra conditions with `if`

Sometimes patterns aren't enough. **Match guards** let you add an `if` condition:

```rust
let num = Some(4);

match num {
    Some(x) if x < 5 => println!("less than five: {}", x),
    Some(x) => println!("five or more: {}", x),
    None => println!("nothing"),
}
// Output: less than five: 4
```

The guard `if x < 5` only lets the arm match if the condition is true.

### More guard examples:

```rust
let pair = (2, -2);

match pair {
    (x, y) if x == y => println!("equal"),
    (x, y) if x + y == 0 => println!("opposites"), // This matches!
    (x, _) if x % 2 == 0 => println!("first is even"),
    _ => println!("no match"),
}
// Output: opposites
```

**Note**: Guards are checked after the pattern matches, so order matters!

---

## Binding with `@`: Name and test at the same time

The `@` operator lets you bind a value to a name while also testing it against a pattern:

```rust
enum Message {
    Hello { id: i32 },
}

let msg = Message::Hello { id: 5 };

match msg {
    Message::Hello { id: id_variable @ 3..=7 } => {
        println!("Found id in range: {}", id_variable)
    }
    Message::Hello { id: 10..=12 } => {
        println!("Found id in another range")
        // Can't use `id` here - we didn't bind it!
    }
    Message::Hello { id } => {
        println!("Found some other id: {}", id)
    }
}
// Output: Found id in range: 5
```

Without `@`, you'd have to either:
- Test the range (but not have access to the value), or
- Bind the value (but not test the range in the pattern)

`@` gives you both!

---

## Matching on references

When matching on references, you might need `ref` or `&`:

### Using `&` in the pattern

```rust
let reference = &4;

match reference {
    &val => println!("Got value: {}", val), // val is i32, not &i32
}
```

### Using `ref` to create a reference

```rust
let value = 5;

match value {
    ref r => println!("Got a reference: {:?}", r), // r is &i32
}
```

### With `ref mut` for mutable references

```rust
let mut value = 5;

match value {
    ref mut m => {
        *m += 10;
        println!("Modified to: {}", m);
    }
}
// value is now 15
```

---

## Ignoring values with `_` and `..`

### `_` ignores a single value

```rust
let point = (3, 5, 8);

match point {
    (x, _, z) => println!("x={}, z={}", x, z), // Ignore y
}
```

### `..` ignores multiple values

```rust
let numbers = (1, 2, 3, 4, 5);

match numbers {
    (first, .., last) => println!("first={}, last={}", first, last),
}
// Output: first=1, last=5
```

### Ignoring remaining struct fields

```rust
struct Point { x: i32, y: i32, z: i32 }

let origin = Point { x: 0, y: 0, z: 0 };

match origin {
    Point { x, .. } => println!("x is {}", x), // Ignore y and z
}
```

---

## `if let`: When you only care about one pattern

If you only care about one case, `if let` is cleaner than a full `match`:

```rust
let some_value = Some(3);

// Full match - verbose for just one case
match some_value {
    Some(3) => println!("three!"),
    _ => (), // Do nothing - annoying boilerplate
}

// if let - much cleaner!
if let Some(3) = some_value {
    println!("three!");
}
```

### With an else clause

```rust
let coin = Coin::Quarter;

if let Coin::Quarter = coin {
    println!("It's a quarter!");
} else {
    println!("Not a quarter");
}
```

### Destructuring works too

```rust
if let Some(value) = some_option {
    println!("Got: {}", value);
}
```

---

## `while let`: Loop while a pattern matches

Great for iterators or channels:

```rust
let mut stack = vec![1, 2, 3];

while let Some(top) = stack.pop() {
    println!("{}", top);
}
// Output: 3, 2, 1 (then loop ends when pop() returns None)
```

---

## `let else`: Handle the non-matching case

Rust 1.65+ introduced `let else` for when you want to handle the failure case:

```rust
fn get_count(s: &str) -> i32 {
    let Some(count) = s.parse::<i32>().ok() else {
        return -1; // Must diverge (return, break, panic, etc.)
    };
    count
}
```

This is particularly useful for early returns:

```rust
fn process_user(user: Option<User>) {
    let Some(user) = user else {
        println!("No user provided");
        return;
    };
    
    // Now `user` is definitely a User, not Option<User>
    println!("Processing {}", user.name);
}
```

---

## Quick reference: Match patterns cheat sheet

| Pattern | Example | What it matches |
|---------|---------|-----------------|
| Literal | `5` | Exactly 5 |
| Variable | `x` | Anything, binds to x |
| Wildcard | `_` | Anything, discards it |
| Range | `1..=5` | 1, 2, 3, 4, or 5 |
| Or | `1 \| 2 \| 3` | 1, 2, or 3 |
| Tuple | `(x, y, _)` | 3-element tuple |
| Struct | `Point { x, y }` | Point, binds fields |
| Enum | `Some(x)` | Some variant, binds inner |
| Reference | `&val` | Reference, binds inner |
| Guard | `x if x > 0` | Pattern + condition |
| Binding | `id @ 1..=5` | Range, also binds to id |
| Rest | `[first, ..]` | Slice, binds first element |