@def title = "Rust Modules: Organizing Your Code"
@def published = "30 January 2026"
@def tags = ["rust"]

# Rust Modules: Organizing Your Code

Modules are how you organize code **within** a crate. Think of them like folders for your code—they group related things together and control what's visible to the outside world.

---

## The Quick Version

| Concept | What it does |
|---------|--------------|
| `mod foo` | Declares a module named `foo` |
| `pub` | Makes something public (visible outside its module) |
| `use` | Creates a shortcut to avoid typing long paths |
| `crate::` | Path starting from the crate root |
| `self::` | Path starting from current module |
| `super::` | Path starting from parent module |

---

## Why Does Rust Require `mod` Declarations?

In many languages, files are automatically modules—if a file exists, you can import it. Rust is different: **you must explicitly declare every module**.

Why this design?

1. **Explicit is better than implicit.** The crate root (`lib.rs` or `main.rs`) is a table of contents. You can see exactly what modules exist without scanning the filesystem.

2. **Files aren't automatically code.** You might have `.rs` files that are templates, build artifacts, or temporarily disabled. Rust won't accidentally compile them.

3. **The module tree is independent of the file tree.** You can reorganize files without changing your public API (using `pub use` to re-export).

4. **Conditional compilation.** You can do `#[cfg(feature = "foo")] mod foo;` to include modules only when certain features are enabled.

```rust
// src/lib.rs — This is your table of contents
mod database;      // ✅ Compiled
mod api;           // ✅ Compiled
// mod experiments; // Commented out = not compiled, even if file exists
```

> **Coming from Python/JavaScript?**
>
> In Python, `import foo` automatically finds `foo.py`. In JS, `import` finds the file.
>
> In Rust, it's two steps:
> 1. `mod foo;` — "This module exists, load it from `foo.rs`"
> 2. `use foo::bar;` — "Bring `bar` into scope"
>
> The `mod` is the declaration; `use` is just a convenience shortcut.

---

## How Modules Work: The Rules

### Rule 1: Everything Starts at the Crate Root

The compiler starts at:
- `src/main.rs` for binary crates
- `src/lib.rs` for library crates

This file is the **crate root**, and it implicitly creates a module called `crate`.

### Rule 2: Declare Modules with `mod`

In the crate root, you declare modules:

```rust
// src/lib.rs or src/main.rs
mod garden;  // Declares a module named "garden"
```

The compiler then looks for the module's code in this order:
1. **Inline** — code inside curly braces: `mod garden { ... }`
2. **File** — `src/garden.rs`
3. **Folder** — `src/garden/mod.rs` (older style)

> **Semicolon vs Curly Braces: Where's the Code?**
>
> The punctuation after `mod garden` tells Rust where to find the module's code:
>
> | Syntax | Meaning |
> |--------|---------|
> | `mod garden;` | "Go find code in `src/garden.rs`" |
> | `mod garden { ... }` | "The code is right here, inline" |
>
> ```rust
> // Semicolon = external file
> mod garden;  // Rust looks for src/garden.rs
>
> // Curly braces = inline
> mod garden {
>     pub fn grow() { }  // Code lives right here
> }
> ```
>
> You can't do both—it's one or the other.

### Rule 3: Submodules Work the Same Way

Inside `src/garden.rs`, you can declare submodules:

```rust
// src/garden.rs
mod vegetables;  // Declares a submodule
```

The compiler looks for:
1. **Inline** — `mod vegetables { ... }`
2. **File** — `src/garden/vegetables.rs`
3. **Folder** — `src/garden/vegetables/mod.rs`

> **Module vs Submodule: It's About Where You Declare It**
>
> There's no special syntax for submodules—it's always just `mod foo;`. The term "submodule" simply means "a module declared inside another module."
>
> ```rust
> // src/lib.rs (crate root)
> mod garden;     // garden is a MODULE (child of crate)
>
> // src/garden.rs
> mod vegetables; // vegetables is a SUBMODULE (child of garden)
>
> // src/garden/vegetables.rs
> mod tomato;     // tomato is a SUBMODULE of vegetables
> ```
>
> This creates a tree:
> ```
> crate              ← root
> └── garden         ← module (declared in lib.rs)
>     └── vegetables ← submodule (declared in garden.rs)
>         └── tomato ← sub-submodule (declared in vegetables.rs)
> ```
>
> The **nesting** determines the relationship—a module declared inside another module becomes its child.

