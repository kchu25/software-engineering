@def title = "Zellij: Quick Start & Comprehensive Guide for Rust Development"
@def published = "6 February 2026"
@def tags = ["devops"]

# Zellij: Quick Start & Comprehensive Guide for Rust Development

[Zellij](https://zellij.dev/) is a terminal multiplexer—it lets you split your terminal into multiple panes and tabs. If you've heard of `tmux` or `screen`, Zellij is the modern, friendlier version.

**The use case:** You're writing Rust in Vim. You want Vim in one pane and `cargo run` or `cargo build` in another—without leaving the terminal. Zellij makes this effortless.

---

## Installation

```bash
# If you have Cargo installed (you're a Rust dev, so you probably do)
cargo install --locked zellij

# Or with binstall (faster, just downloads the binary)
cargo binstall zellij
```

Verify:
```bash
zellij --version
```

---

## 30-Second Quick Start

```bash
# Start zellij
zellij

# That's it. You're in.
```

Now do this:
1. Press `Alt + n` → a new pane appears
2. Type `vim src/main.rs` in one pane
3. Click the other pane (or press `Alt + ←/→`) and run `cargo run`
4. You now have Vim + compiler side by side

**To exit:** Type `exit` in each pane, or press `Ctrl + q` to quit the whole session.

---

## The Modal System (Important!)

Zellij uses **modes**, similar to Vim. In **Normal mode**, certain key combos switch you into other modes to perform actions.

### The Modes You'll Actually Use

| Key | Mode | What it does |
|-----|------|-------------|
| `Ctrl + p` | **Pane** | Create, close, move, resize panes |
| `Ctrl + t` | **Tab** | Create, close, switch tabs |
| `Ctrl + n` | **Resize** | Resize the focused pane |
| `Ctrl + s` | **Scroll** | Scroll through pane output |
| `Ctrl + o` | **Session** | Detach, session manager |
| `Ctrl + g` | **Lock** | Lock Zellij (pass all keys to terminal) |
| `Ctrl + q` | — | Quit Zellij |

**The pattern:** Press the mode key → perform action → press `Esc` or `Enter` to go back to Normal.

> **Why Lock mode?**
>
> Some programs (like Vim) use the same key combos as Zellij. If Zellij is "eating" your `Ctrl + s` (which Vim users might use), press `Ctrl + g` to enter Lock mode. Now ALL keys go to the terminal app. Press `Ctrl + g` again to unlock.

---

## Panes: Your Daily Bread

### Creating Panes

| Action | Key |
|--------|-----|
| New pane (auto-direction) | `Alt + n` |
| New pane below | `Ctrl + p`, then `d` |
| New pane to the right | `Ctrl + p`, then `r` |
| New floating pane | `Ctrl + p`, then `w` |
| Close focused pane | `Ctrl + p`, then `x` |

### Moving Between Panes

| Action | Key |
|--------|-----|
| Focus left/right/up/down | `Alt + ←/→/↑/↓` |
| Focus left/right (or next tab at edge) | `Alt + h/l` |
| Toggle fullscreen | `Ctrl + p`, then `f` |
| Toggle floating/embedded | `Ctrl + p`, then `e` |

### Resizing Panes

Enter resize mode with `Ctrl + n`, then:

| Key | Action |
|-----|--------|
| `h` or `←` | Resize left |
| `l` or `→` | Resize right |
| `j` or `↓` | Resize down |
| `k` or `↑` | Resize up |
| `+` | Increase size |
| `-` | Decrease size |
| `Esc` | Back to normal |

---

## Tabs: Organize Your Work

| Action | Key |
|--------|-----|
| New tab | `Ctrl + t`, then `n` |
| Close tab | `Ctrl + t`, then `x` |
| Next tab | `Ctrl + t`, then `l` or `→` |
| Previous tab | `Ctrl + t`, then `h` or `←` |
| Rename tab | `Ctrl + t`, then `r` |
| Go to tab #N | `Alt + 1-9` |

### Example Tab Setup for Rust Dev

- **Tab 1 "edit"**: Vim with your source code
- **Tab 2 "run"**: Split pane — `cargo run` on top, `cargo test` on bottom
- **Tab 3 "git"**: Git operations

---

## Scrollback: Reading Compiler Output

When `cargo build` spits out a long error, you need to scroll:

1. Press `Ctrl + s` to enter **Scroll mode**
2. Use `j`/`k` or `↑`/`↓` to scroll line by line
3. Use `d`/`u` for half-page down/up
4. Press `Esc` to exit scroll mode

### Search in Scrollback

1. Press `Ctrl + s` to enter Scroll mode
2. Press `s` to enter **Search mode**
3. Type your search term and press `Enter`
4. Use `n`/`p` to go to next/previous match
5. Press `Esc` to exit

> **Editing scrollback in Vim**
>
> Press `Ctrl + s`, then `e` to open the entire scrollback buffer in your `$EDITOR`. Super useful for copying error messages. Make sure `EDITOR=vim` (or your preferred editor) is set in your shell config.

---

## Your Rust Workflow

### The Minimal Setup (What You Probably Want)

Start zellij and set up two panes:

```bash
zellij
# Now inside zellij:
# 1. You're already in a pane — open vim
vim src/main.rs

# 2. Press Alt+n to split a new pane
# 3. In the new pane, run:
cargo run
# or
cargo watch -x run  # Auto-recompile on save (needs cargo-watch)
```

### Using a Layout (Reproducible Setup)

Create a file `~/.config/zellij/layouts/rust.kdl`:

```kdl
layout {
    pane split_direction="vertical" {
        pane name="editor" focus=true {
            // This is where you'll open vim
        }
        pane split_direction="horizontal" size="40%" {
            pane name="build" command="bash" {
                args "-c" "echo 'Run: cargo build / cargo run'"
            }
            pane name="terminal"
        }
    }
}
```

Start with:
```bash
zellij --layout rust
```

This gives you:

```
┌──────────────────────┬────────────────────┐
│                      │     build          │
│       editor         │                    │
│       (vim)          ├────────────────────┤
│                      │     terminal       │
│                      │                    │
└──────────────────────┴────────────────────┘
```

### A Better Layout with Cargo Watch

If you install `cargo-watch` (`cargo install cargo-watch`), you can auto-compile on save:

```kdl
layout {
    pane split_direction="vertical" {
        pane name="editor" size="60%" focus=true
        pane split_direction="horizontal" size="40%" {
            pane name="cargo watch" command="cargo" {
                args "watch" "-x" "run"
            }
            pane name="terminal"
        }
    }
}
```

Now every time you `:w` in Vim, `cargo watch` detects the change and recompiles automatically.

---

## Sessions: Detach and Reattach

One of Zellij's best features—your entire workspace persists even if you close the terminal.

| Action | Command/Key |
|--------|------------|
| Detach from session | `Ctrl + o`, then `d` |
| List all sessions | `zellij ls` |
| Attach to a session | `zellij attach <name>` |
| Attach to last session | `zellij a` |
| Start a named session | `zellij -s my-project` |
| Kill a session | `zellij kill-session <name>` |
| Kill all sessions | `zellij kill-all-sessions` |
| Session manager (in Zellij) | `Ctrl + o`, then `w` |

### Workflow Example

```bash
# Start a named session for your project
zellij -s my-rust-app

# Set up your panes, start coding...
# Need to leave? Detach:
# Press Ctrl+o, then d

# Come back later:
zellij attach my-rust-app
# Everything is exactly where you left it!
```

---

## Floating Panes

Need a quick terminal without disrupting your layout?

| Action | Key |
|--------|-----|
| Toggle floating panes | `Ctrl + p`, then `w` |
| New floating pane | (with floating visible) `Alt + n` |
| Float/embed toggle | `Ctrl + p`, then `e` |

Great for quick one-off commands like `cargo add serde` without messing up your Vim + compiler layout.

---

## Configuration

Zellij config lives at `~/.config/zellij/config.kdl`.

Dump the default config to see all options:

```bash
zellij setup --dump-config > ~/.config/zellij/config.kdl
```

### Useful Config Tweaks

```kdl
// ~/.config/zellij/config.kdl

// Use compact layout by default (less UI chrome)
default_layout "compact"

// Remove pane frames for more space
pane_frames false

// Set your preferred shell
default_shell "zsh"

// Scrollback buffer size (default is 10000)
scroll_buffer_size 50000

// Copy to clipboard command (Linux/Wayland)
copy_command "wl-copy"
// or for X11:
// copy_command "xclip -selection clipboard"
```

### The Compact Layout

If Zellij's status bar takes up too much space:

```bash
zellij --layout compact
```

This gives you a slim tab bar at the top and removes the bottom help bar.

---

## CLI Shortcuts (Handy!)

Zellij provides shell aliases when you add completions:

```bash
# Generate completions for your shell
zellij setup --generate-completion zsh >> ~/.zshrc
# Then source or restart your shell
```

Now you get:

```bash
zr cargo run          # Open a new pane running "cargo run"
zrf htop              # Open a new FLOATING pane with htop
ze src/main.rs        # Open a new pane editing the file in $EDITOR
```

---

## Keybinding Cheat Sheet

### Normal Mode (Default)

| Key | Action |
|-----|--------|
| `Alt + n` | New pane |
| `Alt + ←/→/↑/↓` | Move focus between panes |
| `Alt + h/j/k/l` | Move focus (vim-style) |
| `Alt + 1-9` | Go to tab #N |
| `Alt + +/-` | Resize pane |

### After `Ctrl + p` (Pane Mode)

| Key | Action |
|-----|--------|
| `d` | New pane down |
| `r` | New pane right |
| `x` | Close pane |
| `f` | Toggle fullscreen |
| `w` | Toggle floating panes |
| `e` | Toggle float/embed |
| `z` | Toggle pane frames |
| `c` | Rename pane |
| `h/j/k/l` | Move focus |

### After `Ctrl + t` (Tab Mode)

| Key | Action |
|-----|--------|
| `n` | New tab |
| `x` | Close tab |
| `r` | Rename tab |
| `h/l` or `←/→` | Previous/next tab |
| `s` | Toggle sync (type in all panes) |

### After `Ctrl + s` (Scroll Mode)

| Key | Action |
|-----|--------|
| `j/k` | Scroll down/up |
| `d/u` | Half page down/up |
| `s` | Enter search mode |
| `e` | Edit scrollback in `$EDITOR` |

### After `Ctrl + o` (Session Mode)

| Key | Action |
|-----|--------|
| `d` | Detach |
| `w` | Session manager |

---

## Tips for Vim + Rust Users

### 1. Set Your Editor

Make sure your `.zshrc` has:
```bash
export EDITOR=vim
# or: export EDITOR=nvim
```

This enables the `ze` alias and `Ctrl + s → e` scrollback editing.

### 2. Use Lock Mode When Needed

If Zellij intercepts a key combo you need in Vim:
- `Ctrl + g` → Lock mode (all keys pass through to Vim)
- `Ctrl + g` again → back to Normal

### 3. The "I Just Want Two Panes" Workflow

```bash
zellij -s rust-dev       # Named session
# Alt+n                  # Split a pane
# Left pane: vim         # Right pane: cargo run
# Alt+←/→ to switch
# Ctrl+o, d to detach    # Come back anytime with: zellij a rust-dev
```

### 4. Watch Mode = Best Friend

```bash
# In your compiler pane:
cargo watch -x check        # Fast type checking on save
cargo watch -x 'test -- --nocapture'  # Auto-run tests
cargo watch -x run          # Auto-run program
```

Every `:w` in Vim triggers a recompile in the other pane.

### 5. Sync Mode for Debugging

Need to type the same command in multiple panes? `Ctrl + t`, then `s` toggles sync. Everything you type goes to all panes in the tab.

---

## Quick Reference Card

```
   PANES                TABS               SCROLL          SESSION
   Ctrl+p               Ctrl+t             Ctrl+s          Ctrl+o
   ───────              ──────             ──────          ───────
   d = down             n = new            j/k = line      d = detach
   r = right            x = close          d/u = page      w = manager
   x = close            r = rename         s = search
   f = fullscreen       h/l = switch       e = edit
   w = float
   e = embed

   QUICK KEYS (Normal mode)
   ────────────────────────
   Alt+n        = new pane
   Alt+←/→/↑/↓  = move focus
   Alt+1-9      = go to tab
   Ctrl+g       = lock (pass keys through)
   Ctrl+q       = quit
```
