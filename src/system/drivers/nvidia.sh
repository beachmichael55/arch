source src/cmd.sh

# Ensure early loading of NVIDIA modules in initramfs
function nvidia_earlyloading() {
    if ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
        exec_log "sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf" \
        "Adding NVIDIA modules to mkinitcpio.conf"
    else
        log "NVIDIA modules already present in mkinitcpio.conf"
    fi
}

# Gets the pkgbuild file, then edits 'Plasma' line to enable extra Plasma functions, then builds with changes
function optimus_plasma() {
    exec_log "paru -G optimus-manager-qt && cd optimus-manager-qt && sed -i 's/_with_plasma=false/_with_plasma=true/' PKGBUILD && makepkg -si" \
        "Building optimus-manager-qt with Plasma support"
}

# Optional installation of Intel GPU drivers for hybrid laptops
function nvidia_intel() {
    local -r inlst="
		intel-media-driver
        intel-gmmlib
        onevpl-intel-gpu
		xf86-video-intel
		xorg-xrandr
		nvidia-prime
	"
    install_lst "${inlst}"

	if ask_question "Do you use KDE Plasma?"; then
        optimus_plasma
        echo "For Turing (GeForce RTX 2080 and earlier): Choose [2] for Proprietary."
        echo "For Ampere and later (RTX 3050+): Choose [5] for Open Kernel."
	else
		echo "For Turing (GeForce RTX 2080 and earlier): Choose [2] for Proprietary."
        echo "For Ampere and later (RTX 3050+): Choose [5] for Open Kernel."
		sudo paru -S --noconfirm optimus-manager-qt
    fi
}

function nvidia_desktop() {
    echo "Use open-kernel drivers for GTX 1650+ and newer, otherwise use proprietary."
    if ask_question "Do you want to use NVIDIA's proprietary drivers? (NO means open-kernel)"; then
        install_mixed_lst "nvidia-dkms"
    else
        install_mixed_lst "nvidia-open-dkms"
    fi
}

# Main function to uninstall legacy NVIDIA drivers and install the correct set
function nvidia_drivers() {
    # Install required NVIDIA packages
    local -r inlst="
        egl-wayland
		nvidia-utils
        lib32-nvidia-utils
        nvidia-settings
        lib32-opencl-nvidia
        libvdpau-va-gl
        libvdpau
        libva-nvidia-driver
    "
    install_lst "${inlst}"

    # call early loading NVIDIA fonction
    nvidia_earlyloading

    # Optional Intel GPU driver installation for hybrid laptops
	if ask_question "Is this a laptop (with Intel/NVIDIA hybrid graphics)?"; then
		nvidia_intel
	else
		nvidia_desktop
	fi

    # Optional CUDA installation
    if ask_question "Do you want to install CUDA (${RED}say No if unsure${RESET}) ?"; then
        install_one "cuda"
    fi

    # Enable NVIDIA suspend/resume services
    exec_log "sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service" \
        "Enabling NVIDIA suspend/resume services"

    # Conditionally enable nvidia-powerd if on laptop and GPU is not Turing
    local device_type
    device_type="$(cat /sys/devices/virtual/dmi/id/chassis_type)"
    if ((device_type >= 8 && device_type <= 11)); then
        # Check for Turing GPUs (Device name starts with "TU")
        if ! lspci -d "10de:*:030x" -vm | grep -q 'Device:\s*TU'; then
            exec_log "sudo systemctl enable nvidia-powerd.service" \
                "Enabling NVIDIA PowerD for supported laptop GPU"
        else
            log "NVIDIA PowerD is not supported on Turing GPUs"
        fi
    else
        log "Not a laptop chassis; skipping NVIDIA PowerD"
    fi
}