### Rule 4: Everything is Private by Default

Code in a module is **private** to its parent. To expose it, use `pub`:

```rust
pub mod garden;        // Public module
pub fn grow() { }      // Public function
pub struct Plant { }   // Public struct
```

---

## A Complete Example

Let's build a project called `backyard`:

```
backyard/
├── Cargo.toml
└── src/
    ├── main.rs              ← Crate root
    ├── garden.rs            ← garden module
    └── garden/
        └── vegetables.rs    ← garden::vegetables submodule
```

### The Code

```rust
// src/main.rs (crate root)
use crate::garden::vegetables::Asparagus;

pub mod garden;  // "Include the garden module"

fn main() {
    let plant = Asparagus {};
    println!("Growing {:?}", plant);
}
```

```rust
// src/garden.rs
pub mod vegetables;  // "Include the vegetables submodule"
```

```rust
// src/garden/vegetables.rs
#[derive(Debug)]
pub struct Asparagus {}
```

### The Module Tree

This creates the following structure:

```
crate                         (src/main.rs)
└── garden                    (src/garden.rs)
    └── vegetables            (src/garden/vegetables.rs)
        └── Asparagus         (the struct)
```

The full path to `Asparagus` is: `crate::garden::vegetables::Asparagus`

---

## Inline Modules (All in One File)

You don't *need* separate files. For smaller projects, inline modules work fine:

```rust
// src/lib.rs - everything in one file
mod front_of_house {
    pub mod hosting {
        pub fn add_to_waitlist() {}
        pub fn seat_at_table() {}
    }

    mod serving {  // Private module
        fn take_order() {}
        fn serve_order() {}
    }
}

pub fn eat_at_restaurant() {
    // Use absolute path
    crate::front_of_house::hosting::add_to_waitlist();
    
    // Or relative path
    front_of_house::hosting::seat_at_table();
}
```

This creates:

```
crate
└── front_of_house
    ├── hosting
    │   ├── add_to_waitlist  (pub)
    │   └── seat_at_table    (pub)
    └── serving              (private!)
        ├── take_order
        └── serve_order
```

---

## File Organization: Two Styles

Rust supports two ways to organize module files:

### Modern Style (Recommended)

```
src/
├── lib.rs
├── garden.rs           ← mod garden
└── garden/
    └── vegetables.rs   ← mod garden::vegetables
```

### Older Style (Still Works)

```
src/
├── lib.rs
└── garden/
    ├── mod.rs          ← mod garden (note: mod.rs, not garden.rs)
    └── vegetables.rs   ← mod garden::vegetables
```

> **Which should I use?**
>
> Use the modern style (`garden.rs` + `garden/` folder). The older `mod.rs` style clutters your editor with many files named `mod.rs`, making it hard to tell them apart.

---

## Privacy: What Can See What?

### The Default: Private

```rust
mod outer {
    fn private_fn() {}      // Only visible inside `outer`
    
    mod inner {
        fn also_private() {}  // Only visible inside `inner`
    }
}

// private_fn();  // ❌ Error! Can't access from outside
```

### Making Things Public

```rust
mod outer {
    pub fn public_fn() {}   // Visible to parent and beyond
    
    pub mod inner {         // Module itself is public
        pub fn inner_public() {}  // Function is also public
    }
}

outer::public_fn();           // ✅ Works
outer::inner::inner_public(); // ✅ Works
```

### The Gotcha: `pub mod` Isn't Enough

Making a module public doesn't make its contents public:

```rust
pub mod kitchen {
    fn secret_recipe() {}     // Still private!
    pub fn menu() {}          // This one is public
}

kitchen::menu();           // ✅ Works
// kitchen::secret_recipe();  // ❌ Still private!
```

You need `pub` on **both** the module and the items inside.

---

## The `use` Keyword: Creating Shortcuts

Typing full paths gets tedious:

```rust
fn main() {
    crate::garden::vegetables::Asparagus::new();
    crate::garden::vegetables::Asparagus::grow();
    crate::garden::vegetables::Asparagus::harvest();
}
```

