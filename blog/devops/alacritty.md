@def title = "Alacritty: Quick Start & Comprehensive Guide"
@def published = "6 February 2026"
@def tags = ["devops"]

# Alacritty: Quick Start & Comprehensive Guide

[Alacritty](https://alacritty.org/) is a GPU-accelerated terminal emulator. It's fast, minimal, and configured entirely through a single TOML file—no menus, no tabs, no splits, just a blazing-fast terminal.

**Why Alacritty?** If your terminal feels sluggish when scrolling through long `cargo build` output or `cat`-ing large files, Alacritty fixes that. It uses your GPU to render text, making it noticeably snappier than most terminals.

---

## Why Use Alacritty?

| Feature | Why it matters |
|---------|---------------|
| **GPU-accelerated rendering** | Scrolling through compiler output is instant |
| **Minimal by design** | No built-in tabs or splits—pair it with Zellij/tmux |
| **TOML config** | Version-control your entire terminal setup |
| **Live config reload** | Change fonts/colors and see results immediately |
| **Vi mode** | Navigate and select text with Vim keybindings |
| **Cross-platform** | Linux, macOS, Windows, BSD |
| **Low latency** | Noticeable when typing fast in Vim |

> **"No tabs? No splits?"**
>
> That's intentional. Alacritty does ONE thing—render a terminal—and does it extremely well. For tabs and splits, use a terminal multiplexer like [Zellij](/blog/devops/zellij/) or tmux. This is the Unix philosophy: each tool does one thing well, and you compose them together.

---

## Installation

### Ubuntu/Debian

```bash
# Install dependencies
sudo apt install cmake g++ pkg-config libfontconfig1-dev \
    libxcb-xfixes0-dev libxkbcommon-dev python3

# Install via Cargo
cargo install alacritty
```

### Arch Linux

```bash
sudo pacman -S alacritty
```

### Fedora

```bash
sudo dnf install alacritty
```

### macOS

Download the `.dmg` from [the releases page](https://github.com/alacritty/alacritty/releases), or:

```bash
brew install --cask alacritty
```

### From Cargo (any platform)

```bash
cargo install alacritty

# Or faster with binstall (just downloads the binary)
cargo binstall alacritty
```

### Post-Install: Terminfo

Make sure the terminfo entry is installed (fixes potential display issues):

```bash
# Check if it's already installed
infocmp alacritty

# If not, install it (from the cloned repo)
sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
```

---

## Setting Alacritty as Default Terminal

### On Linux (GNOME/Ubuntu)

```bash
# Set as default terminal application
sudo update-alternatives --install /usr/bin/x-terminal-emulator \
    x-terminal-emulator /usr/local/bin/alacritty 50

# Choose it as default
sudo update-alternatives --config x-terminal-emulator
# Select the number for alacritty

# Also set it for GNOME specifically
gsettings set org.gnome.desktop.default-applications.terminal exec 'alacritty'
```

**To switch back:**

```bash
# Choose a different terminal
sudo update-alternatives --config x-terminal-emulator
# Select gnome-terminal or your previous default

# Reset GNOME setting
gsettings set org.gnome.desktop.default-applications.terminal exec 'gnome-terminal'
```

### On Linux (KDE Plasma)

System Settings → Applications → Default Applications → Terminal Emulator → set to `alacritty`.

To switch back: same path, choose `konsole`.

### On Linux (i3/Sway/Other WMs)

In your window manager config, change the terminal binding:

```bash
# i3 config (~/.config/i3/config)
bindsym $mod+Return exec alacritty

# To switch back:
# bindsym $mod+Return exec gnome-terminal
```

### On macOS

macOS doesn't have a system-wide "default terminal" setting. Instead:
- Use Spotlight (`Cmd + Space`) and type "Alacritty"
- Or add it to your Dock
- To switch back, just launch Terminal.app or iTerm2 instead

### Verify It's Working

```bash
echo $TERM
# Should output: alacritty
```

---

## Configuration

Alacritty uses a single TOML file. **It doesn't create one by default**—you need to make it yourself.

### Config File Location

```bash
# Create the config directory and file
mkdir -p ~/.config/alacritty
touch ~/.config/alacritty/alacritty.toml
```

Alacritty looks for the config in this order:
1. `$XDG_CONFIG_HOME/alacritty/alacritty.toml`
2. `~/.config/alacritty/alacritty.toml`
3. `~/.alacritty.toml`

### Live Reload

Alacritty watches your config file and **reloads changes instantly**. No need to restart—just save and see.

---

## Essential Configuration

### Font

```toml
[font]
size = 13.0

[font.normal]
family = "JetBrains Mono"
style = "Regular"

[font.bold]
style = "Bold"

[font.italic]
style = "Italic"

# Adjust line spacing (positive = more space)
[font.offset]
x = 0
y = 2
```

> **Recommended fonts for coding:**
> - [JetBrains Mono](https://www.jetbrains.com/lp/mono/)
> - [Fira Code](https://github.com/tonsky/FiraCode)
> - [Hack](https://sourcefoundry.org/hack/)
> - Any [Nerd Font](https://www.nerdfonts.com/) variant (needed for icons in tools like starship, lsd, etc.)

### Window

```toml
[window]
# Padding around the terminal content (in pixels)
padding = { x = 8, y = 8 }
dynamic_padding = true

# Transparency (0.0 = fully transparent, 1.0 = opaque)
opacity = 0.95

# Start maximized
startup_mode = "Maximized"

# Window decorations
decorations = "Full"  # "Full" | "None" | "Transparent" (macOS) | "Buttonless" (macOS)
```

### Scrollback

```toml
[scrolling]
# How many lines to keep in scrollback buffer (max 100000)
history = 50000

# Lines scrolled per scroll wheel tick
multiplier = 3
```

### Shell

```toml
[terminal]
shell = { program = "/bin/zsh", args = ["-l"] }
```

### Cursor

```toml
[cursor.style]
shape = "Block"       # "Block" | "Underline" | "Beam"
blinking = "On"       # "Never" | "Off" | "On" | "Always"

[cursor]
blink_interval = 750   # milliseconds
unfocused_hollow = true # Show hollow cursor when window not focused
```

### Mouse

```toml
[mouse]
hide_when_typing = true
```

---

## Themes (Color Schemes)

Alacritty has an official [theme collection](https://github.com/alacritty/alacritty-theme) with 200+ themes.

### Quick Setup

```bash
# Clone the theme collection
mkdir -p ~/.config/alacritty/themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
```

Then import a theme in your config:

```toml
# ~/.config/alacritty/alacritty.toml
[general]
import = [
    "~/.config/alacritty/themes/themes/gruvbox_dark.toml"
]
```

### Popular Themes

| Theme | File name |
|-------|-----------|
| Gruvbox Dark | `gruvbox_dark.toml` |
| Dracula | `dracula.toml` |
| Catppuccin Mocha | `catppuccin_mocha.toml` |
| Tokyo Night | `tokyo_night.toml` |
| Nord | `nord.toml` |
| Solarized Dark | `solarized_dark.toml` |
| Rose Pine | `rose_pine.toml` |
| One Dark | `one_dark.toml` |
| Everforest Dark | `everforest_dark.toml` |

**Switching themes is instant** thanks to live reload—just change the import path and save.

### Manual Color Configuration

If you want to tweak colors yourself:

```toml
[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.normal]
black   = "#45475a"
red     = "#f38ba8"
green   = "#a6e3a1"
yellow  = "#f9e2af"
blue    = "#89b4fa"
magenta = "#f5c2e7"
cyan    = "#94e2d5"
white   = "#bac2de"

[colors.bright]
black   = "#585b70"
red     = "#f38ba8"
green   = "#a6e3a1"
yellow  = "#f9e2af"
blue    = "#89b4fa"
magenta = "#f5c2e7"
cyan    = "#94e2d5"
white   = "#a6adc8"
```

---

## Vi Mode

Alacritty has a built-in Vi mode for keyboard-driven navigation and selection. No mouse needed.

### Enter/Exit Vi Mode

| Action | Key |
|--------|-----|
| Toggle Vi mode | `Ctrl + Shift + Space` |
| Exit Vi mode | `Escape` or `i` |

### Navigation (in Vi mode)

| Key | Action |
|-----|--------|
| `h/j/k/l` | Move left/down/up/right |
| `w/b` | Jump word forward/backward |
| `0` / `$` | Start/end of line |
| `gg` / `G` | Top/bottom of scrollback |
| `H/M/L` | Top/middle/bottom of screen |
| `Ctrl+u/d` | Half-page up/down |
| `{` / `}` | Paragraph up/down |

### Selection (in Vi mode)

| Key | Action |
|-----|--------|
| `v` | Start character selection |
| `Shift + v` | Start line selection |
| `Ctrl + v` | Start block selection |
| `Alt + v` | Start semantic (word) selection |
| `y` | Copy selection to clipboard |
| `Escape` | Cancel selection |

This is incredibly powerful—select and copy text entirely with the keyboard.

---

## Search

### Normal Search

| Key | Action |
|-----|--------|
| `Ctrl + Shift + f` | Search forward |
| `Ctrl + Shift + b` | Search backward |
| `Enter` | Next match |
| `Shift + Enter` | Previous match |
| `Escape` | Exit search (keeps selection) |

### Vi Mode Search

| Key | Action |
|-----|--------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next match |
| `N` | Previous match |

---

## Hints (Clickable URLs and More)

Alacritty can detect URLs and other patterns in terminal output and let you open them.

**Default behavior:**
- URLs are underlined when you hover over them
- `Ctrl + Shift + o` opens hints for clickable links
- Click on a URL to open it in your browser

### Custom Hints

You can add custom regex patterns that link to programs:

```toml
[[hints.enabled]]
# Make file paths clickable → opens in vim
regex = "[/~][\\w./-]+"
command = { program = "vim" }
post_processing = true
binding = { key = "F", mods = "Control|Shift" }
mouse = { mods = "Control", enabled = true }
```

---

## Keyboard Shortcuts

### Essential Default Keybindings

| Key | Action |
|-----|--------|
| `Ctrl + Shift + c` | Copy |
| `Ctrl + Shift + v` | Paste |
| `Ctrl + Shift + Space` | Toggle Vi mode |
| `Ctrl + Shift + f` | Search forward |
| `Ctrl + Shift + b` | Search backward |
| `Ctrl + Shift + o` | Open hint links |
| `Ctrl + Shift + n` | New window (same instance) |
| `Ctrl + =` | Increase font size |
| `Ctrl + -` | Decrease font size |
| `Ctrl + 0` | Reset font size |
| `Ctrl + Shift + F11` | Toggle fullscreen |

### Custom Keybindings

```toml
[keyboard]
bindings = [
    # Open a new Alacritty window
    { key = "N", mods = "Control|Shift", action = "CreateNewWindow" },

    # Quick clear terminal
    { key = "K", mods = "Control|Shift", action = "ClearHistory" },

    # Toggle fullscreen
    { key = "Return", mods = "Control|Shift", action = "ToggleFullscreen" },
]
```

---

## Multi-Window

Alacritty can run multiple windows from a single process (saving resources):

```bash
# From another terminal or script:
alacritty msg create-window

# Or use the keybinding:
# Ctrl + Shift + n
```

---

## Productivity Hacks

### 1. Split Your Config Into Multiple Files

Keep your config organized using imports:

```toml
# ~/.config/alacritty/alacritty.toml
[general]
import = [
    "~/.config/alacritty/themes/themes/catppuccin_mocha.toml",
    "~/.config/alacritty/font.toml",
    "~/.config/alacritty/keybindings.toml",
]
```

```toml
# ~/.config/alacritty/font.toml
[font]
size = 13.0
[font.normal]
family = "JetBrains Mono Nerd Font"
```

```toml
# ~/.config/alacritty/keybindings.toml
[keyboard]
bindings = [
    { key = "N", mods = "Control|Shift", action = "CreateNewWindow" },
]
```

### 2. Quick Theme Switching Script

```bash
#!/bin/bash
# ~/.local/bin/alacritty-theme
# Usage: alacritty-theme gruvbox_dark

THEME="$1"
CONF="$HOME/.config/alacritty/alacritty.toml"
sed -i "s|themes/.*\.toml|themes/${THEME}.toml|" "$CONF"
echo "Switched to: $THEME"
```

Since Alacritty live-reloads, the theme changes instantly:

```bash
alacritty-theme dracula
alacritty-theme nord
alacritty-theme catppuccin_mocha
```

### 3. Environment Variables

Pass environment variables to programs inside Alacritty:

```toml
[env]
TERM = "alacritty"
EDITOR = "vim"
```

### 4. Pair with Zellij for the Ultimate Setup

Alacritty handles rendering fast. Zellij handles panes and tabs. Together, they're the perfect Rust dev environment:

```bash
# Auto-start Zellij inside Alacritty
# Add to your ~/.zshrc:
if [[ -z "$ZELLIJ" ]]; then
    zellij attach -c default
fi
```

Or configure Alacritty to launch Zellij directly:

```toml
[terminal]
shell = { program = "/usr/bin/zellij", args = ["attach", "-c", "default"] }
```

### 5. Font Size Per Monitor

If you use multiple monitors with different DPIs, you can launch Alacritty with different configs:

```bash
alias alacritty-laptop="alacritty --config-file ~/.config/alacritty/laptop.toml"
alias alacritty-monitor="alacritty --config-file ~/.config/alacritty/monitor.toml"
```

### 6. Scroll Through Compiler Errors with Vi Mode

When `cargo build` dumps a wall of errors:

1. `Ctrl + Shift + Space` → Enter Vi mode
2. `gg` → Jump to top of scrollback
3. `/error` → Search for "error"
4. `n` → Jump to next error
5. `v` → Start selection, yank with `y`

Much faster than mouse-scrolling!

### 7. Copy on Select (Linux)

```toml
[selection]
save_to_clipboard = true  # Selected text auto-copies to clipboard
```

---

## Starter Config (Complete)

Here's a ready-to-use config file combining the essentials:

```toml
# ~/.config/alacritty/alacritty.toml

# Import a theme (install alacritty-theme first)
[general]
import = [
    "~/.config/alacritty/themes/themes/catppuccin_mocha.toml"
]
live_config_reload = true

[env]
TERM = "alacritty"

[window]
padding = { x = 6, y = 6 }
dynamic_padding = true
opacity = 0.97
startup_mode = "Maximized"

[scrolling]
history = 50000
multiplier = 3

[font]
size = 13.0
[font.normal]
family = "JetBrains Mono"
style = "Regular"
[font.bold]
style = "Bold"
[font.italic]
style = "Italic"
[font.offset]
y = 1

[cursor.style]
shape = "Block"
blinking = "On"

[mouse]
hide_when_typing = true

[selection]
save_to_clipboard = true

[terminal]
shell = { program = "/bin/zsh", args = ["-l"] }
```

---

## Quick Reference

```
NAVIGATION                    SEARCH
Ctrl+Shift+Space = Vi mode    Ctrl+Shift+f = Search forward
h/j/k/l          = Move       Ctrl+Shift+b = Search backward
w/b               = Word jump  Enter/Shift+Enter = Next/prev match
gg / G            = Top/bottom Escape = Exit search

SELECTION (Vi mode)           GENERAL
v     = Character select      Ctrl+Shift+c = Copy
V     = Line select           Ctrl+Shift+v = Paste
Ctrl+v = Block select         Ctrl+Shift+n = New window
y     = Copy to clipboard     Ctrl+= / Ctrl+- = Font size
                              Ctrl+0 = Reset font size
```

---

## Alacritty vs Other Terminals

| Feature | Alacritty | GNOME Terminal | Kitty | WezTerm |
|---------|-----------|----------------|-------|---------|
| GPU-accelerated | ✅ | ❌ | ✅ | ✅ |
| Built-in tabs | ❌ | ✅ | ✅ | ✅ |
| Built-in splits | ❌ | ❌ | ✅ | ✅ |
| Config format | TOML | GUI | conf | Lua |
| Vi mode | ✅ | ❌ | ✅ | ❌ |
| Latency | Lowest | Medium | Low | Low |
| Resource usage | Very low | Medium | Low | Medium |
| Philosophy | Do one thing well | All-in-one | Feature-rich | Feature-rich |

**Bottom line:** If you want the fastest, leanest terminal and you're already using Zellij or tmux for multiplexing, Alacritty is the best choice.
