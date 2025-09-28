# Configure GRUB bootloader and setup automatic config regeneration with pacman hook

# Load shared functions
source src/cmd.sh
source src/system/grub-btrfs.sh

function setup_system_loaders() {
    log_msg "Checking if GRUB is installed"

    # Only continue if the system uses GRUB
    if [[ $BOOT_LOADER != "grub" ]]; then
        return
    fi

    # Ensure pacman hook directory exists
    exec_log "sudo mkdir -p /etc/pacman.d/hooks" "Creating /etc/pacman.d/hooks"

    # Create GRUB regeneration hook if it doesn't exist
    if [ ! -f /etc/pacman.d/hooks/grub.hook ]; then
        exec_log "sudo tee /etc/pacman.d/hooks/grub.hook > /dev/null << 'EOF'
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
" "Setting up GRUB hook"
    fi

    # Enable OS prober for dual-boot detection
    install_one "os-prober"
    exec_log "sudo sed -i 's/#\s*GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' '/etc/default/grub'" "Enabling os-prober"
    exec_log "sudo os-prober" "Running os-prober"
    exec_log "sudo grub-mkconfig -o /boot/grub/grub.cfg" "Updating GRUB"

    # Install grub-btrfs if btrfs is used and package is not present
    if ! pacman -Q grub-btrfs &> /dev/null && [[ ${BTRFS} == true ]]; then
        grub-btrfs
    fi
}
