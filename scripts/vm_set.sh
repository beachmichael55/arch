#!/bin/bash
sudo pacman -S --noconfirm --needed virt-what
vm="$(sudo virt-what)"
if [[ ${vm} =~ (^|[[:space:]])virtualbox($|[[:space:]]) ]]; then
    sudo pacman -S --noconfirm --needed virtualbox-guest-utils
    sudo systemctl enable vboxservice
    sudo VBoxClient-all
fi
if [[ ${vm} =~ (^|[[:space:]])vmware($|[[:space:]]) ]]; then
    sudo pacman -S --noconfirm --needed open-vm-tools
    sudo systemctl enable vmtoolsd
    sudo systemctl enable vmware-vmblock-fuse
else
    # Otherwise, assume QEMU or similar and install its agents
    sudo pacman -S --noconfirm --needed spice-vdagent qemu-guest-agent
fi
