#!/bin/bash
# Helper script to set up your GitHub fork for Codespaces

set -e

echo "================================================"
echo "GitHub Fork Setup for OnlyOffice Customization"
echo "================================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "⚠️  GitHub CLI (gh) is not installed."
    echo ""
    echo "Please install it:"
    echo "  brew install gh"
    echo ""
    echo "Or do this manually:"
    echo "1. Go to https://github.com/ONLYOFFICE/DocumentServer"
    echo "2. Click 'Fork' button"
    echo "3. Then run:"
    echo "   git remote remove origin"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/DocumentServer.git"
    echo "   git add ."
    echo "   git commit -m 'Add Codespaces configuration'"
    echo "   git push -u origin master"
    exit 1
fi

# Authenticate with GitHub
echo "Step 1: Authenticate with GitHub..."
gh auth status 2>/dev/null || gh auth login

# Get user info
GH_USER=$(gh api user -q .login)
echo "✓ Authenticated as: $GH_USER"
echo ""

# Check if fork already exists
echo "Step 2: Checking for existing fork..."
if gh repo view "$GH_USER/DocumentServer" &>/dev/null; then
    echo "✓ Fork already exists: $GH_USER/DocumentServer"
    FORK_EXISTS=true
else
    echo "Creating fork..."
    # Create fork
    gh repo fork ONLYOFFICE/DocumentServer --clone=false
    echo "✓ Fork created: $GH_USER/DocumentServer"
    FORK_EXISTS=false
fi

echo ""
echo "Step 3: Updating git remote..."
# Update remote
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$GH_USER/DocumentServer.git"
echo "✓ Remote updated to your fork"

echo ""
echo "Step 4: Preparing commit..."
# Add all changes
git add .devcontainer/ *.sh *.md BUILD-FIX-NOTES.md CHANGES-SUMMARY.md CODESPACES-SETUP.md VERSION-FIX-README.md 2>/dev/null || true
git add Dockerfile.dev docker-compose.yml docker/ 2>/dev/null || true

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "✓ No new changes to commit (files already committed)"
else
    # Commit changes
    git commit -m "Add GitHub Codespaces configuration and custom development setup

- Added .devcontainer for GitHub Codespaces support
- Added version tracking fix for file reset issue
- Added helper scripts for building and running services
- Added comprehensive documentation
- Configured for embedded feature development (e.g., chat)
"
    echo "✓ Changes committed"
fi

echo ""
echo "Step 5: Pushing to your fork..."
# Push to fork
git push -u origin master

echo ""
echo "================================================"
echo "✓ Setup Complete!"
echo "================================================"
echo ""
echo "Your OnlyOffice customization is now at:"
echo "  https://github.com/$GH_USER/DocumentServer"
echo ""
echo "Next steps:"
echo "1. Go to: https://github.com/$GH_USER/DocumentServer"
echo "2. Click 'Code' → 'Codespaces' → 'Create codespace on master'"
echo "3. Wait 3-5 minutes for setup"
echo "4. Start building: ./build-with-version.sh"
echo ""
echo "See CODESPACES-SETUP.md for detailed instructions."
echo ""
