#!/bin/bash

# Get the package path from the command-line argument
package_path="$1"

# Check if the package is valid
if [[ ! -f "$package_path/.python-version" ]]; then
  echo "Error: Invalid package. Missing .python-version file."
  exit 1
fi

echo "checking pyenv installation"
# Check if pyenv is installed
if ! command -v pyenv >/dev/null 2>&1; then
  echo "pyenv not found. Installing..."
  ./install-pyenv.sh &> /dev/null # Assuming install_pyenv.sh is in the same directory
fi


# Get the specified Python version from the .python-version file
python_version=$(cat "$package_path/.python-version" | grep -oP '\d+\.\d+\.\d+')
echo "expected python version: $python_version"

# Check if an existing .venv folder exists
if [[ -d "$package_path/.venv" ]]; then
  echo "existing .venv folder exists"
  # Check the Python version in the .venv folder
  venv_python_version=$("$package_path/.venv/bin/python" --version | grep -oP '\d+\.\d+\.\d+')

  echo "existing .venv version $venv_python_version"
  if [[ "$python_version" != "$venv_python_version" ]]; then
    # Delete the existing .venv folder
    echo 'deleting existing virtual environment due to version mismatch.'
    rm -rf "$package_path/.venv"
    echo -e "\tdeleted existing virtual environment due to version mismatch."
  fi
fi

# Create the virtual environment if it doesn't exist
if [[ ! -d "$package_path/.venv" ]]; then
  # Install the specified Python version if not already installed
  if ! pyenv versions | grep -q "$python_version"; then
    echo "python $python_version does not exist in pyenv. installing..."
    pyenv install "$python_version" &> /dev/null
    echo -e "\tinstalled python $python_version in pyenv..."
  fi

  # Create the virtual environment
  pyenv local "$python_version"

  # resets pyenv
  eval "$(pyenv init -)"

  echo "creating virtual environment with Python $python_version."  
  # creates a new virtual environment
  python -m venv "$package_path/.venv"

  echo -e "\tcreated virtual environment with Python $python_version."
fi

# Activate the virtual environment
source "$package_path/.venv/bin/activate"

# Install requirements from requirements.txt if it exists
if [[ -f "$package_path/requirements.txt" ]]; then
  echo 'installing requirements from requirements.txt'
  "$package_path/.venv/bin/pip" install -r "$package_path/requirements.txt" &> /dev/null
  echo -e "\tinstalled requirements from requirements.txt."
fi

echo "virtual environment initialized successfully."
