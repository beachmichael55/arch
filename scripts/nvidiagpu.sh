#!/bin/bash
sudo pacman -S --noconfirm --needed egl-wayland nvidia-utils ib32-nvidia-utils nvidia-settings lib32-opencl-nvidia libvdpau-va-gl libvdpau libva-nvidia-driver nvidia-open-dkms cuda 
if ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
    sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
    else
    echo "NVIDIA modules already present in mkinitcpio.conf"
fi
sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
sudo mkinitcpio -P
