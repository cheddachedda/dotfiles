#!/bin/sh

echo "Setting up your Mac..."

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &>/dev/null; then
  echo "Xcode Command Line Tools not found. Installing..."
  xcode-select --install
else
  echo "Xcode Command Line Tools already installed."
fi

# Check for Oh My Zsh and install if we don't have it
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed."
fi

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew already installed."
fi

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc
ln -sw $HOME/.dotfiles/.zshrc $HOME/.zshrc

# Removes .gitconfig from $HOME (if it exists) and symlinks the .gitconfig file from the .dotfiles
rm -rf $HOME/.gitconfig
ln -sw $HOME/.dotfiles/.gitconfig $HOME/.gitconfig

# Removes .mise.toml from $HOME (if it exists) and symlinks the .mise.toml file from the .dotfiles
rm -rf $HOME/.mise.toml
ln -sw $HOME/.dotfiles/.mise.toml $HOME/.mise.toml

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle --file ./Brewfile

# Configure Mise
echo "Configuring Mise..."
mise trust
mise install

# Install Ruby gems
echo "Installing Ruby gems..."
mise exec -- gem update --system
mise exec -- gem install $(cat ./gems.txt)

# Start PostgreSQL service
echo "Starting PostgreSQL..."
brew services start postgresql@16

# Wait a moment for PostgreSQL to start
sleep 3

# Create a default database user (optional - you can customize this)
echo "Setting up PostgreSQL..."
createdb $(whoami) 2>/dev/null || echo "Database $(whoami) already exists or user setup complete"

# Create a projects directory if it doesn't exist
mkdir -p $HOME/projects

# Clone Github repositories
chmod +x ./clone.sh
./clone.sh

# Set up SSH keys for GitHub
echo "Setting up SSH keys for GitHub..."
chmod +x ./setup-ssh.sh
./setup-ssh.sh

# Set macOS preferences - we will run this last because this will reload the shell
source ./.macos
