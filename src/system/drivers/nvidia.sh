source src/cmd.sh

# Ensure early loading of NVIDIA modules in initramfs
function nvidia_earlyloading () {
    if ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
        exec_log "sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf" \
        "Adding NVIDIA modules to mkinitcpio.conf"
    else
        log "NVIDIA modules already present in mkinitcpio.conf"
    fi
}

# Optional installation of Intel GPU drivers for hybrid laptops
function nvidia_intel() {
    if ask_question "Do you have an Intel/Nvidia Laptop ?"; then
        local -r inlst="
            intel-media-driver
            intel-gmmlib
            onevpl-intel-gpu
			xf86-video-intel
			xorg-xrandr
			nvidia-prime
			optimus-manager-qt
        "
        install_lst "${inlst}"

		prompt_choice TURING "Do you have Turing (GeForce GTX 1650 - GeForce RTX 2080) card?" "Yes" "No"
		if [[ "${TURING}" == "Yes" ]]; then
			install_mixed_lst "nvidia-dkms"
		 else
			if ask_question "Do you want to use Nvidia's proprietary drivers?(NO means use open-source)"; then
				install_mixed_lst "nvidia-dkms"
			elif
				install_mixed_lst "nvidia-open-dkms"
			fi
		fi
		
    fi
}

function nvidia_desktop() {
	if ask_question "Do you want to use Nvidia's proprietary drivers?(NO means use open-source)"; then
		install_mixed_lst "nvidia-dkms"
	elif
		install_mixed_lst "nvidia-open-dkms"
	fi
}
# Main function to uninstall legacy NVIDIA drivers and install the correct set
function nvidia_drivers() {
    # Install required NVIDIA packages
    local -r inlst="
        nvidia-utils
        lib32-nvidia-utils
        nvidia-settings
        egl-wayland
        lib32-opencl-nvidia
        libvdpau-va-gl
        libvdpau
        libva-nvidia-driver
    "
    install_lst "${inlst}"

    # call early loading NVIDIA fonction
    nvidia_earlyloading

    # Optional Intel GPU driver installation for hybrid laptops
    nvidia_intel
	
	# Ask what Card have
	nvidia_desktop

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
