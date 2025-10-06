#!/bin/bash

# Build the site
echo "Building Franklin.jl site..."
julia -e 'using Franklin; optimize()'

# Create or switch to gh-pages branch
git checkout --orphan gh-pages 2>/dev/null || git checkout gh-pages

# Remove all files except __site and .git
find . -maxdepth 1 ! -name '__site' ! -name '.git' ! -name '.' -exec rm -rf {} +

# Move __site contents to root
mv __site/* .
rmdir __site

# Add .nojekyll to prevent Jekyll processing
touch .nojekyll

# Commit and push
git add .
git commit -m "Deploy Franklin.jl site"
git push -f mathematics gh-pages

# Switch back to main
git checkout main

echo "Site deployed to gh-pages branch!"