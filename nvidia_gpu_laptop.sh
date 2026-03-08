#!/bin/bash
if command -v yay &> /dev/null; then
        AUR=yay
elif command -v paru &> /dev/null; then
        AUR=paru
fi
sudo pacman -S --noconfirm --needed intel-media-driver intel-gmmlib onevpl-intel-gpu xf86-video-intel xorg-xrandr egl-wayland nvidia-utils ib32-nvidia-utils nvidia-settings lib32-opencl-nvidia libvdpau-va-gl libvdpau libva-nvidia-driver cuda nvidia-open-dkms nvidia-prime
##$AUR -S --noconfirm nvidia-580xx-dkms
if ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
    sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
    else
    echo "NVIDIA modules already present in mkinitcpio.conf"
fi
if [[ "$AUR" == "yay" ]]; then
		yay --getpkgbuild optimus-manager-qt && cd optimus-manager-qt && sed -i 's/_with_plasma=false/_with_plasma=true/' PKGBUILD && makepkg -si
	fi
	if [[ "$AUR" == "paru" ]]; then
		paru -G optimus-manager-qt && cd optimus-manager-qt && sed -i 's/_with_plasma=false/_with_plasma=true/' PKGBUILD && makepkg -si
	fi
sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
device_type="$(cat /sys/devices/virtual/dmi/id/chassis_type)"
if ((device_type >= 8 && device_type <= 11)); then
    if ! lspci -d "10de:*:030x" -vm | grep -q 'Device:\s*TU'; then
    echo "Enabling NVIDIA PowerD for supported laptop GPU"
        sudo systemctl enable nvidia-powerd.service
    else
        echo "NVIDIA PowerD is not supported on Turing GPUs"
fi