Use `use` to create shortcuts:

```rust
use crate::garden::vegetables::Asparagus;

fn main() {
    Asparagus::new();
    Asparagus::grow();
    Asparagus::harvest();
}
```

### Common `use` Patterns

```rust
// Bring in a specific item
use std::collections::HashMap;

// Bring in multiple items from same module
use std::collections::{HashMap, HashSet, BTreeMap};

// Bring in everything (use sparingly!)
use std::collections::*;

// Rename to avoid conflicts
use std::fmt::Result;
use std::io::Result as IoResult;
```

### Idiomatic `use` Conventions

**For functions**: bring in the parent module, not the function itself

```rust
// ✅ Idiomatic - clear where `add_to_waitlist` comes from
use crate::front_of_house::hosting;
hosting::add_to_waitlist();

// ❌ Less clear - where does this function come from?
use crate::front_of_house::hosting::add_to_waitlist;
add_to_waitlist();
```

**For structs and enums**: bring in the full path

```rust
// ✅ Idiomatic
use std::collections::HashMap;
let map = HashMap::new();
```

---

## Path Types: `crate`, `self`, `super`

### `crate::` — Absolute Path from Root

```rust
// Always starts from the crate root
crate::garden::vegetables::Asparagus
```

Like an absolute file path: `/home/user/documents/file.txt`

### `self::` — Relative to Current Module

```rust
mod foo {
    pub fn bar() {}
    
    pub fn baz() {
        self::bar();  // Same as just `bar()`
    }
}
```

Like `./` in file paths.

### `super::` — Go Up to Parent Module

```rust
mod parent {
    pub fn parent_fn() {}
    
    mod child {
        pub fn child_fn() {
            super::parent_fn();  // Call function in parent module
        }
    }
}
```

Like `../` in file paths.

---

## Re-exporting with `pub use`

Sometimes you want to expose an item at a different path:

```rust
// src/lib.rs
mod garden {
    pub mod vegetables {
        pub struct Asparagus {}
    }
}

// Re-export at the crate root
pub use garden::vegetables::Asparagus;

// Now users can do:
//   use my_crate::Asparagus;
// Instead of:
//   use my_crate::garden::vegetables::Asparagus;
```

This is how libraries provide clean public APIs while keeping complex internal structure.

---

## Quick Reference

| Syntax | Meaning |
|--------|---------|
| `mod foo;` | Declare module, look for `foo.rs` or `foo/mod.rs` |
| `mod foo { }` | Declare inline module |
| `pub mod foo;` | Declare public module |
| `pub fn bar()` | Public function |
| `use path::to::Item;` | Import `Item` into scope |
| `pub use path::to::Item;` | Import AND re-export |
| `crate::path` | Absolute path from crate root |
| `self::path` | Relative path from current module |
| `super::path` | Relative path from parent module |

---

## Mental Model: Modules are Like Folders

```
File System                    Rust Modules
-----------                    ------------
/                              crate
├── garden/                    mod garden
│   └── vegetables/            mod vegetables  
│       └── asparagus.txt      pub struct Asparagus
└── tools/                     mod tools
    └── shovel.txt             pub struct Shovel

Path: /garden/vegetables/      Path: crate::garden::vegetables::
```

The key differences:
- **Privacy**: Files are usually readable; modules are private by default
- **Declaration**: You must declare modules with `mod`; folders just exist
- **The root is `crate`**, not `/`

---

## Common Mistakes

### Mistake 1: Forgetting to Declare the Module

```rust
// src/lib.rs
use crate::garden::Tomato;  // ❌ Error!

// You forgot:
mod garden;  // Must declare the module first!
```

### Mistake 2: Public Module, Private Contents

```rust
pub mod kitchen {
    struct Oven {}  // Still private!
}

// kitchen::Oven  // ❌ Error! Oven isn't pub
```

### Mistake 3: Wrong File Location

```rust
// src/lib.rs
mod garden;
mod garden::vegetables;  // ❌ Wrong! This isn't valid syntax
```

Submodules are declared inside their parent:

```rust
// src/lib.rs
mod garden;

// src/garden.rs
pub mod vegetables;  // ✅ Declare submodule here
```
