#!/bin/bash

# SSH Key Setup Script
# This script automates the process of setting up SSH keys for GitHub

set -e

echo "🔑 Setting up SSH keys for GitHub..."

# Check if SSH directory exists, create if not
if [ ! -d "$HOME/.ssh" ]; then
    echo "Creating ~/.ssh directory..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi

# Check if SSH keys already exist
if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
    echo "✅ SSH keys already exist!"
    echo "Existing keys:"
    ls -la ~/.ssh/id_*
    
    # Test GitHub connection
    echo "Testing GitHub connection..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "✅ SSH key is already working with GitHub!"
        exit 0
    else
        echo "⚠️  SSH key exists but GitHub connection failed."
        echo "You may need to add your public key to GitHub manually."
        echo "Your public key:"
        if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
            cat "$HOME/.ssh/id_ed25519.pub"
        elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
            cat "$HOME/.ssh/id_rsa.pub"
        fi
        exit 1
    fi
fi

# Get user email for SSH key from git config
GITHUB_EMAIL=$(git config --global user.email 2>/dev/null)

if [ -z "$GITHUB_EMAIL" ]; then
    echo "No email found in git config. Enter your GitHub email address:"
    read -r GITHUB_EMAIL
else
    echo "Using email from git config: $GITHUB_EMAIL"
fi

# Generate SSH key
echo "Generating new SSH key..."
ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""

# Start ssh-agent and add key
echo "Adding SSH key to ssh-agent..."
eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/id_ed25519"

# Copy public key to clipboard
echo "Copying public key to clipboard..."
if command -v pbcopy >/dev/null 2>&1; then
    cat "$HOME/.ssh/id_ed25519.pub" | pbcopy
    echo "✅ Public key copied to clipboard!"
elif command -v xclip >/dev/null 2>&1; then
    cat "$HOME/.ssh/id_ed25519.pub" | xclip -selection clipboard
    echo "✅ Public key copied to clipboard!"
else
    echo "⚠️  Could not copy to clipboard. Here's your public key:"
    cat "$HOME/.ssh/id_ed25519.pub"
fi

echo ""
echo "🔗 Next steps:"
echo "1. Go to https://github.com/settings/ssh/new"
echo "2. Give your key a title (e.g., 'MacBook Pro')"
echo "3. Paste your key (already in clipboard if on macOS)"
echo "4. Click 'Add SSH key'"
echo ""
echo "Then test the connection with: ssh -T git@github.com"
echo ""
echo "📖 For detailed instructions, see: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
