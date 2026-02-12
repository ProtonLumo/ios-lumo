#!/bin/bash

# Setup git hooks for the project
# Run this once after cloning the repository

set -e

echo "📦 Installing git hooks..."

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
cp scripts/git-hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "✅ Git hooks installed successfully!"
echo ""
echo "The following hooks are now active:"
echo "  - pre-commit: Formats Swift files with swift-format"
echo ""
echo "To skip hooks when needed: git commit --no-verify"
