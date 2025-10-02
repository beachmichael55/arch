#!/bin/bash
#### SETUP mirror list

# Set up colors for terminal output
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
ORANGE=$(tput setaf 3)
BLUE=$(tput setaf 4)
PURPLE=$(tput setaf 5)
CYAN=$(tput setaf 6)
GREY=$(tput setaf 8)

if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root or with sudo.${RESET}"
    echo -e "${ORANGE}This script is designed to be run as a regular user with sudo privileges.${RESET}"
    echo -e "${ORANGE}It will prompt for sudo rights when necessary during the setup process.${RESET}"
    exit 1
fi
# Prompt user for a choice between two options
function prompt_choice() {
    local var_name=$1
    local prompt=$2
    shift 2
    local options=("$@")
    while true; do
        echo -e "${prompt}"
        for i in "${!options[@]}"; do
            printf "  %s) %s\n" "$((i + 1))" "${options[i]}"
        done

        read -rp "Choice [1-${#options[@]}]: " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            declare -g "$var_name=${options[choice-1]}"
            break
        else
            echo -e "${RED}Invalid option.${RESET} Please enter a number between 1 and ${#options[@]}."
        fi
    done
}
# Ask a yes/no question, return 0 for yes, 1 for no
function ask_question() {
    read -rp "$1 (y/N): " choice
    case "${choice,,}" in
        y|yes) return 0 ;;
        *) return 1 ;;
    esac
}
# Check if the OS is Arch Linux (not a derivative)
function check_os() {
    if [[ $(grep '^ID=' /etc/os-release) != "ID=arch" ]]; then
        echo "${RED}Error: This script is only compatible with Arch Linux and not its derivatives.${RESET}"
        exit 1
    fi
}
# Function to check if the system has an active internet connection
function check_internet() {
    local -r tool='curl'                     # Tool used to perform the connection check
    local -r tool_opts='-s --connect-timeout 8'  # Silent mode, with an 8-second timeout
    # Attempt to connect to archlinux.org; if it fails, show an error and return 1
    if ! ${tool} ${tool_opts} https://archlinux.org/ >/dev/null 2>&1; then
        echo "${RED}Error: No Internet connection${RESET}"
        return 1
    fi
    # Connection succeeded
    return 0
}
# Function to check and install a package
function install_package() {
    local package="$1"
    if pacman -Qi "$package" &> /dev/null; then
        echo "Package '$package' is already installed. Skipping..."
        return
    fi
    echo "Package '$package' is not installed. Attempting to install..."
    if command -v yay &> /dev/null; then
        yay -S --noconfirm "$package"
    elif command -v paru &> /dev/null; then
        paru -S --noconfirm "$package"
    elif command -v pacman &> /dev/null; then
        echo "No AUR helper found. Attempting to install with pacman..."
        sudo pacman -S --noconfirm --needed "$package" || {
            echo "Package '$package' could not be installed."
            return 1
        }
    else
        echo "No supported package manager (pacman, yay, paru) found."
        return 1
    fi
}
function uninstall_package() {
    local package="$1"
    if ! pacman -Qi "$package" &> /dev/null; then
        echo "Package '$package' is not installed. Skipping..."
        return
    fi
    echo "Package '$package' is installed. Attempting to uninstall..."
    if command -v yay &> /dev/null; then
        yay -Rns --noconfirm "$package"
    elif command -v paru &> /dev/null; then
        paru -Rns --noconfirm "$package"
    elif command -v pacman &> /dev/null; then
        sudo pacman -Rns --noconfirm "$package"
    else
        echo "No supported package manager (pacman, yay, paru) found."
        return 1
    fi
}
###########################################################################
# Function to check and enable multilib repository
function config_pacman() {
	# Enable color output in pacman
	if ! grep -q "^#Color" /etc/pacman.conf; then
		echo "Enabling color output in pacman..."
		sudo sed -i 's/^#Color$/Color/' '/etc/pacman.conf'
	else
		echo "Color output is already enabled.."
	fi
	# Enable verbose package lists
	if ! grep -q "^#VerbosePkgLists" /etc/pacman.conf; then
        echo "Enabling Verbose package lists..."
		sudo sed -i 's/^#VerbosePkgLists$/VerbosePkgLists/' '/etc/pacman.conf'
	else
		echo "Verbose package lists is already enabled.."
	fi
	# Enable Multilib(32bit) package lists
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo "Enabling multilib repository..."
        sudo tee -a /etc/pacman.conf > /dev/null <<EOT
[multilib]
Include = /etc/pacman.d/mirrorlist
EOT
        echo "Multilib repository has been enabled."
    else
        echo "Multilib repository is already enabled."
    fi
	# Full system upgrade
	echo "Updating full system ${RED}(might be long)${RESET}"
    sudo pacman -Syyu --noconfirm
    # Install pacman-contrib for tools like paccache
	echo "Installing pacman-contrib"
    sudo pacman -S pacman-contrib --noconfirm
    # Enable automatic cleaning of old package versions
	echo "Enabling paccache timer"
    sudo systemctl enable paccache.timer
	# Remove existing update-mirrors script if it exists
    
	# Checks if Archlinuxcn Repository exists
	if ! grep -q "^\[archlinuxcn]\]" /etc/pacman.conf; then
		# Ask to insall and enable Archlinuxcn Repository (Chinese Community) Repository
		if ask_question "Do you want to install and setup 'Archlinuxcn Repository' ${RED}say No if unsure${RESET}?"; then
			# Adds the repository to pacman and imports it's keys
			echo "Adding Archlinuxcn repo"
			echo -e '\n[archlinuxcn]\nServer = https://repo.archlinuxcn.org/\$arch' | sudo tee -a /etc/pacman.conf
			sudo pacman -Sy && sudo pacman -S archlinuxcn-keyring
		fi
	else
		echo "Archlinuxcn Repository is already enabled..."
	fi
}
function install_aur() {
	AUR=""
	local packages=("git" "base-devel" "pkgfile" "cmake")
	for pkg in "${packages[@]}"; do
		install_package "$pkg"
	done
	# Auto-detect if yay or paru is already installed
    if command -v yay &>/dev/null; then
        AUR="yay"
        echo "Detected yay is already installed."
    elif command -v paru &>/dev/null; then
        AUR="paru"
        echo "Detected paru is already installed."
    fi
	# Prompt user only if neither is installed
    if [[ -z "$AUR" ]]; then
		prompt_choice AUR "Which AUR helper do you want to install? ${CYAN}(yay/paru)${RESET}:" "yay" "paru"
		if [[ "$AUR" == "yay" ]]; then
			echo "Installing yay..."
			git clone https://aur.archlinux.org/yay-bin.git
			cd yay-bin || exit
			makepkg -si --noconfirm
			cd .. && rm -rf yay-bin
			export PATH="$PATH:$HOME/.local/bin"
			echo "Generating DB for $AUR"
			yay -Y --gendb
			echo "Auto-updating Git-based AUR packages"
			yay -Y --devel --save
			echo "Enabling SudoLoop option for yay"
			sed -i 's/\"sudoloop\": false,/\"sudoloop\": true,/' ~/.config/yay/config.json
		fi
		if [[ "$AUR" == "paru" ]]; then
			echo "Installing paru..."
			git clone https://aur.archlinux.org/paru-bin.git
			cd paru-bin || exit
			makepkg -si --noconfirm
			cd .. && rm -rf paru-bin
			export PATH="$PATH:$HOME/.local/bin"
			echo "Auto-updating Git-based AUR packages"
			paru --gendb
			echo "Enabling BottomUp option for paru"
			sudo sed -i 's/#BottomUp/BottomUp/' /etc/paru.conf
			echo "Enabling SudoLoop option for paru"
			sudo sed -i 's/#SudoLoop/SudoLoop/' /etc/paru.conf
			echo "Enabling CombinedUpgrade option for paru"
			sudo sed -i 's/#CombinedUpgrade/CombinedUpgrade/' /etc/paru.conf
			echo "Enabling UpgradeMenu option for paru"
			sudo sed -i 's/#UpgradeMenu/UpgradeMenu/' /etc/paru.conf
			echo "Enabling NewsOnUpgrade option for paru"
			sudo sed -i 's/#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf
			echo "Enabling SkipReview option for paru"
			sudo sed -i 's/#SkipReview/SkipReview/' /etc/paru.conf
			fi
	fi
}
function install_headers() {
    local kernel_headers=()
    for kernel in /boot/vmlinuz-*; do
        [ -e "${kernel}" ] || continue
        kernel_headers+=("$(basename "${kernel}" | sed -e 's/vmlinuz-//')-headers")
    done
    for header in "${kernel_headers[@]}"; do
		install_package "$header"
	done
}
function configure_sysctl_tweaks() {
    local sysctl_file="/etc/sysctl.d/99-architect-kernel.conf"
    # Remove existing sysctl file if it exists
    if [ -f "$sysctl_file" ]; then
		echo "Removing existing sysctl performance tweaks"
        sudo rm $sysctl_file
    fi
    # Create new sysctl config with system performance optimizations
	echo "Applying sysctl memory and kernel performance tweaks"
    sudo tee $sysctl_file > /dev/null << 'EOF'
# The sysctl swappiness parameter determines the kernel's preference for pushing anonymous pages or page cache to disk in memory-starved situations.
# A low value causes the kernel to prefer freeing up open files (page cache), a high value causes the kernel to try to use swap space,
# and a value of 100 means IO cost is assumed to be equal.
vm.swappiness = 100

# The value controls the tendency of the kernel to reclaim the memory which is used for caching of directory and inode objects (VFS cache).
# Lowering it from the default value of 100 makes the kernel less inclined to reclaim VFS cache (do not set it to 0, this may produce out-of-memory conditions)
vm.vfs_cache_pressure = 50

# Contains, as bytes, the number of pages at which a process which is
# generating disk writes will itself start writing out dirty data.
vm.dirty_bytes = 268435456

# page-cluster controls the number of pages up to which consecutive pages are read in from swap in a single attempt.
# This is the swap counterpart to page cache readahead. The mentioned consecutivity is not in terms of virtual/physical addresses,
# but consecutive on swap space - that means they were swapped out together. (Default is 3)
# increase this value to 1 or 2 if you are using physical swap (1 if ssd, 2 if hdd)
vm.page-cluster = 0

# Contains, as bytes, the number of pages at which the background kernel
# flusher threads will start writing out dirty data.
vm.dirty_background_bytes = 67108864

# The kernel flusher threads will periodically wake up and write old data out to disk.  This
# tunable expresses the interval between those wakeups, in 100'ths of a second (Default is 500).
vm.dirty_writeback_centisecs = 1500

# This action will speed up your boot and shutdown, because one less module is loaded. Additionally disabling watchdog timers increases performance and lowers power consumption
# Disable NMI watchdog
kernel.nmi_watchdog = 0

# Enable the sysctl setting kernel.unprivileged_userns_clone to allow normal users to run unprivileged containers.
kernel.unprivileged_userns_clone = 1

# To hide any kernel messages from the console
kernel.printk = 3 3 3 3

# Restricting access to kernel pointers in the proc filesystem
kernel.kptr_restrict = 2

# Disable Kexec, which allows replacing the current running kernel.
kernel.kexec_load_disabled = 1

# Increase netdev receive queue
# May help prevent losing packets
net.core.netdev_max_backlog = 4096

# Set size of file handles and inode cache
fs.file-max = 2097152

# Disable Intel split-lock
kernel.split_lock_mitigate = 0
EOF
    # Reload sysctl settings
    echo "Reloading sysctl parameters"
	sudo sysctl --system
}
function setup_sound() {
    # Packages to install for modern audio stack
	local packages=("pipewire" "wireplumber" "pipewire-alsa" "pipewire-jack" "pipewire-pulse" "alsa-utils" "alsa-plugins" "alsa-firmware" "alsa-ucm-conf" "sof-firmware" "rtkit")
	for pkg in "${packages[@]}"; do
		install_package "$pkg"
	done
	# Remove conflicting or outdated audio components
	uninstall_package "jack2"
}
function grub-btrfs() {
    # Ask the user if they want to set up Timeshift and GRUB-Btrfs
    if ask_question "Do you want to install and setup grub-btrfs and timeshift ${RED}say No if unsure${RESET} /!\  ?"; then
        # Install the required packages: Timeshift, Grub-Btrfs, and Timeshift autosnap
		local packages=("timeshift" "grub-btrfs" "timeshift-autosnap")
		for pkg in "${packages[@]}"; do
			install_package "$pkg"
		done
        # Enable cronie, needed for scheduled tasks like Timeshift autosnap
        echo "Enable cronie"
		sudo systemctl enable cronie.service
        # Enable the grub-btrfsd daemon, which generates GRUB entries for Timeshift snapshots
		echo "Enable grub-btrfsd"
        sudo systemctl enable grub-btrfsd
        # Modify the grub-btrfsd systemd unit to use Timeshift's snapshot directory automatically
		echo "setup grub-btrfsd for timeshift"
        sudo sed -i 's|ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' /etc/systemd/system/multi-user.target.wants/grub-btrfsd.service
    fi
}
function setup_boot_loaders() {
    echo "Checking if GRUB is installed"
    # Only continue if the system uses GRUB
    if [[ $BOOT_LOADER != "grub" ]]; then
        return
    fi
    # Ensure pacman hook directory exists
    echo "sudo mkdir -p /etc/pacman.d/hooks" "Creating /etc/pacman.d/hooks"
    # Create GRUB regeneration hook if it doesn't exist
    if [ ! -f /etc/pacman.d/hooks/grub.hook ]; then
        echo "Setting up GRUB hook"
	sudo tee /etc/pacman.d/hooks/grub.hook > /dev/null << 'EOF'
[Trigger]
Type = File
Operation = Install
Operation = Upgrade
Operation = Remove
Target = usr/lib/modules/*/vmlinuz

[Action]
Description = Updating grub configuration ...
When = PostTransaction
Exec = /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
EOF
    fi
    # Enable OS prober for dual-boot detection
    install_package "os-prober"
    echo "Enabling os-prober"
	sudo sed -i 's/#\s*GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' '/etc/default/grub'
    echo "Running os-prober"
	sudo os-prober
    echo "Updating GRUB"
	sudo grub-mkconfig -o /boot/grub/grub.cfg 
    # Install grub-btrfs if btrfs is used and package is not present
    if ! pacman -Q grub-btrfs &> /dev/null && [[ ${BTRFS} == true ]]; then
        grub-btrfs
    fi
}
function setup_flatpak() {
	install_package flatpak
    # Add Flathub if not already added
    if ! flatpak remote-list | grep -q flathub; then
		echo "Adding Flathub support"
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    # Update flatpak repos
	echo "Updating Flatpak/Flathub packages"
    flatpak update -y
}
function usefull_packages() {
		local packages=("gstreamer" "gst-plugins-base" "gst-plugin-pipewire" "gstreamer-vaapi" "gst-plugins-good" "gst-libav" "gstreamer-vaapi" "libva-mesa-driver" "mesa-vdpau" \
        "xdg-utils" "rebuild-detector" "fastfetch" "power-profiles-daemon" "ttf-dejavu" "ttf-liberation" "ttf-meslo-nerd" "noto-fonts-emoji" "adobe-source-code-pro-fonts" \
        "otf-font-awesome" "ttf-droid" "ntfs-3g" "fuse2" "fuse2fs" "fuse3" "exfatprogs" "bash-completion" "ffmpegthumbs" "man-db" "man-pages" "lsscsi" "mtools" "sg3_utils" \
		"efitools" "nfs-utils" "ntp" "unrar" "unzip" "libgsf" "networkmanager-openvpn" "networkmanager-l2tp" "network-manager-applet" "cpupower" "nano-syntax-highlighting" \
		"xdg-desktop-portal" "btop" "duf" "pv" "jq" "rsync" "duperemove" "curl" "iperf3" "python-pip" "wine-staging" "jre-openjdk" "dkms" "xorg-server" "xorg-xinit" "xwaylandvideobridge")
	for pkg in "${packages[@]}"; do
		install_package "$pkg"
	done
    if [[ ${BTRFS} == true ]]; then
		install_package "btrfs-progs"
		install_package "btrfs-assistant"
		install_package "btrfsmaintenance"
    fi
}
function firewall() {
	local installed_firewall=""
	# Check if either firewall is already installed
	if command -v firewall-cmd &>/dev/null; then
        installed_firewall="Firewalld"
    elif command -v ufw &>/dev/null; then
        installed_firewall="UFW"
    fi
	# If a firewall is already installed, inform the user and skip
    if [[ -n "$installed_firewall" ]]; then
        echo "A firewall is already installed: $installed_firewall. Skipping installation."
        return 0
    fi
	# Ask the user if they want to install a firewall
    if ask_question "Would you like to install a firewall?\ ${RED}WARNING: This script can install and enable either Firewalld or UFW. The default configuration may block local network devices such as printers or block some software functions.${RESET}"; then
        prompt_choice firewall_choice "Please choose which firewall to install by typing the number of your choice." "Firewalld" "UFW"
		if [[ "$firewall_choice" == "Firewalld" ]]; then
			install_package "firewalld"
			install_package "python-pyqt5"
			install_package "python-capng"
             # Enable and start the firewalld service immediately
			sudo systemctl enable --now firewalld.service &> /dev/null
			# Inform the user that Firewalld is set up
			echo "Firewalld has been installed and enabled."
		fi
		if [[ "$firewall_choice" == "UFW" ]]; then
			# Install the UFW package
			install_package "ufw"
			# Enable and start the ufw service
			sudo systemctl enable --now ufw.service &> /dev/null
			# Activate ufw (by default, it may block all incoming connections except SSH)
			sudo ufw enable
			# Inform the user that UFW is set up
			echo "UFW has been installed and enabled."
		fi
    fi
}
function shell_config() {
    # 1. Declare an associative array mapping command names to their implementations
    declare -A cmd_map=(
        [fix-key]="sudo rm /var/lib/pacman/sync/* && \
sudo rm -rf /etc/pacman.d/gnupg/* && \
sudo pacman-key --init && \
sudo pacman-key --populate && \
sudo pacman -Sy --noconfirm archlinux-keyring && \
sudo pacman --noconfirm -Su"
        [update-arch]="${AUR} -Syu --noconfirm"
        [update-grub]="sudo grub-mkconfig -o /boot/grub/grub.cfg"
        [install-all-pkg]="sudo pacman -S \$(pacman -Qnq) --overwrite '*'"
    )
    # Add the clean-arch command based on the chosen AUR helper
    if [[ "${AUR}" == "yay" ]]; then
        cmd_map[clean-arch]="yay -Sc --noconfirm && yay -Yc --noconfirm"
    elif [[ "${AUR}" == "paru" ]]; then
        cmd_map[clean-arch]="paru -Sc --noconfirm && paru -c --noconfirm"
    fi
    # 2. Create or recreate executable scripts in /usr/bin for each command
    for name in "${!cmd_map[@]}"; do
        local cmd="${cmd_map[$name]}"
        # If the binary already exists, remove it first
        if [[ -f /usr/bin/${name} ]]; then
            sudo rm /usr/bin/${name}
        fi
	done
        # Use tee with an EOF block to install the script
        sudo tee /usr/bin/${name} > /dev/null << EOF
#!/bin/bash
# Auto-generated by shell_config(): ${name}
${cmd}
EOF
	# Make the script executable
	sudo chmod +x /usr/bin/${name}
	# Ensure ~/.bashrc exists
	touch "${HOME}/.bashrc"
	if ! grep -q "bash_aliases" "${HOME}/.bashrc"; then
		echo -e '\n# Source ~/.bash_aliases if it exists\n[ -f ~/.bash_aliases ] && source ~/.bash_aliases' >> "${HOME}/.bashrc"
		echo "Added Bash Aliases line to ~/.bashrc"
	else
		echo "Bash Aliases line already sources in ~/.bash_aliases"
	fi
	cat > "${HOME}/.bash_aliases" <<'EOF'
### Custom Aliases ###
# Clear screen and history
alias cls='clear'
alias acls='history -c; clear'

# List hidden files
alias lh='ls -a --color=auto'

# Directory commands
alias mkdir='mkdir -pv'
alias rmdir='rm -rdv'

# Safer file operations
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'

# Networking and package management
alias brctl='sudo brctl'
alias net?='ping google.com -c 5'

# System info
alias stats='sudo systemctl status'
alias fstats='sudo systemctl status > status.txt'
alias analyze='systemd-analyze'
alias blame='systemd-analyze blame'
alias chain='systemd-analyze critical-chain'
alias chart='systemd-analyze plot > test.svg'

# KDE
alias plasmareset='killall plasmashell; kstart plasmashell'

# Grep with color
alias grep='grep --colour=auto'

# Pacman and AUR
alias add='sudo pacman -S --needed'
alias sp='pacman -Ss'
alias rem='sudo pacman -Rsn'
alias yay='paru -S'
alias sa='paru -Ss'
alias pac='sudo nano /etc/pacman.conf'

# Editors and config
alias nb='nano ~/.bashrc'
alias nano='vim'
alias n='nano'

# Fastfetch
alias ff='fastfetch'

# Disk and navigation
alias ld='lsblk'
alias up='cd ..'
alias up2='cd ../..'
alias up3='cd ../../..'
alias up4='cd ../../../..'
alias up5='cd ../../../../..'

# Network IP info
alias lan="ip addr show | grep 'inet ' | grep -v '127.0.0.1' | cut -d' ' -f6 | cut -d/ -f1"
alias lan6="ip addr show | grep 'inet6 ' | cut -d ' ' -f6 | sed -n '2p'"
alias wan='curl ipinfo.io/ip'

# Make all .sh files executable
#alias run='find . -type f -name \"*.sh\" -exec chmod +x {} \;'
alias run='find . -type f -name "*.sh" -exec chmod +x {} \;'

# Gaming and Wine tools
alias proton='protontricks --gui --no-bwrap'
alias bottles='flatpak run --command=bottles-cli com.usebottles.bottles'
EOF
}
function add_groups_to_user() {
    local -r groups_lst="sys,network,wheel,audio,lp,storage,video,users,rfkill"
	echo "Adding user to groups: ${groups_lst}"
    sudo usermod -aG ${groups_lst} $(whoami)
}
function video_drivers() {
    local -r valid_gpus=("intel" "amd" "nvidia" "vm")
    local choice index
	echo "Available GPU types:"
    for i in "${!valid_gpus[@]}"; do
        printf "  %d) %s\n" "$((i+1))" "${valid_gpus[$i]}"
    done
    echo "  Press Enter to skip driver selection."
	while true; do
        read -rp "Select your GPU by number (1-${#valid_gpus[@]}) or press Enter to skip: " choice
        if [[ -z "$choice" ]]; then
            echo -e "${ORANGE}Skipping GPU driver installation.${RESET}"
            return 0
        elif [[ "$choice" =~ ^[1-4]$ ]]; then
            index=$((choice - 1))
            break
        else
            echo -e "${RED}Invalid selection.${RESET} Please enter a number between 1 and ${#valid_gpus[@]}, or press Enter to skip."
        fi
    done
    local selected_gpu="${valid_gpus[$index]}"
    echo -e "${GREEN}You chose ${selected_gpu^^}${RESET}"
	install_package "vulkan-icd-loader"
	install_package "lib32-vulkan-icd-loader"
    case "${selected_gpu^^}" in
        "NVIDIA") nvidia_drivers ;;
        "AMD")    amd_drivers ;;
        "INTEL")  intel_drivers ;;
        "VM")     vm_drivers ;;
        *)        echo "${RED}Unexpected error: unknown GPU type '${selected_gpu}'${RESET}" ;;
    esac
}
function vm_drivers() {
    # Install virt-what to detect the virtualization environment
    install_package "virt-what"
    # Use virt-what to get the VM type
    local -r vm="$(sudo virt-what)"
    # Install generic software rendering and Vulkan support for VMs
	install_package "vulkan-swrast"
	install_package "lib32-vulkan-swrast"
	install_package "gtkmm3"
    # If running under VirtualBox, install VirtualBox guest utilities
    if [[ ${vm} =~ (^|[[:space:]])virtualbox($|[[:space:]]) ]]; then
		install_package "virtualbox-guest-utils"
        # Enable VirtualBox guest service
		echo "Activation of vboxservice"
        sudo systemctl enable vboxservice
        # Start VirtualBox client tools for resolution/sync
		echo "Activation of VBoxClient-all"
        sudo VBoxClient-all
	fi
	# If running under VmWare, install VmWare guest utilities
	if [[ ${vm} =~ (^|[[:space:]])vmware($|[[:space:]]) ]]; then
		install_package "open-vm-tools"
        # Enable VmWare guest service
		echo "Activation of 'vmtoolsd'"
        sudo systemctl enable vmtoolsd
		echo "Activation of 'vmware-vmblock-fuse'"
		sudo systemctl enable vmware-vmblock-fuse
    # Otherwise, assume QEMU or similar and install its agents
    else
        install_package "spice-vdagent"
        install_package "qemu-guest-agent"
    fi
    # Remove virt-what after use to keep the system clean
    uninstall_package "virt-what"
}
function intel_drivers() {
		local packages=("mesa" "lib32-mesa" "xf86-video-intel" "vulkan-intel" "lib32-vulkan-intel" "intel-media-driver" "intel-gmmlib" "onevpl-intel-gpu" "vulkan-mesa-layers"\ 
        "libva-mesa-driver" "lib32-libva-mesa-driver" "mesa-vdpau" "lib32-mesa-vdpau" "intel-gpu-tools")
	for pkg in "${packages[@]}"; do
		install_package "$pkg"
	done
}
function amd_drivers() {
		local packages=("mesa" "lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon" "libva-mesa-driver" "lib32-libva-mesa-driver" "vulkan-mesa-layers" "mesa-vdpau"\
		"lib32-mesa-vdpau" "radeontop" "xf86-video-amdgpu" "xf86-video-ati" "corectrl" "lact")
		for pkg in "${packages[@]}"; do
			install_package "$pkg"
		done
    if ask_question "Would you like to install ROCM ({RED}say No if unsure{RESET})"; then
		local packages=("rocm-opencl-runtime" "rocm-hip-runtime" "rocm-clinfo")
		for pkg in "${packages[@]}"; do
			install_package "$pkg"
		done
    fi
}
# Ensure early loading of NVIDIA modules in initramfs
function nvidia_earlyloading() {
    if ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
		echo "Adding NVIDIA modules to mkinitcpio.conf"
        sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
    else
        echo "NVIDIA modules already present in mkinitcpio.conf"
    fi
}
# Gets the pkgbuild file, then edits 'Plasma' line to enable extra Plasma functions, then builds with changes
function optimus_plasma() {
	# Building optimus-manager-qt with Plasma support
    if [[ "$AUR" == "yay" ]]; then
		yay --getpkgbuild optimus-manager-qt && cd optimus-manager-qt && sed -i 's/_with_plasma=false/_with_plasma=true/' PKGBUILD && makepkg -si
	fi
	if [[ "$AUR" == "paru" ]]; then
		paru -G optimus-manager-qt && cd optimus-manager-qt && sed -i 's/_with_plasma=false/_with_plasma=true/' PKGBUILD && makepkg -si
	fi
}
# Optional installation of Intel GPU drivers for hybrid laptops
function nvidia_intel() {
	local packages=("intel-media-driver" "intel-gmmlib" "onevpl-intel-gpu" "xf86-video-intel" "xorg-xrandr" "nvidia-prime")
	for pkg in "${packages[@]}"; do
		install_package "$pkg"
	done
	if ask_question "Do you use KDE Plasma?"; then
		echo "For Turing (GeForce RTX 2080 and earlier): Choose [2] for Proprietary."
        echo "For Ampere and later (RTX 3050+): Choose [5] for Open Kernel."
        optimus_plasma
	else
		echo "For Turing (GeForce RTX 2080 and earlier): Choose [2] for Proprietary."
        echo "For Ampere and later (RTX 3050+): Choose [5] for Open Kernel."
		sudo $AUR -S optimus-manager-qt
    fi
}
function nvidia_desktop() {
    echo "Use open-kernel drivers for GTX 1650+ and newer, otherwise use proprietary."
    if ask_question "Do you want to use NVIDIA's proprietary drivers? (NO means open-kernel)"; then
        install_package "nvidia-dkms"
    else
        install_package "nvidia-open-dkms"
    fi
}
# Main function to uninstall legacy NVIDIA drivers and install the correct set
function nvidia_drivers() {
    # Install required NVIDIA packages
    local packages=("egl-wayland" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings" "lib32-opencl-nvidia" "libvdpau-va-gl" "libvdpau" "libva-nvidia-driver")
	for pkg in "${packages[@]}"; do
		install_package "$pkg"
	done
    # function early loading NVIDIA fonction
    nvidia_earlyloading
    # Optional Intel GPU driver installation for hybrid laptops
	if ask_question "Is this a laptop (with Intel/NVIDIA hybrid graphics)?"; then
		nvidia_intel
	else
		nvidia_desktop
	fi
    # Optional CUDA installation
    if ask_question "Do you want to install CUDA (${RED}say No if unsure${RESET}) ?"; then
        install_package "cuda"
    fi
    # Enable NVIDIA suspend/resume services
	echo "Enabling NVIDIA suspend/resume services"
    sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
    # Conditionally enable nvidia-powerd if on laptop and GPU is not Turing
    local device_type
    device_type="$(cat /sys/devices/virtual/dmi/id/chassis_type)"
    if ((device_type >= 8 && device_type <= 11)); then
        # Check for Turing GPUs (Device name starts with "TU")
        if ! lspci -d "10de:*:030x" -vm | grep -q 'Device:\s*TU'; then
			echo "Enabling NVIDIA PowerD for supported laptop GPU"
            sudo systemctl enable nvidia-powerd.service
        else
            echo "NVIDIA PowerD is not supported on Turing GPUs"
        fi
    else
        echo "Not a laptop chassis; skipping NVIDIA PowerD"
    fi
}
function gamepad() {
	install_package "joystickwake"
    if ask_question "Would you want to install xpadneo? (Can improve Xbox gamepad support. ${RED}Say No if unsure.${RESET})"; then
        install_package "xpadneo-dkms-git"
    fi

    if ask_question "Would you want to install Xone? (Can improve Xbox gamepad support with a USB wireless dongle. ${RED}Say No if unsure.${RESET})"; then
            install_package "xone-dkms-git"
            install_package "xone-dongle-firmware"

    fi

    if ask_question "Do you want to use PS5 controllers?"; then
        install_package "dualsensectl-git"
    fi
}
function printer() {
    if ask_question "Do you want to use a printer?"; then
		local packages=("ghostscript" "gsfonts" "cups" "cups-filters" "cups-pdf" "system-config-printer" "avahi" "foomatic-db-engine" "foomatic-db" "foomatic-db-ppds" \
		"foomatic-db-nonfree" "foomatic-db-nonfree-ppds" "gutenprint" "foomatic-db-gutenprint-ppds" "splix")
		for pkg in "${packages[@]}"; do
			install_package "$pkg"
		done
        if ask_question "Do you want to use an EPSON printer?"; then
                install_package "epson-inkjet-printer-escpr"
                install_package "epson-inkjet-printer-escpr2"
        fi
        if ask_question "Do you want to use a HP printer?"; then
                install_package "hplip"
                install_package "python-pyqt5"
        fi
        # Enable necessary services
		echo "Enabling avahi-daemon service"
        sudo systemctl enable avahi-daemon
		echo "Enabling cups service"
        sudo systemctl enable cups
        # If firewalld is installed, open the ports/services needed for CUPS
        if command -v firewall-cmd >/dev/null 2>&1; then
            # Open the IPP service (port 631) for network printing
			echo "Opening IPP service for CUPS"
            sudo firewall-cmd --permanent --add-service=ipp
			echo "Opening mDNS for printer discovery"
            sudo firewall-cmd --permanent --add-service=mdns
			echo "Reloading firewalld configuration"
            sudo firewall-cmd --reload
        fi
        # If ufw is installed, open the same ports/services for CUPS
        if command -v ufw >/dev/null 2>&1; then
            # UFW doesn't have a named 'ipp' service by default, so we directly open port 631
			echo "Opening TCP port 631 for IPP"
            sudo ufw allow 631/tcp
            # mDNS typically uses UDP port 5353
			echo "Opening UDP port 5353 for mDNS"
            sudo ufw allow 5353/udp
			echo "Reloading ufw configuration"
            sudo ufw reload
        fi
    fi
}
function bluetooth() {
    if ask_question "Do you want to use Bluetooth?"; then
		local packages=("bluez" "bluez-plugins" "bluez-utils" "bluez-hid2hci" "bluez-libs")
		for pkg in "${packages[@]}"; do
			install_package "$pkg"
		done
        # Enable the Bluetooth service
		echo "Enabling bluetooth service"
        sudo systemctl enable bluetooth
    fi
}
function detect_de() {
    local detected=""
    # Get the current desktop environment from standard environment variables
    # Fallback to DESKTOP_SESSION if XDG_CURRENT_DESKTOP is not set
    local desktop_env="${XDG_CURRENT_DESKTOP,,}"
    desktop_env="${desktop_env:-${DESKTOP_SESSION,,}}"
    # Match known desktop environments and run the corresponding setup
    case "$desktop_env" in
        *gnome*)
            detected="GNOME"
            install_gnome
            ;;
        *plasma*|*kde*)
            detected="KDE"
            install_kde
            ;;
        *xfce*)
            detected="XFCE"
            install_xfce
            ;;
        *)
            detected="OTHER"
            echo "No supported DE detected (GNOME, KDE, XFCE). Skipping DE configuration."
            return
            ;;
    esac
    # Output the detected environment for logging/debugging
    echo "Detected desktop environment:$detected"
}
function install_kde() {
    # Define a list of KDE applications to install
		local packages=("konsole" "dolphin" "ark" "plasma-meta" "plasma-workspace" "print-manager" "gwenview" "spectacle" "partitionmanager" "ffmpegthumbs" "qt6-multimedia" "qt6-multimedia-gstreamer" \
        "qt6-multimedia-ffmpeg" "qt6-wayland" "kdeplasma-addons" "kcalc" "plasma-systemmonitor" "kwalletmanager" "kio-admin" "egl-wayland" "sddm-kcm" "filelight" "xdg-desktop-portal-kde" \
		"kdegraphics-thumbnailers" "kdialog")
		for pkg in "${packages[@]}"; do
			install_package "$pkg"
		done
    # Check if the SDDM configuration file exists
    if [ ! -f /etc/sddm.conf ]; then
        # Create the SDDM configuration file if it doesn't exist
		echo "Creating /etc/sddm.conf"
        sudo touch /etc/sddm.conf
    fi
    # Set the Breeze theme for SDDM
	echo "Setting Breeze theme for SDDM"
    echo -e '[Theme]\nCurrent=breeze' | sudo tee -a /etc/sddm.conf
    # Enable Numlock for SDDM
	echo "Setting Numlock=on for SDDM"
    echo -e '[General]\nNumlock=on' | sudo tee -a /etc/sddm.conf
}
function install_gnome() {
    # Define a list of GNOME applications to install
		local packages=("gnome" "gnome-tweaks" "gnome-calculator" "gnome-console" "gnome-control-center" "gnome-disk-utility" "gnome-keyring" "gnome-nettool" "gnome-power-manager" "gnome-shell" \
        "gnome-text-editor" "gnome-themes-extra" "gnome-browser-connector" "adwaita-icon-theme" "loupe" "papers" "gdm" "gvfs" "gvfs-afc" "gvfs-gphoto2" "gvfs-mtp" "gvfs-nfs" "gvfs-smb" "nautilus" \
        "nautilus-sendto" "sushi" "totem" "xdg-user-dirs-gtk" "adw-gtk-theme" "snapshot" "qt6-wayland")	
		for pkg in "${packages[@]}"; do
			install_package "$pkg"
		done
    # Set the GTK theme to adw-gtk3
	echo "Setting gtk theme to adw-gtk3"
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
    # Enable Numlock on startup
	echo "Enabling numlock on startup"
    gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true
    # Disable GDM rules to unlock Wayland
	echo "Disable GDM rules to unlock Wayland"
    sudo ln -s /dev/null /etc/udev/rules.d/61-gdm.rules
}
function install_xfce() {
	local packages=("xfce4" "xfce4-goodies" "pavucontrol" "gvfs" "xarchiver" "xfce4-battery-plugin" "xfce4-datetime-plugin" "xfce4-mount-plugin" "xfce4-netload-plugin" \
	"xfce4-notifyd" "xfce4-pulseaudio-plugin" "xfce4-screensaver" "xfce4-screenshooter" "xfce4-taskmanager" "xfce4-wavelan-plugin" "xfce4-weather-plugin" "xfce4-whiskermenu-plugin" \
	"xfce4-xkb-plugin" "xdg-desktop-portal-xapp" "xdg-user-dirs-gtk" "network-manager-applet" "xfce4-notifyd" "gnome-keyring" "mugshot" "xdg-user-dirs" "blueman" "file-roller" \
	"galculator" "gvfs-afc" "gvfs-gphoto2" "gvfs-mtp" "gvfs-nfs" "gvfs-smb" "lightdm" "lightdm-slick-greeter" "network-manager-applet" "parole" "ristretto" \
	"thunar-archive-plugin" "thunar-media-tags-plugin" "xed")
	for pkg in "${packages[@]}"; do
		install_package "$pkg"
	done
	echo "Updating user directories"
    xdg-user-dirs-update
}

set "FLAT=Flatpak"
set "AURT=Aur"
# Declare associative arrays for each software category
declare -A desktop_list
declare -A desktop_list2
declare -A desktop_list3
declare -A system_list
declare -A browser_list
declare -A accessibility_list
declare -A video_list
declare -A picture_list
declare -A gaming_list
declare -A gaming_list2
declare -A emulator_list
declare -A emulator_list2
declare -A emulator_list3
# Will store the complete list of packages to install
selected_packages=""
# -----------------------------------------------------------------------------
# Define software choices for each category
# -----------------------------------------------------------------------------
function set_software_list() {
    desktop_list=(
        ["Discord(instant messaging and VoIP social platform)"]="discord|com.discordapp.Discord"
		["Vesktop(Snappier Discord alternitive)"]="vesktop-bin|dev.vencord.Vesktop"
		["Ulauncher(Application launcher for Linux)"]="ulauncher"
		["Meld(Compare files, directories and working copies)"]="meld|org.gnome.meld"
		["Distrobox(run containerized Linux distributions)"]="distrobox|io.github.dvlv.boxbuddyrs"
        ["Kate(Feature-Packed Text Editor)"]="kate|org.kde.kate"
		["K3B(CD, DVD and Blu-ray authoring application)"]="k3b"
		["RCloneBrowser(GUI for rclone)"]="rclone-browser"
        ["LibreOffice(open source office suite)"]="libreoffice-fresh|org.libreoffice.LibreOffice"
    )
	desktop_list2=(
		["Qbittorrent(P2P BitTorrent client)"]="qbittorrent|org.qbittorrent.qBittorrent"
		["Calibre(e-book manager)"]="calibre|com.calibre_ebook.calibre"
		["Keepassxc(open-source password manager)"]="keepassxc|org.keepassxc.KeePassXC"
		["Syncthing(continuous file synchronization program)"]="syncthing|com.github.zocker_160.SyncThingy"
		["Syncthing Tray 'Not Needed with 'Syncthing'"]="syncthingtray"
		["Thunderbird(email, newsfeed, chat, and calendaring client)"]="thunderbird|org.mozilla.Thunderbird"
		["Filezilla(Fast and reliable FTP client)"]="filezilla|org.filezillaproject.Filezilla"
		["Remmina(Remote desktop client)"]="remmina|org.remmina.Remmina.desktop"
		["ProtonVPN(Protons VPN app)"]="proton-vpn-gtk-app|com.protonvpn.www"
		["Ekpar2(tool to create par2 recovery files, verify and repair)"]="ekpar2"
	)
	desktop_list3=(
		["IPerf(Network bandwidth measurement tool)"]="iperf3"
		["Wireshark(Network traffic and protocol analyzer/sniffer)"]="wireshark-qt|org.wireshark.Wireshark"
		["Audacity(audio editing and recording app)"]="audacity|org.audacityteam.Audacity"
		["Notepadqq(advanced text editor)"]="|com.notepadqq.Notepadqq"
		["FFaudioConverter(graphical audio converter)"]="|com.github.Bleuzen.FFaudioConverter"
		["NTag(graphical audio tag editor)"]="|com.github.nrittsti.NTag"
		["SpeechNote(offline Speech to Text, Text to Speech)"]="net.mkiol.SpeechNote"
	)
    system_list=(
        ["Open RGB(RGB lighting control)"]="openrgb i2c-tools"
        ["Open Razer(Drivers/tools for Razer hardware)"]="openrazer-daemon libnotify polychromatic"
        ["Arch Update(An update notifier & applier)"]="arch-update vim"
		["Virtualbox(Powerful x86 virtualization)"]="virtualbox virtualbox-host-dkms virtualbox-guest-iso"
        ["Virtmanager(Desktop user interface for managing virtual machines)"]="qemu-full libvirt virt-manager virt-viewer dnsmasq vde2 /
		bridge-utils openbsd-netcat dmidecode libguestfs guestfs-tools"
    )

    picture_list=(
        ["Gimp(GNU Image Manipulation Program)"]="gimp|org.gimp.GIMP"
        ["Krita(Edit and paint images)"]="krita|org.kde.krita"
        ["Blender(fully integrated 3D graphics creation suite)"]="blender|org.blender.Blender"
		["Digikam(advanced digital photo management)"]="digikam|org.kde.digikam.desktop"
		["Converseen(Batch image converter and resizer)"]="converseen|net.fasterland.converseen"
		["Switcheroo(Convert and manipulate images)"]="switcheroo|io.gitlab.adhami3310.Converter"
    )

    video_list=(
        ["Kdenlive(A non-linear video editor for Linux)"]="kdenlive|org.kde.kdenlive"
        ["OBS Studio(software for live streaming and recording)"]="obs-studio|com.obsproject.Studio"
        ["VLC(multimedia player)"]="vlc|org.videolan.VLC"
        ["MPV(minimalistic media player)"]="mpv|io.mpv.Mpv"
		["mediainfo(Supplies technical and tag information about media files)"]="mediainfo-gui|net.mediaarea.MediaInfo"
		["Aegisub (general-purpose subtitle editor)"]="aegisub|org.aegisub.Aegisub"
    )

    browser_list=(
        ["Firefox (Mozilla web browser)"]="firefox|org.mozilla.firefox"
		["Firefox Beta (Mozilla web browser - Beta branch)"]="firefox-beta-bin"
        ["Brave (Chromium-based 'Private' web browser)"]="brave-bin|com.brave.Browser"
        ["Chromium (Ungoogled Chromium-based web browser)"]="chromium|org.chromium.Chromium"
        ["Vivaldi (Chromium-based 'Private' web browser)"]="vivaldi vivaldi-ffmpeg-codecs|com.vivaldi.Vivaldi"
        ["Google Chrome (Googles web browser)"]="google-chrome|com.google.Chrome"
        ["Microsoft Edge (Microsoft web browser)"]="microsoft-edge-stable-bin|com.microsoft.Edge"
		["Pipeline (Client for Youtube watch, download,make 'Subscriptions without Login)"]="de.schmidhuberj.tubefeeder"
    )
	accessibility_list=(
        ["ESpeakup (light weight connector for espeak-ng and speakup)"]="espeakup"
        ["MouseTweaks (Mouse accessibility enhancements)"]="mousetweaks"
		["Orca (Screen reader for individuals who are blind or visually impaired)"]="orca"
    )
    gaming_list=(
        ["Steam (Game Launcher/Manager/Store) Only:Native"]="steam"
        ["Lutris (Game Launcher/Manager)"]="lutris|net.lutris.Lutris"
        ["Heroic Games Launcher(Game Launcher/Manager/Store) Only:AURT"]="com.heroicgameslauncher.hgl"
        ["Prism Launcher (Minecraft)"]="prismlauncher|org.prismlauncher.PrismLauncher"
		["vkBasalt (Vulkan post processing layer-ReShade)"]="org.freedesktop.Platform.VulkanLayer.vkBasalt//24.08"
		["ProtonPlus (Manage supported compatibility tools across supported launchers)"]="com.vysp3r.ProtonPlus"
		["MameTools (Tools for emulators:chdman)"]="mame-tools"
		["Restic (Fast, secure, efficient backup program)"]="restic"
        ["RuneLite (Old School RuneScape client)"]="runelite|net.runelite.RuneLite"
    )
	gaming_list2=(
		["Goverlay/Mangohud (GUI to help manage Vulkan/OpenGL overlays)"]="mangohud lib32-mangohud gamescope goverlay org.freedesktop.Platform.VulkanLayer.MangoHud /
		org.freedesktop.Platform.VulkanLayer.MangoHud org.freedesktop.Platform.VulkanLayer.gamescope"
		["ProtonTricks (Apps and fixes for Proton games)"]="com.github.Matoking.protontricks"
        ["Gamemode (Daemon that allows games to request a set of optimisations)"]="gamemode lib32-gamemode"
		["ProtonUp QT (Install Wine- and Proton-based compatibility tools)"]="net.davidotek.pupgui2"
		["Moonlight (Client for Sunshine server)"]="moonlight-qt|com.moonlight_stream.Moonlight"
		["Sunshine (Self-hosted game stream host for Moonlight)"]="dev.lizardbyte.app.Sunshine"
		["Ludusavi (backing up your PC video game save data)"]="com.github.mtkennerly.ludusavi"
	)
	emulator_list=(
		["Ryubing(Switch-Ryujinx) Only:$FLAT"]="io.github.ryubing.Ryujinx"
		["Azahar(3DS) Only:$FLAT"]="org.azahar_emu.Azahar"
		["Cemu(WiiU) Only:$FLAT"]="info.cemu.Cemu"
		["PPSSPP(PSP) Only:$FLAT"]="org.ppsspp.PPSSPP"
		["mGBA(GameBoy Adv) Only:$FLAT"]="io.mgba.mGBA"
		["Pcsx2(PS2) Only:$FLAT"]="net.pcsx2.PCSX2"
		["melonDS(DS) Only:$FLAT"]="net.kuribo64.melonDS"
		["PrimeHack(Metroid Prime) Only:$FLAT"]="io.github.shiiion.primehack"
		["Rosalies Mupen GUI(N64) Only:$FLAT"]="com.github.Rosalie241.RMG"
	)
	emulator_list2=(
		["ShadPS4(PS4) Only:$FLAT"]="net.shadps4.shadPS4"
		["Dolphin(GC-Wii) Only:$FLAT"]="org.DolphinEmu.dolphin-emu"
		["Snes9x(SNES) Only:$FLAT"]="com.snes9x.Snes9x"
		["Xemu(Xbox) Only:$FLAT"]="app.xemu.xemu"
		["Rpcs3(PS3) Only:$FLAT"]="net.rpcs3.RPCS3"
		["Vita3K(PS Vita) Only:$AURT"]="vita3k-bin"
		["Mednafen(Multi) Only:$FLAT"]="com.github.AmatCoder.mednaffe"
		["Flycast(Dreamcast) Only:$FLAT"]="flycast-git|org.flycast.Flycast"
		["Xenia Canary(Xbox360) Only:$AURT"]="xenia-canary-bin"
	)
	emulator_list3=(
		["Mesen(Multi) Only:$AURT"]="mesen2-git"
		["Ares(Multi) Only:$FLAT"]="dev.ares.ares"
		["RetroArch(Multi)"]="retroarch|org.libretro.RetroArch"
		["Eden(Switch) Only:$AURT"]="eden-bin"
		["Citron(Switch-Yuzu) Only:$AURT"]="citron"
		["DuckStation(PSX) Only:$FLAT -Deprecated"]="org.duckstation.DuckStation"
	)
}
# -----------------------------------------------------------------------------
# Display the available software, ask the user to make a choice, 
# and populate the global 'selected_packages' variable accordingly.
# -----------------------------------------------------------------------------
function select_and_install() {
    declare -n software_list=$1
    local -r software_type=$2
    local i=1
    local options=()
    local input
    echo "${GREEN}${software_type}${RESET} :"
    for software in "${!software_list[@]}"; do
        printf " ${PURPLE}%2d${RESET}) %s\n" "$i" "$software"
        options+=("$software")
        ((i++))
    done
    echo "${BLUE}::${RESET} Packages to install (${CYAN}e.g., 1 2 3, 1-3, all or press enter to skip):${RESET} "
    read -ra input
    for item in "${input[@]}"; do
        if [[ "$item" == "$(eval_gettext "all")" ]]; then
            for software in "${!software_list[@]}"; do
                selected_packages+=" ${software_list[$software]} "
            done
            break
        elif [[ $item =~ ^[0-9]+$ ]]; then
            selected_packages+=" ${software_list[${options[$item - 1]}]} "
        elif [[ $item =~ ^[0-9]+-[0-9]+$ ]]; then
            IFS='-' read -ra range <<<"$item"
            for ((j = ${range[0]}; j <= ${range[1]}; j++)); do
                selected_packages+=" ${software_list[${options[$j - 1]}]} "
            done
        fi
    done
}
# Main function:
# 1. Initialize software lists
# 2. Let user select and install
# 3. Perform post-install actions (groups, timers, etc.)
# 4. Manage firewall configuration (firewalld and ufw) if needed
function install_software() {
	# Ask how to install software when both Flatpak and native versions exist
	prompt_choice INSTALL_METHOD "Choose preferred software installation method" "Native" "Flatpak"
    # 1. Initialize lists
    set_software_list
    select_and_install browser_list "Browsers"
	select_and_install accessibility_list "Accessibility Apps"
    select_and_install system_list "System Software"
    select_and_install desktop_list "Desktop Apps P1"
	select_and_install desktop_list2 "Desktop Apps P2"
	select_and_install desktop_list3 "Desktop Apps P3"
    select_and_install video_list "Video Software"
    select_and_install picture_list "Image Editors"
    select_and_install gaming_list "Gaming Software"
	select_and_install gaming_list2 "Gaming Software P2"
	select_and_install emulator_list "Gaming Emulator Software"
	select_and_install emulator_list2 "Gaming Emulator Software P2"
	select_and_install emulator_list3 "Gaming Emulator Software P3"
    # Retrieve selected packages to install
    local -r packages="${selected_packages}"
    selected_packages=""
    # install_lst "${packages}"
	install_package "${packages}"
    # Arch Update
    if [[ "${packages}" =~ "arch-update" ]]; then
		echo "Enable arch-update.timer"
        systemctl --user enable arch-update.timer
		echo "Enable arch-update tray"
        arch-update --tray --enable
    fi
    if [[ "${packages}" =~ "openrazer-daemon" ]]; then
		echo "Add the current user to the plugdev group"
        sudo usermod -aG plugdev $(whoami)
    fi
    if [[ "${packages}" =~ "virtualbox" ]]; then
		echo "Add the current user to the vboxusers group"
        sudo usermod -aG vboxusers $(whoami)
		echo "Enable vboxweb"
        sudo systemctl enable vboxweb.service
    fi
    if [[ "${packages}" =~ "virt-manager" ]]; then
		echo "Add the current user to the libvirt group"
        sudo usermod -aG libvirt $(whoami)
		echo "Add the current user to the kvm group"
        sudo usermod -aG kvm $(whoami)
		echo "Enable libvirtd"
        sudo systemctl enable --now libvirtd
        # Configure libvirtd socket (permissions)
        sudo sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' /etc/libvirt/libvirtd.conf
        sudo sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf
        # -- Open relevant ports if firewalld is installed
        if command -v firewall-cmd >/dev/null 2>&1; then
            sudo firewall-cmd --permanent --add-service=libvirt &> /dev/null
            sudo firewall-cmd --permanent --add-port=5900-5999/tcp &> /dev/null
            sudo firewall-cmd --permanent --add-port=16509/tcp &> /dev/null
            sudo firewall-cmd --permanent --add-port=5666/tcp &> /dev/null
            sudo firewall-cmd --reload &> /dev/null
        fi
        # -- Open the same ports if ufw is installed
        if command -v ufw >/dev/null 2>&1; then
            sudo ufw allow 5900:5999/tcp
            sudo ufw allow 16509/tcp
            sudo ufw allow 5666/tcp
            sudo ufw reload &> /dev/null
        fi
    fi
    # Gamemode
    if [[ "${packages}" =~ "gamemode" ]]; then
		echo "Add the current user to the gamemode group"
        sudo usermod -aG gamemode $(whoami)
	fi
        # Default configuration for /etc/gamemode.ini
	if [ ! -f /etc/gamemode.ini ]; then
	sudo tee /etc/gamemode.ini > /dev/null <<EOF
[general]
reaper_freq=5
desiredgov=performance
desiredgov=performance
igpu_desiredgov=powersave
igpu_power_threshold=0.3
softrealtime=off
renice=0
ioprio=0
inhibit_screensaver=1
disable_splitlock=1

[filter]
;whitelist=RiseOfTheTombRaider
;blacklist=HalfLife3

[gpu]
;apply_gpu_optimisations=0
;gpu_device=0
;nv_powermizer_mode=1
;nv_core_clock_mhz_offset=0
;nv_mem_clock_mhz_offset=0
;amd_performance_level=high

[cpu]
;park_cores=no
;pin_cores=yes

[supervisor]
;supervisor_whitelist=
;supervisor_blacklist=
;require_supervisor=0

[custom]
;start=notify-send "GameMode started"
;end=notify-send "GameMode ended"
;script_timeout=10'
EOF
fi
    # Firewall
    if [[ "${packages}" =~ "steam" ]]; then
        if command -v firewall-cmd >/dev/null 2>&1; then
            # Steam Remote Play https://help.steampowered.com/en/faqs/view/0689-74B8-92AC-10F2
            sudo firewall-cmd --permanent --add-port=27031-27036/udp &> /dev/null
            sudo firewall-cmd --permanent --add-port=27036/tcp &> /dev/null
            sudo firewall-cmd --permanent --add-port=27037/tcp &> /dev/null
            sudo firewall-cmd --reload &> /dev/null
        fi
        if command -v ufw >/dev/null 2>&1; then
            # Steam Remote Play https://help.steampowered.com/en/faqs/view/0689-74B8-92AC-10F2
            sudo ufw allow 27031:27036/udp
            sudo ufw allow 27036/tcp
            sudo ufw allow 27037/tcp
            sudo ufw reload &> /dev/null
        fi
    fi
}
# Main installation
echo -e "${ORANGE}It will automatically download and use yay to install the required software. The multilib repository will also be enabled automatically.${RESET}"
echo -e "${ORANGE}Please ensure that you have a backup of your important data before proceeding.${RESET}"
echo -e "${ORANGE}Do you want to proceed? (y/n)${RESET}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation aborted.${RESET}"
    exit 1
fi
# Ask for sudo rights
sudo -v
# Keep sudo rights
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
sudo pacman -Syyu --noconfirm
read -n1 -p "Press any key to continue"
check_os
check_internet
config_pacman
install_aur
install_headers
configure_sysctl_tweaks
setup_sound
setup_boot_loaders
setup_flatpak
usefull_packages
firewall
shell_config
add_groups_to_user
video_drivers
gamepad
printer
bluetooth
detect_de
# Ask about restart
echo -e "${GREEN}Script completed succesfully. Do you want to restart your system to apply all changes now?(y/n)${RESET}"
read -r restart_response
if [[ "$restart_response" =~ ^[Yy]$ ]]; then
    sudo reboot now
else
    echo -e "${RED}No restart selected${RESET}"
fi
