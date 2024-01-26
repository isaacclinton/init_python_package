echo "checking powershell installation..."
# checking if powershell exists, if not download
if ! command -v pwsh >/dev/null 2>&1; then 
    echo -e "\tpowershell is not installed. Installing..."
    ./install_powershell.sh
    echo -e "\tpowershell installed."
else
    echo -e "\tpowershell installed."
fi

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}";
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

# $@ passes all arguments to the powershell script
pwsh $SCRIPT_DIR/init_package.ps1 $@