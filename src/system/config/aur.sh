# Load shared functions
source src/cmd.sh

function install_aur() {
    # Ensure Git, MakePKG is installed (required to clone AUR helper repositories)
	local inlst="
		git
		base-devel
	"
	install_lst "${inlst}"

    # Define AUR helpers and their respective Git URLs
    local -r aur_helpers=("yay" "paru")
    local -r aur_repos=("https://aur.archlinux.org/yay-bin.git" "https://aur.archlinux.org/paru-bin.git")
    local -r aur_dirs=("yay-bin" "paru-bin")

    local choice=""
    local index=-1
	
	# Auto-detect if yay or paru is already installed
    if command -v yay &>/dev/null; then
        choice="yay"
        index=0
        echo "Detected yay is already installed."
    elif command -v paru &>/dev/null; then
        choice="paru"
        index=1
        echo "Detected paru is already installed."
    fi
	
	# Prompt user only if neither is installed
    if [[ -z "$choice" ]]; then
        while [[ $choice != "yay" && $choice != "paru" ]]; do
		# Prompt user to choose an AUR helper
            read -rp "Which AUR helper do you want to install? ${CYAN}(yay/paru)${RESET}: " choice
            choice="${choice,,}"  # Lowercase
        done

        echo "${GREEN}You chose ${choice}${RESET}"
		# Determine index and export AUR helper name
        case "$choice" in
            yay) index=0 ;;
            paru) index=1 ;;
        esac
    fi

    export AUR="${aur_helpers[$index]}"

    # Install the chosen AUR helper if not already installed
    if ! pacman -Qi "$AUR" &>/dev/null; then
        local dir="${aur_dirs[$index]}"
        exec_log "git clone ${aur_repos[$index]}" "Cloning $dir"

        # Temporarily allow pacman to run without password
        exec_log "\"$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman\" | sudo tee /etc/sudoers.d/99-pacman-nopasswd >/dev/null" \
            "Allowing pacman without password temporarily"

        pushd "$dir" >/dev/null || return 1
        exec_log "makepkg -si --noconfirm" "Installing $AUR"
        popd >/dev/null || return 1

        # Clean up
        exec_log "sudo rm -f /etc/sudoers.d/99-pacman-nopasswd" "Removing temporary sudoers rule"
        exec_log "rm -rf $dir" "Deleting directory $dir"
    fi

    # Post-install configuration
    case "$AUR" in
        yay)
            exec_log "yay -Y --gendb" "Generating DB for $AUR"
            exec_log "yay -Y --devel --save" "Auto-updating Git-based AUR packages"
            exec_log "sed -i 's/\"sudoloop\": false,/\"sudoloop\": true,/' ~/.config/yay/config.json" \
                "Enabling SudoLoop option for yay"
            ;;
        paru)
            exec_log "paru --gendb" "Generating DB for $AUR and auto-updating Git-based AUR packages"
            local paru_conf="/etc/paru.conf"
            exec_log "sudo sed -i 's/#BottomUp/BottomUp/' $paru_conf" \
                "Enabling BottomUp option for paru"
            exec_log "sudo sed -i 's/#SudoLoop/SudoLoop/' $paru_conf" \
                "Enabling SudoLoop option for paru"
            exec_log "sudo sed -i 's/#CombinedUpgrade/CombinedUpgrade/' $paru_conf" \
                "Enabling CombinedUpgrade option for paru"
            exec_log "sudo sed -i 's/#UpgradeMenu/UpgradeMenu/' $paru_conf" \
                "Enabling UpgradeMenu option for paru"
            exec_log "sudo sed -i 's/#NewsOnUpgrade/NewsOnUpgrade/' $paru_conf" \
                "Enabling NewsOnUpgrade option for paru"

            # Only add SkipReview if it's not already present
            exec_log "if ! grep -qxF \"SkipReview\" \"$paru_conf\"; then sudo sh -c 'echo \"SkipReview\" >> \"$paru_conf\"'; fi" \
                "Enabling SkipReview option for paru"
            ;;
    esac
}
