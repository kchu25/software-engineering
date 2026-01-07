@def title = "Creating Python Packages: A Guide for Julia Users"
@def published = "7 January 2026"
@def tags = ["python"]

# Creating Python Packages: A Guide for Julia Users

## TL;DR

Python's package creation is **similar in spirit** to Julia's but more fragmented. Instead of one blessed tool (PkgTemplates.jl), you have several good options. `uv` is emerging as the modern, fast choice that handles everything.

## The Modern Way: Using `uv`

Yes! `uv` can absolutely be your one-stop shop, similar to how you use PkgTemplates.jl:

```bash
# Create a new package (similar to PkgTemplates.generate)
uv init my-package --lib

# This creates:
# my-package/
# ├── pyproject.toml
# ├── README.md
# ├── src/
# │   └── my_package/
# │       └── __init__.py
# └── tests/
```

What `uv` gives you:
- **Project scaffolding** (like PkgTemplates.jl)
- **Dependency management** (like Julia's built-in Pkg)
- **Virtual environments** (Python quirk - isolated package installations)
- **Fast package installation** (written in Rust, blazing fast)

### Development workflow with `uv`:

```bash
# Add dependencies
uv add numpy pandas

# Add dev dependencies
uv add --dev pytest mypy

# Run your code
uv run python -m my_package

# Run tests
uv run pytest
```

## Package Structure

Your `pyproject.toml` is like Julia's `Project.toml`:

```toml
[project]
name = "my-package"
version = "0.1.0"
description = "A cool package"
authors = [
    {name = "Your Name", email = "you@example.com"}
]
dependencies = [
    "numpy>=1.20",
]

[build-system]
requires = ["hatchling"]  # or "setuptools", "flit", etc.
build-backend = "hatchling.build"
```

## Publishing: The Registry Difference

Here's where Python differs from Julia:

### Julia (what you're used to):
```
Code → GitHub → Registrator bot → General registry → Done ✓
```

### Python:
```
Code → Build distribution → Upload to PyPI → Done ✓
```

**Key difference:** PyPI (Python Package Index) is more like a package **hosting service** than a curated registry. Anyone can upload directly (after creating a free account).

### Publishing with `uv`:

```bash
# 1. Build your package (creates .whl and .tar.gz files)
uv build

# 2. Upload to PyPI (requires account at pypi.org)
uv publish

# Or test first on TestPyPI
uv publish --index-url https://test.pypi.org/legacy/
```

> **What's a "distribution"?** Think of it as the packaged-up version of your code ready to ship. When you run `uv build`, it creates two files in a `dist/` folder:
> - A `.whl` file (wheel) - a zip file with your code, optimized for fast installation
> - A `.tar.gz` file - a compressed source archive as backup
> 
> These are what get uploaded to PyPI. When someone runs `pip install your-package`, pip downloads one of these files and unpacks it. It's like creating a `.tar.gz` of your Julia package, except Python has standardized formats for this.

That's it! No bot needed. Your package is immediately available:

```bash
pip install my-package  # Anyone can now install it
```

## Alternative Tools (for context)

Since Python's ecosystem is more fragmented, you might encounter:

- **Poetry**: Popular, opinionated tool (like `uv` but slower)
- **Hatch**: Modern project manager with build support
- **Flit**: Minimal, simple tool for pure Python packages
- **setuptools**: The old-school way (verbose, dated)

But honestly? **Start with `uv`**. It's fast, modern, and handles everything you need.

## Quick Comparison Table

| Task | Julia | Python (with `uv`) |
|------|-------|-------------------|
| Create package | `PkgTemplates.generate()` | `uv init --lib` |
| Add dependency | Edit Project.toml or `]add` | `uv add package` |
| Run tests | `]test` | `uv run pytest` |
| Register package | GitHub + Registrator bot | `uv publish` |
| Install published | `]add Package` | `pip install package` |

## Pro Tips

1. **Version control**: Always include `pyproject.toml` in git. The `uv.lock` file (like `Manifest.toml`) can be included for reproducibility.

2. **Testing**: Unlike Julia's built-in test system, Python uses separate frameworks. `pytest` is the standard.

3. **Type hints**: Python's equivalent to Julia's type system is optional type hints + `mypy`:
   ```python
   def greet(name: str) -> str:
       return f"Hello, {name}!"
   ```

4. **Documentation**: Use `mkdocs` or `sphinx` (Julia's Documenter.jl equivalent)

## The Bottom Line

Python package creation is **slightly less streamlined** than Julia's because:
- Multiple competing tools (though `uv` is becoming the favorite)
- No centralized registry review (PyPI is open upload)
- Virtual environments add complexity (not needed in Julia)

But with `uv`, you get pretty close to the Julia experience: one tool, straightforward workflow, and quick publishing. The main win for Python is that once published, your package is **immediately available** worldwide - no waiting for registry merges!