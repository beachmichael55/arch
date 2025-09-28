# Load shared functions
source src/cmd.sh

################################################################################
# Bluetooth-related installations
################################################################################
function bluetooth() {
    if ask_question "echo Do you want to use Bluetooth?"; then
        local -r inlst="
            bluez
            bluez-plugins
            bluez-utils
            bluez-hid2hci
            bluez-libs
        "

        install_lst "${inlst}"

        # Enable the Bluetooth service
        exec_log "sudo systemctl enable bluetooth" "echo Enabling bluetooth service"
    fi
}
