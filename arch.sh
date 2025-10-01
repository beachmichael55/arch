#!/usr/bin/env bash

# Load gettext for translations
. gettext.sh

# Get the script's base directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Set gettext domains for translation
unset TEXTDOMAIN
unset TEXTDOMAINDIR

# Set up colors for terminal output
export RESET=$(tput sgr0)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export ORANGE=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export PURPLE=$(tput setaf 5)
export CYAN=$(tput setaf 6)
export GREY=$(tput setaf 8)

# Display usage information
function usage() {
    echo "Usage : ./arch.sh [OPTION]"
    echo "Options :"; echo
    echo "  -h --help    : Display this help."
    echo "  -v --verbose : Verbose mode."
    echo "  --no-reboot  : Do not reboot the system at the end of the script."
}

# Parse command-line arguments
VALID_ARGS=$(getopt -o hv --long help,verbose,no-reboot -- "$@")
if [[ $? -ne 0 ]]; then
    exit 1
fi

# Process parsed arguments
eval set -- "$VALID_ARGS"
while :; do
    case "$1" in
        -h | --help)
            usage
            exit 1
            ;;
        -v | --verbose)
            export VERBOSE=true
            shift
            ;;
        --no-reboot)
            export NOREBOOT=true
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

# Set defaults if variables are not defined
export VERBOSE=${VERBOSE:-false}
export NOREBOOT=${NOREBOOT:-false}

# Ensure the script is not run as root
if [[ $(whoami) == 'root' ]]; then
    echo
	echo "${RED}Do not run this script as root, use a user with sudo rights${RESET}"
	echo
    exit 1
fi

# Prompt for sudo and test privileges
if sudo -v; then
    echo "${GREEN}Root privileges granted${RESET}"
else
    echo "${RED}Root privileges denied${RESET}"
    exit 1
fi

# Set log file path
export LOG_FILE="$SCRIPT_DIR/logfile_$(date "+%Y%m%d-%H%M%S").log"

# Detect the boot loader
if [[ -d "/boot/loader/entries" ]]; then
    export BOOT_LOADER="systemd-boot"
else
    export BOOT_LOADER="grub"
fi

# Detect Btrfs usage
if lsblk -o FSTYPE | grep -q btrfs; then
    export BTRFS=true
else
    export BTRFS=false
fi

# Source all modules
source src/init.sh
source src/end.sh
source src/de/detect.sh
source src/software/install.sh
source src/system/internet.sh
source src/system/config/aur.sh
source src/system/config/pacman.sh
source src/system/drivers/bluetooth.sh
source src/system/drivers/printer.sh
source src/system/drivers/gamepad.sh
source src/system/drivers/gpu.sh
source src/system/kernel.sh
source src/system/packages.sh
source src/system/shell.sh
source src/system/firewall.sh
source src/system/apparmor.sh
source src/system/usergroups.sh
source src/system/audio.sh
source src/system/bootloader.sh
source src/system/flatpak.sh
source src/system/bash_aliases.sh

# Display a big step with a visual separator
function display_step() {
    local -r message="$1"
    clear
    cat <<-EOF
${BLUE}-----------------------------------------------------------------------------------------------------------

                                   ${message}

-----------------------------------------------------------------------------------------------------------${RESET}
EOF
}

# Check if the OS is Arch Linux (not a derivative)
function check_os() {
    if [[ $(grep '^ID=' /etc/os-release) != "ID=arch" ]]; then
        echo "${RED}Error: This script is only compatible with Arch Linux and not its derivatives.${RESET}"
        exit 1
    fi
}

# Run a small step with a title and a function
function little_step() {
    local -r function=$1
    local -r message=$2

    echo -e "\n${PURPLE}${message}${RESET}"
    ${function}
}

# Main installation logic
function main() {
    check_os
    check_internet || exit 1
	read -n1 -p "Press any key to continue"

    local -r start_time="$(date +%s)"

    # Initialization
    display_step "Initialization"
    init_log
    header
read -n1 -p "Press any key to continue"
    # System configuration
    display_step "System preparation"
    sleep 1
    little_step config_pacman            "Pacman configuration"
	read -n1 -p "Press any key to continue"
    little_step install_aur              "AUR helper installation"
	read -n1 -p "Press any key to continue"
    little_step mirrorlist               "Mirrorlist configuration"
	read -n1 -p "Press any key to continue"
    little_step install_headers          "Kernel headers installation"
	read -n1 -p "Press any key to continue"
    little_step configure_sysctl_tweaks  "Kernel tweaks"
	read -n1 -p "Press any key to continue"
    little_step sound_server             "Sound server configuration"
	read -n1 -p "Press any key to continue"
    little_step setup_system_loaders     "System loaders configuration"
	read -n1 -p "Press any key to continue"
	little_step setup_flatpak			 "Flatpak setup"
	read -n1 -p "Press any key to continue"
    little_step usefull_package          "Useful package installation"
	read -n1 -p "Press any key to continue"
    little_step configure_sysctl_tweaks  "sysctl kernel tweaks"
	read -n1 -p "Press any key to continue"
    little_step firewall                 "Firewall installation"
	
    # little_step apparmor                 "Apparmor installation"
	read -n1 -p "Press any key to continue"
    little_step shell_config             "Shell configuration"
	read -n1 -p "Press any key to continue"
    little_step add_groups_to_user       "Adding user to necessary groups"

    # Driver installation
    display_step "System configuration"
    sleep 1
    little_step video_drivers            "Video drivers installation"
    little_step gamepad                  "Gamepad configuration"
    little_step printer                  "Printer configuration"
    little_step bluetooth                "Bluetooth configuration"

    # Desktop environment configuration
    display_step "Environment configuration"
    sleep 1
    little_step detect_de                "Desktop environment detection"

    # Software installation
    sleep 1
    display_step "oftware installation"
    little_step install_software         "Software installation"

    # Final wrap-up
    sleep 1
    endscript "${start_time}"
}

# Launch main procedure
main
