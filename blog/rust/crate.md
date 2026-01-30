@def title = "Rust Packages and Crates: Untangled"
@def published = "30 January 2026"
@def tags = ["rust"]

# Rust Packages and Crates: Untangled

The official Rust book introduces three concepts at once—crates, packages, and modules—which can feel overwhelming. Let's untangle them one layer at a time.

---

## The Big Picture

```
Package (has Cargo.toml)
├── Crate (binary) ← compiled to executable
├── Crate (library) ← compiled to shareable code
└── Crate (binary) ← you can have multiple binaries
```

Think of it like this:
- **Crate** = a unit of compilation (what `rustc` compiles)
- **Package** = a bundle of crates managed by Cargo (has `Cargo.toml`)
- **Module** = organization within a crate (we'll cover this separately)

---

## What is a Crate?

A **crate** is the smallest unit of code the Rust compiler deals with. When you run `rustc` on a file, that file is a crate.

### Two Kinds of Crates

| Type | Has `main`? | Compiles to | Example |
|------|-------------|-------------|---------|
| **Binary crate** | Yes | Executable you can run | CLI tool, server, game |
| **Library crate** | No | Code others can use | `rand`, `serde`, `tokio` |

```rust
// Binary crate - has main(), runs as a program
fn main() {
    println!("I'm an executable!");
}

// Library crate - no main(), provides functionality
pub fn useful_function() {
    // Other code can call this
}
```

> **"Crate" usually means library**
> 
> When Rustaceans say "I'm using the `serde` crate," they mean library crate. It's interchangeable with "library" in casual conversation.

### The Crate Root

Every crate has a **root file**—the starting point for compilation:

| Crate type | Root file |
|------------|-----------|
| Binary | `src/main.rs` |
| Library | `src/lib.rs` |

The compiler starts at the root and follows all the `mod` declarations to find the rest of your code.

---

## What is a Package?

A **package** is what you create when you run `cargo new`. It's a directory with:
- A `Cargo.toml` file (the manifest)
- One or more crates

> **What's a manifest?**
>
> A **manifest** is a file that describes your project's metadata and configuration. In Rust, it's `Cargo.toml`. It tells Cargo:
> - What your package is called
> - What version it is
> - What dependencies it needs
> - How to build it
>
> Think of it like a shipping label + packing list for your code. The name comes from shipping terminology—a ship's manifest lists everything on board.

```bash
$ cargo new my-project
     Created binary (application) `my-project` package

$ tree my-project
my-project
├── Cargo.toml    ← Package manifest
└── src
    └── main.rs   ← Binary crate root
```

### Package Rules

1. **At least one crate** (binary or library)
2. **At most one library crate** (you can only have one `src/lib.rs`)
3. **Any number of binary crates** (multiple executables are fine)

---

## Package Configurations

### Binary Only (most common for applications)

```
my-app/
├── Cargo.toml
└── src/
    └── main.rs      ← Binary crate "my-app"
```

This is what `cargo new my-app` creates.

### Library Only (for sharing code)

```
my-lib/
├── Cargo.toml
└── src/
    └── lib.rs       ← Library crate "my-lib"
```

This is what `cargo new my-lib --lib` creates.

### Both Binary and Library

```
my-project/
├── Cargo.toml
└── src/
    ├── main.rs      ← Binary crate "my-project"
    └── lib.rs       ← Library crate "my-project"
```

The binary can use the library:

```rust
// src/main.rs
use my_project::useful_function;  // Import from the library crate

fn main() {
    useful_function();
}
```

```rust
// src/lib.rs
pub fn useful_function() {
    println!("Called from the library!");
}
```

### Multiple Binaries

```
my-project/
├── Cargo.toml
└── src/
    ├── main.rs          ← Binary "my-project"
    ├── lib.rs           ← Library "my-project"
    └── bin/
        ├── tool1.rs     ← Binary "tool1"
        └── tool2.rs     ← Binary "tool2"
```

Run them with:
```bash
cargo run --bin my-project
cargo run --bin tool1
cargo run --bin tool2
```

---

## Convention Over Configuration

Cargo uses **file location** to determine crate structure. You don't need to specify these in `Cargo.toml`:

| File exists | Cargo assumes |
|-------------|---------------|
| `src/main.rs` | Binary crate with package name |
| `src/lib.rs` | Library crate with package name |
| `src/bin/foo.rs` | Additional binary crate named "foo" |

This is why `Cargo.toml` often has no explicit crate configuration—Cargo just looks at your file structure.

---

## Why Separate Binary and Library?

A common pattern: put your logic in a library crate, and keep `main.rs` thin.

**Benefits:**
- Library can be tested independently
- Library can be used by other projects
- Binary is just a thin wrapper that calls library functions

```rust
// src/lib.rs - All the real logic
pub fn run_app(args: Vec<String>) -> Result<(), String> {
    // Complex logic here
    Ok(())
}

// src/main.rs - Just the entry point
fn main() {
    let args: Vec<String> = std::env::args().collect();
    if let Err(e) = my_project::run_app(args) {
        eprintln!("Error: {}", e);
        std::process::exit(1);
    }
}
```

---

## Quick Reference

| Term | What it is | Example |
|------|------------|---------|
| **Crate** | Compilation unit | `rand`, your `main.rs` |
| **Binary crate** | Compiles to executable | CLI app, server |
| **Library crate** | Compiles to reusable code | `serde`, `tokio` |
| **Crate root** | Entry point for compiler | `src/main.rs`, `src/lib.rs` |
| **Package** | Bundle of crates + `Cargo.toml` | What `cargo new` creates |

---

## Mental Model

```
┌─────────────────────────────────────────┐
│  Package (Cargo.toml)                   │
│  "A project managed by Cargo"           │
│                                         │
│  ┌──────────────┐  ┌──────────────┐    │
│  │ Binary Crate │  │ Library Crate│    │
│  │ (main.rs)    │  │ (lib.rs)     │    │
│  │              │  │              │    │
│  │ → Executable │  │ → .rlib file │    │
│  └──────────────┘  └──────────────┘    │
│                                         │
│  ┌──────────────┐  ┌──────────────┐    │
│  │ Binary Crate │  │ Binary Crate │    │
│  │ (bin/a.rs)   │  │ (bin/b.rs)   │    │
│  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────┘
```

**Next up:** Modules—how to organize code *within* a crate.
