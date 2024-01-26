#!/bin/bash

# Check if pyenv is already installed
if command -v pyenv >/dev/null 2>&1; then
  echo "pyenv is already installed. Updating to the latest version..."
  pyenv update
else
  echo "Installing pyenv..."

  # Install dependencies
  sudo apt-get update
  sudo apt-get install -y git-core build-essential libssl-dev zlib1g-dev libbz2-dev \
                         libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
                         libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

  # Clone pyenv repository
  git clone https://github.com/pyenv/pyenv.git ~/.pyenv

  # Add pyenv to PATH
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
  echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc

  git clone https://github.com/pyenv/pyenv-update.git $(pyenv root)/plugins/pyenv-update

  # Initialize pyenv for the current shell
  eval "$(pyenv init -)"
  source ~/.bashrc
fi

# Optional: Install pyenv-virtualenv plugin
# if ! command -v pyenv-virtualenv >/dev/null 2>&1; then
#   pyenv install pyenv-virtualenv
#   pyenv virtualenv-init -
# fi

echo "Installation complete! To use pyenv, restart your terminal or run:"
echo "source ~/.bashrc"
