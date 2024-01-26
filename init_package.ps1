
param (
    [Switch] $Testing = $False
)

. (Join-Path -Path $PSScriptRoot -ChildPath "functions.ps1")


# Get the package path from the first command-line argument
$package_path = $args[0]


if ($null -eq $package_path) {
    Write-Error "no package path provided"
    Exit 1
}

$package_path = Resolve-Path $package_path

Write-Host "checking package '$package_path'..."
# Check if the package is valid
if (!(Is-Valid-Package -Package $package_path)) {
    Write-Error (Get-Invalid-Package-Error($package_path))
    Exit 1
}
else {
    $package_python_version = Get-Package-Expected-Python-Version($package_path)
    Write-Host "    package is valid. expected python $package_python_version"
}

Write-Host "checking pyenv installation..."
# $initial_dir = (Get-Location | Select-Object -Expand Path)
# Set-Location $package_path
if (Pyenv-Is-Installed) {
    $pyenv_version = Get-Pyenv-Version
    Write-Host "    pyenv $pyenv_version is installed"
}
else {
    Write-Host "    pyenv is not installed. Installing..."
    Install-Pyenv 
    Write-Host "    installed pyenv"
}

Write-Host "checking package $(Get-Package-Venv-Dir-Name)"
if (Package-Venv-Exists($package_path)) {
    Write-Host "    $(Get-Package-Venv-Dir-Name) folder exists in package"
    if (Package-Venv-Is-Valid($package_path)) {
        $venv_python_version = Get-Python-Version(Get-Package-Python-Path($package_path))
        Write-Host "    $(Get-Package-Venv-Dir-Name) folder is valid. python $venv_python_version"
        if (Package-Venv-Is-Expected($package_path)) {
            Write-Host "    existing $(Get-Package-Venv-Dir-Name) is of the expected version"
        }
        else {
            Write-Host "    existing $(Get-Package-Venv-Dir-Name) is not of the expected version. deleting..."
            Delete-Package-Venv($package_path)
        }
    }
    else {
        Write-Host "    $(Get-Package-Venv-Dir-Name) folder is not valid. deleting..."
        Delete-Package-Venv($package_path)
    }
}
else {
    Write-Host "    $(Get-Package-Venv-Dir-Name) folder does not exist in package"
}

# Create the virtual environment if it doesn't exist
if (!(Package-Venv-Exists($package_path))) {
    Write-Host "creating $(Get-Package-Venv-Dir-Name)"
    $expected_python_version = Get-Package-Expected-Python-Version($package_path)
    $pyenv_is_empty = (Pyenv-Is-Empty)
    Write-Host "    pyenv is empty $pyenv_is_empty"
    if (Python-Version-Is-In-Pyenv($expected_python_version)) {
        Write-Host "    python $expected_python_version is in pyenv. creating $(Get-Package-Venv-Dir-Name)..."
        Make-Package-Venv($expected_python_version, $package_path)
        Write-Host "    created $(Get-Package-Venv-Dir-Name)"
    }
    else {
        Write-Host "    python $expected_python_version is not in pyenv. Installing..."
        Install-Python-In-Pyenv($expected_python_version)
        if ($pyenv_is_empty) {
            Write-Host "    setting $expected_python_version as global"
            Set-Global-Python-Version($expected_python_version)
        }
        Write-Host "    creating $(Get-Package-Venv-Dir-Name)..."
        Make-Package-Venv($expected_python_version, $package_path)
        Write-Host "    created $(Get-Package-Venv-Dir-Name)"   
    }
}

Write-Host "checking requirements"
# installing requirements from requirements.txt
if (Requirements-File-Exists-In-Package($package_path)) {
    Write-Host "    $(Get-Requirements-File-Name) exists in package. Installing requirements..."
    Install-Requirements-In-Package($package_path)
    Write-Host "    installed requirements"
}
else {
    Write-Host "    $(Get-Requirements-File-Name) does not exist in package"
}