function Get-Project-Path {
    if ($IsWindows) {
        Write-Output "D:/projects"
    }
    else {
        Write-Output (Join-Path -Path "~" -ChildPath "projects")
    }
}


function Get-Package-Path {
    $project_path = Get-Project-Path
    $project_path = ([IO.Path]::Combine($project_path, 'planner', 'packages', 'python_youtube_api'))
    Write-Output $project_path
}


function Get-Internet-Access {
    $is_connected = Test-Connection -ComputerName www.google.com -Quiet -Count 1
    Write-Output $is_connected
}


function Get-Python-Version-File-Path {

    [CmdletBinding()]
    param (
        [string]$PackagePath
    )

    Write-Output (Join-Path -Path $PackagePath -ChildPath ".python-version")
}

function Get-Package-Expected-Python-Version($PackagePath) {
    Write-Output (Get-Content (Get-Python-Version-File-Path -PackagePath $PackagePath) | Select-String -Pattern '\d+\.\d+\.\d+').Matches.Value
}   


function Is-Valid-Package {

    [CmdletBinding()]
    param (
        [string]$PackagePath
    )

    $package_error = (Get-Invalid-Package-Error($PackagePath))
    if ($package_error) {
        Write-Output $false
    }
    else {
        Write-Output $true
    }
}

function Get-Invalid-Package-Error($package_path) {

    if (!(Test-Path -Path $package_path)) {
        Write-Output "package path $package_path does not exist"
    }
    else {

        $py_version_file_exists = Test-Path (Get-Python-Version-File-Path -PackagePath $package_path)

        if (!$py_version_file_exists) {
            Write-Output "Invalid Package. Missing .python-version file"
        }
    }
}

function Get-Package-Python-Path($PackagePath) {

    $full_path = ([IO.Path]::Combine($PackagePath, (Get-Package-Venv-Dir-Name), 'bin', 'python'))
    if ($IsWindows) {
        $full_path = ([IO.Path]::Combine($PackagePath, (Get-Package-Venv-Dir-Name), 'Scripts', 'python.exe'))
    }
    Write-Output $full_path
}

function Get-Python-Version($Path) {

    if (Test-Path $Path) {
        try {
            $venv_python_version = ((& $Path --version) | Select-String -Pattern '\d+\.\d+\.\d+' | ForEach-Object { $_.Matches.Value })
            Write-Output $venv_python_version
        }
        catch {
            Write-Output $null
        }
    }
    else {
        Write-Output $null
    }
}


function Install-Pyenv {
    if (!(Get-Internet-Access)) {
        Throw "No Internet Access"
    }
    if ($IsWindows) {
        & .\install-pyenv.ps1 >$null 2>&1 # Assuming install_pyenv.ps1 is in the same directory
    }
    else {
        Invoke-Expression "chmod +x ./install-pyenv.sh" >$null 2>&1
        Invoke-Expression "/bin/bash ./install-pyenv.sh" >$null 2>&1
    }
}


function Pyenv-Is-Installed {

    # Check if pyenv is installed
    if (!(Get-Command pyenv -ErrorAction SilentlyContinue)) {
        
        Write-Output $false 
    }
    else {

        Write-Output $true
    }
    
}

function Get-Pyenv-Version {
    $pyenv_version = (pyenv --version  | Select-String -Pattern '\d+\.\d+\.\d+(-\d+-[\d\w]+)?' | ForEach-Object { $_.Matches.Value })
    Write-Output $pyenv_version
}

function Get-Package-Venv-Dir-Name {
    Write-Output ".venv"
}

function Get-Package-Venv-Path($package_path) {
    Write-Output (Join-Path -Path $package_path -ChildPath (Get-Package-Venv-Dir-Name))
}

function Package-Venv-Exists($package_path) {
    Write-Output (Test-Path (Get-Package-Venv-Path($package_path)))
}

function Package-Venv-Is-Valid($package_path) {
    if (!(Package-Venv-Exists($package_path))) {
        Write-Output $false
    }
    elseif (!(Get-Python-Version(Get-Package-Python-Path($package_path)))) {
        Write-Output $false   
    }
    else {

        Write-Output $true
    }
}

function Delete-Package-Venv($package_path) {
    $venv_path = (Get-Package-Venv-Path($package_path))
    if ($IsWindows) {
        Remove-Item $venv_path  -Recurse
    }
    else {
        Invoke-Expression "rm -r $venv_path"
    }
}

function Package-Venv-Is-Expected($package_path) {
    $venv_python_version = (Get-Python-Version(Get-Package-Python-Path($package_path)))
    $expected_python_version = Get-Package-Expected-Python-Version($package_path)

    Write-Output ($venv_python_version -eq $expected_python_version)
}

function Python-Version-Is-In-Pyenv($python_version) {
    if ((pyenv versions | Select-String -Pattern "$python_version")) {
        Write-Output $true
    }
    else {
        Write-Output $false
    }
}

function Install-Python-In-Pyenv($python_version) {
    if (!(Get-Internet-Access)) {
        Throw "No internet access"
    }
    pyenv install "$python_version" >$null 2>&1
}

function Pyenv-Is-Empty() {
    if ((pyenv versions)) {
        Write-Output $false
    }
    else {
        Write-Output $true
    }
}

function Set-Global-Python-Version($python_version) {
    pyenv global $python_version >$null 2>&1
    Refresh-Pyenv
}

function Refresh-Pyenv() {
    if (!$IsWindows) {
        bash -c 'eval "$(pyenv init -)"'
    }
    else {
        pyenv rehash
    }
}

function Make-Package-Venv($args1) {
    $python_version = $args1[0]
    $package_path = $args1[1]
    $initial_dir = (Get-Location | Select-Object -Expand Path)
    # So that pyenv local can use package_path
    Set-Location $package_path
    pyenv local $python_version
    
    Refresh-Pyenv

    python -m venv (Get-Package-Venv-Path($package_path))

    Write-Host "    upgrading pip"
    if (!(Get-Internet-Access)) {
        Throw "No Internet Access"
    }
    & (Get-Package-Python-Path($package_path)) -m pip install --upgrade pip >$null 2>&1
    Write-Host "    upgraded pip"
    Set-Location $initial_dir
}

function Get-Requirements-File-Name() {
    Write-Output ("requirements.txt")
}

function Get-Package-Requirements-File-Path($package_path) {
    Write-Output (Join-Path -Path $package_path -ChildPath (Get-Requirements-File-Name))
}

function Requirements-File-Exists-In-Package($package_path) {
    Write-Output (Test-Path (Get-Package-Requirements-File-Path($package_path)))
}

function Install-Requirements-In-Package($package_path) {
    if (!(Get-Internet-Access)) {
        Throw "No Internet Access"
    }
    $python_path = Get-Package-Python-Path($package_path)
    $requirements_path = Get-Package-Requirements-File-Path($package_path)

    & $python_path -m pip install -r $requirements_path >$null 2>&1
}