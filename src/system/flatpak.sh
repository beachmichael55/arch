# Load shared functions
source src/cmd.sh

# -----------------------------------------------------------------------------
# Install Flatpak and configure Flathub
# -----------------------------------------------------------------------------
function setup_flatpak() {
	local inlst="
	flatpak
	"
	install_lst "${inlst}"
    # Add Flathub if not already added
    if ! flatpak remote-list | grep -q flathub; then
        exec_log "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo" \
                 "${GREEN}[Flatpak]${RESET} Add Flathub remote"
    fi
    # Update flatpak repos
    exec_log "flatpak update -y" "${GREEN}[Flatpak]${RESET} Update Flatpak packages"
}