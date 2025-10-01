# Load shared functions
source src/cmd.sh

# Configure pacman and makepkg with user-friendly and performance settings
function config_pacman() {
    # Enable color output in pacman
    exec_log "sudo sed -i 's/^#Color$/Color/' '/etc/pacman.conf'" "Enabling color in pacman"
    # Enable verbose package lists
    exec_log "sudo sed -i 's/^#VerbosePkgLists$/VerbosePkgLists/' '/etc/pacman.conf'" "Enabling verbose package lists in pacman"
    # Enable the multilib repository
    exec_log "sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' '/etc/pacman.conf'" "Enabling multilib repository"
    # Set MAKEFLAGS to use all available CPU cores for compilation (can cause system hangs)
	# (can cause system hangs)
		# exec_log "sudo sed -i 's/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j\$(nproc)\"/' /etc/makepkg.conf" "Enabling multithread compilation"
    # Full system upgrade
    exec_log "sudo pacman -Syyu --noconfirm" "Updating full system ${RED}(might be long)${RESET}"
    # Install pacman-contrib for tools like paccache
    exec_log "sudo pacman -S pacman-contrib --noconfirm" "Installing pacman-contrib"
    # Enable automatic cleaning of old package versions
    exec_log "sudo systemctl enable paccache.timer" "Enabling paccache timer"
    # Remove existing update-mirrors script if it exists
    if [[ -f /usr/bin/update-mirrors ]]; then
        exec_log "sudo rm /usr/bin/update-mirrors" "Removing existing update-mirrors script"
    fi
    # Create /usr/bin/update-mirrors script using proper EOF formatting
    exec_log "sudo tee /usr/bin/update-mirrors > /dev/null << 'EOF'
#!/bin/bash
tmpfile=\$(mktemp)
echo \"Using temporary file: \$tmpfile\"
rate-mirrors --save=\$tmpfile arch --max-delay=43200 && \\
  sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup && \\
  sudo mv \$tmpfile /etc/pacman.d/mirrorlist && \\
  sudo pacman -Syyu
EOF" "Creating update-mirrors script"

    # Make it executable
    exec_log "sudo chmod +x /usr/bin/update-mirrors" "Making update-mirrors script executable"
	
	# Ask to insall and enable Archlinuxcn Repository (Chinese Community) Repository
	if ask_question "Do you want to install and setup 'Archlinuxcn Repository' ${RED}say No if unsure${RESET} /!\  ?"; then
		# Adds the repository to pacman and imports it's keys
		exec_log "echo -e '\n[archlinuxcn]\nServer = https://repo.archlinuxcn.org/\$arch' | sudo tee -a /etc/pacman.conf" "Adding archlinuxcn repo"
		exec_log "sudo pacman -Sy && sudo pacman -S archlinuxcn-keyring" "Importing Archlinuxcn PGP Keys"
	fi
}

# Optimize and update mirrorlist using rate-mirrors wrapper
function mirrorlist() {

    # Ensure rate-mirrors is installed
    install_mixed_lst "rate-mirrors-bin"

    # Use the new /usr/bin/update-mirrors binary
    exec_log "update-mirrors" "Running update-mirrors"
}
