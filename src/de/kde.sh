# Source the script from src/cmd.sh
source src/cmd.sh

# Function to install KDE applications
function install_kde() {
    # Define a list of KDE applications to install
    local -r inlst="
        konsole
        kwrite
        dolphin
        ark
        plasma-meta
		plasma-workspace
        print-manager
        gwenview
        spectacle
        partitionmanager
        ffmpegthumbs
        qt6-multimedia
        qt6-multimedia-gstreamer
        qt6-multimedia-ffmpeg
        qt6-wayland
        kdeplasma-addons
        kcalc
        plasma-systemmonitor
        kwalletmanager
		kio-admin
		egl-wayland 
		sddm-kcm
		filelight
		xdg-desktop-portal-kde
		kdegraphics-thumbnailers
		kdialog
    "

    # Call the install_lst function to install the listed applications
    install_lst "${inlst}"

    # Check if the SDDM configuration file exists
    if [ ! -f /etc/sddm.conf ]; then
        # Create the SDDM configuration file if it doesn't exist
        exec_log "sudo touch /etc/sddm.conf" "Creating /etc/sddm.conf"
    fi

    # Set the Breeze theme for SDDM
    exec_log "echo -e '[Theme]\nCurrent=breeze' | sudo tee -a /etc/sddm.conf" "Setting Breeze theme for SDDM"

    # Enable Numlock for SDDM
    exec_log "echo -e '[General]\nNumlock=on' | sudo tee -a /etc/sddm.conf" "Setting Numlock=on for SDDM"
}
