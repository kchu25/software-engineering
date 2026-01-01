@def title = "uv Cheatsheet: Complete Reference"
@def published = "1 January 2026"
@def tags = ["python"]

# uv Cheatsheet: Complete Reference

## Installation

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# Via pip (if you must)
pip install uv

# Upgrade uv
uv self update
```

## Virtual Environments

```bash
# Create a new venv (default name: .venv)
uv venv

# Create with custom name
uv venv myenv

# Create with specific Python version
uv venv --python 3.11
uv venv --python 3.12

# Create with system site packages (access global packages)
uv venv --system-site-packages

# Delete a venv (just remove the directory)
rm -rf .venv
```

## Activation & Deactivation

```bash
# Activate (macOS/Linux)
source .venv/bin/activate

# Activate (Windows)
.venv\Scripts\activate

# Deactivate (any platform)
deactivate

# Check which Python you're using
which python     # macOS/Linux
where python     # Windows
```

## Package Installation

```bash
# Install a single package
uv pip install requests

# Install multiple packages
uv pip install requests pandas numpy

# Install specific version
uv pip install pandas==2.0.0

# Install version range
uv pip install "pandas>=2.0.0,<3.0.0"

# Install from requirements.txt
uv pip install -r requirements.txt

# Install from pyproject.toml
uv pip install -e .

# Install with optional dependencies
uv pip install -e ".[dev]"
uv pip install "package[extra1,extra2]"

# Install from git
uv pip install git+https://github.com/user/repo.git

# Install from local path
uv pip install /path/to/package
uv pip install ./my-local-package
```

## Package Management

```bash
# List installed packages
uv pip list

# Show package details
uv pip show pandas

# Upgrade a package
uv pip install --upgrade pandas
uv pip install -U pandas  # short form

# Upgrade all packages
uv pip install --upgrade-all

# Uninstall a package
uv pip uninstall pandas

# Uninstall multiple packages
uv pip uninstall pandas numpy requests
```

## Requirements Files

```bash
# Generate requirements.txt (exact versions)
uv pip freeze > requirements.txt

# Generate with hashes (for security)
uv pip freeze --require-hashes > requirements.txt

# Install from requirements
uv pip install -r requirements.txt

# Install and upgrade from requirements
uv pip install -U -r requirements.txt
```

## Sync & Lock

```bash
# Sync environment to match requirements exactly
uv pip sync requirements.txt

# This will:
# - Install missing packages
# - Upgrade outdated packages  
# - Uninstall extra packages

# Compile dependencies (resolve and lock)
uv pip compile pyproject.toml -o requirements.txt
uv pip compile requirements.in -o requirements.txt
```

## Search & Inspect

```bash
# Search for packages on PyPI
uv pip search pandas

# Check outdated packages
uv pip list --outdated

# Tree view of dependencies
uv pip tree

# Show dependency tree for specific package
uv pip tree --package pandas
```

## Development Workflow

```bash
# Install package in editable mode (development)
uv pip install -e .

# Install with dev dependencies
uv pip install -e ".[dev]"
uv pip install -e ".[test,docs]"

# Common pattern for new project
uv venv
source .venv/bin/activate
uv pip install -e ".[dev]"
```

## Python Version Management

```bash
# Use specific Python version
uv venv --python 3.11

# Use Python from specific path
uv venv --python /usr/bin/python3.11

# List available Python versions (if using uv's Python management)
uv python list
```

## Cache Management

```bash
# Show cache directory
uv cache dir

# Clear cache
uv cache clean

# Prune old cache entries
uv cache prune
```

## Common Workflows

### Starting a New Project

```bash
mkdir my-project && cd my-project
uv venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
uv pip install requests pandas
uv pip freeze > requirements.txt
```

### Cloning & Setting Up Existing Project

```bash
git clone https://github.com/user/project.git
cd project
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

### Creating a Python Package

```bash
mkdir my-package && cd my-package
uv venv
source .venv/bin/activate

# Create pyproject.toml (manually or with tools)
# Then install in editable mode
uv pip install -e ".[dev]"
```

### Quick Script Environment

```bash
# Create throwaway environment for a script
uv venv temp-env
source temp-env/bin/activate
uv pip install whatever-you-need
python script.py
deactivate
rm -rf temp-env
```

## Configuration

```bash
# Set environment variables for uv
export UV_INDEX_URL=https://pypi.org/simple/  # Custom PyPI index
export UV_CACHE_DIR=~/.cache/uv               # Custom cache location

# Create uv.toml in project root for project-specific config
# (check uv docs for current config options)
```

## Troubleshooting

```bash
# Verify uv is working
uv --version

# Check which Python uv sees
uv venv --python python3 --verbose

# Force reinstall a package
uv pip install --force-reinstall pandas

# Install without using cache
uv pip install --no-cache pandas

# Verbose output for debugging
uv pip install -v pandas
uv pip install -vv pandas  # extra verbose
```

## Tips & Tricks

```bash
# Always check you're in the right environment
which python
python --version

# Quick package install without activation
.venv/bin/python -m pip install package  # Not recommended, but works

# Export only top-level dependencies (manual, in requirements.in)
# Then compile to get full locked requirements.txt
uv pip compile requirements.in -o requirements.txt

# Use .gitignore
echo ".venv/" >> .gitignore
echo "__pycache__/" >> .gitignore
echo "*.pyc" >> .gitignore
```

## Comparison to pip

```bash
# pip command              →  uv equivalent
pip install package        →  uv pip install package
pip uninstall package      →  uv pip uninstall package
pip list                   →  uv pip list
pip show package           →  uv pip show package
pip freeze                 →  uv pip freeze
python -m venv .venv       →  uv venv
pip install -r req.txt     →  uv pip install -r req.txt
pip install -e .           →  uv pip install -e .
```

## When to Use What

- **Quick install**: `uv pip install package`
- **Lock dependencies**: `uv pip freeze > requirements.txt`
- **Reproducible install**: `uv pip sync requirements.txt`
- **Development**: `uv pip install -e ".[dev]"`
- **Fresh environment**: `rm -rf .venv && uv venv`

---

## VSCode Setup

> **VSCode makes this dead simple—it auto-detects and activates your venv.**
>
> **First time setup**:
> 1. Open your project folder in VSCode
> 2. Create your venv: `uv venv` in the terminal
> 3. VSCode will show a popup: "We noticed a new virtual environment. Do you want to select it?" → Click **Yes**
> 4. Done! VSCode will now use this venv automatically
>
> **If you missed the popup**:
> 1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
> 2. Type: `Python: Select Interpreter`
> 3. Choose the one that says `.venv` or `./venv/bin/python`
>
> **Check it worked**:
> - Open a new terminal in VSCode (`` Ctrl+` ``)
> - You'll see `(.venv)` at the start of the prompt
> - Or run `which python` (Mac/Linux) or `where python` (Windows)—it should point to your `.venv` folder
>
> **Pro tip**: Once set, VSCode remembers your choice. Every new terminal automatically activates the venv. You don't manually activate unless you're in a regular terminal outside VSCode.

---

**Remember**: Always activate your venv before working (`source .venv/bin/activate`). Check with `which python` if unsure!