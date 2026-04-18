#!/bin/bash
if command -v yay &> /dev/null; then
        AUR=yay
elif command -v paru &> /dev/null; then
        AUR=paru
fi
## sudo pacman -S --noconfirm --needed egl-wayland nvidia-utils lib32-opencl-nvidia libvdpau-va-gl libvdpau libva-nvidia-driver nvidia-open-dkms nvidia-prime

sudo pacman -S --noconfirm --needed intel-media-driver xf86-video-intel xorg-xrandr mesa lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-mesa-layers libva-mesa-driver lib32-libva-mesa-driver cuda

$AUR -S --noconfirm nvidia-580xx-dkms nvidia-580xx-settings
if ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
    sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
   else
    echo "NVIDIA modules already present in mkinitcpio.conf"
fi
if [[ "$AUR" == "yay" ]]; then
		yay -S --noconfirm optimus-manager-git
		yay --getpkgbuild optimus-manager-qt && cd optimus-manager-qt && sed -i 's/_with_plasma=false/_with_plasma=true/' PKGBUILD && makepkg -si
	fi
	if [[ "$AUR" == "paru" ]]; then
		paru -S --noconfirm optimus-manager-git
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

sudo mkinitcpio -P

prime-run gamescope -f -- steam -gamepadui

If your distro doesn't include prime-run, use:

__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
gamescope -f -- steam -gamepadui

-f = fullscreen gamescope session.

Step 2 — Create the launcher script

Create a script so the .desktop file stays clean.

mkdir -p ~/.local/bin
nano ~/.local/bin/steam-gamescope-nvidia

Script:

#!/usr/bin/env bash

export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

exec gamescope -f -- steam -gamepadui

Make it executable:

chmod +x ~/.local/bin/steam-gamescope-nvidia
Step 3 — Create the .desktop file
nano ~/.local/share/applications/steam-gamescope.desktop

Example:

[Desktop Entry]
Name=Steam Big Picture (NVIDIA Gamescope)
Comment=Launch Steam Big Picture using Gamescope on NVIDIA GPU
Exec=/home/YOURUSER/.local/bin/steam-gamescope-nvidia
Icon=steam
Terminal=false
Type=Application
Categories=Game;
