# Get the package path from the first command-line argument
$package_path = $args[0]


# Check if the package is valid
if (!(Test-Path "$package_path\.python-version")) {
    Write-Error "Error: Invalid package. Missing .python-version file."
    Exit 1
}

$initial_dir = (Get-Location | Select-Object -Expand Path)
Set-Location $package_path

Write-Host "Checking pyenv installation"

# Check if pyenv is installed
if (!(Get-Command pyenv -ErrorAction SilentlyContinue)) {
    Write-Host "pyenv not found. Installing..."
    & .\install-pyenv.ps1  # Assuming install_pyenv.ps1 is in the same directory
}

# Get the specified Python version from the .python-version file
$python_version = (Get-Content "$package_path\.python-version" | Select-String -Pattern '\d+\.\d+\.\d+').Matches.Value
Write-Host "Expected Python version: $python_version"

# Check if an existing .venv folder exists
if (Test-Path "$package_path\.venv") {
    Write-Host "Existing .venv folder exists"

    # Check the Python version in the .venv folder
    $venv_python_version = & "$package_path\.venv\Scripts\python" --version | Select-String -Pattern '\d+\.\d+\.\d+' | ForEach-Object { $_.Matches.Value }

    Write-Host "Existing .venv version: $venv_python_version"
    # Exit 1
    if ($python_version -ne $venv_python_version) {
        Write-Host "Deleting existing virtual environment due to version mismatch."
        Remove-Item "$package_path\.venv" -Recurse
        Write-Host "Deleted existing virtual environment due to version mismatch."
    }
}


# Create the virtual environment if it doesn't exist
if (!(Test-Path "$package_path\.venv")) {
    # Install the specified Python version if not already installed
    if (!(pyenv versions | Select-String -Pattern "$python_version")) {
        Write-Host "Python $python_version does not exist in pyenv. Installing..."
        pyenv install "$python_version"
        Write-Host "Installed Python $python_version in pyenv."
    }

    # Create the virtual environment
    # pyenv local "$python_version"
    if (Test-Path "$package_path\.python-version") {
        Remove-Item "$package_path\.python-version"
    }
    New-Item -Path "$package_path\.python-version" -ItemType "file" -Value "3.10.0" >$null 2>&1
    
    # Resets pyenv
    pyenv rehash

    Write-Host "Creating virtual environment with Python $python_version."
    python -m venv "$package_path\.venv"

    Write-Host "Upgrading pip"
    & "$package_path\.venv\Scripts\python" -m pip install --upgrade pip >$null 2>&1
    Write-Host "Created virtual environment with Python $python_version."
}


# Activate the virtual environment
# Install requirements from requirements.txt if it exists
if (Test-Path "$package_path\requirements.txt") {
    Write-Host "Installing requirements from requirements.txt"
    & "$package_path\.venv\Scripts\pip.exe" install -r "$package_path\requirements.txt" >$null 2>&1
    Write-Host "Installed requirements from requirements.txt."
}

Write-Host "Virtual environment initialized successfully."
Set-Location $initial_dir