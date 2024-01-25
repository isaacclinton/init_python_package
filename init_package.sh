echo "checking powershell installation..."
# checking if powershell exists, if not download
if ! command -v pwsh >/dev/null 2>&1; then 
    echo -e "\tpowershell is not installed. Installing..."
    ./install_powershell.sh
    echo -e "\tpowershell installed."
fi

pwsh ./init_package.ps1
