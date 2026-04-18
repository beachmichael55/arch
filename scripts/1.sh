#!/bin/bash
# Enable color output in pacman
if ! grep -q "^#Color" /etc/pacman.conf; then
    echo "Color output is already enabled.."
else
    sudo sed -i 's/^#Color$/Color/' '/etc/pacman.conf'
fi
# Enable verbose package lists
if ! grep -q "^#VerbosePkgLists" /etc/pacman.conf; then
    echo "Verbose package lists is already enabled.."
else
    sudo sed -i 's/^#VerbosePkgLists$/VerbosePkgLists/' '/etc/pacman.conf'
fi
# Enable Multilib(32bit) package lists
if grep -q "^#\[multilib\]" /etc/pacman.conf; then
    sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
else
    echo "Multilib repository already enabled."
fi
sudo pacman -Syyu --noconfirm
sudo pacman -S --noconfirm --needed pacman-contrib
sudo systemctl enable paccache.timer
local kernel_headers=()
for kernel in /boot/vmlinuz-*; do
    [ -e "${kernel}" ] || continue
    kernel_headers+=("$(basename "${kernel}" | sed -e 's/vmlinuz-//')-headers")
done
for header in "${kernel_headers[@]}"; do
    sudo pacman -S --noconfirm --needed "$header"
done

CPU=$(grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}')
if [[ "$CPU" == "GenuineIntel" ]]; then
sudo pacman -S --needed --noconfirm intel-ucode
fi
if [[ "$CPU" == "AuthenticAMD" ]]; then
sudo pacman -S --needed --noconfirm amd-ucode
fi
