#!/bin/bash
if command -v yay &> /dev/null; then
        AUR=yay
elif command -v paru &> /dev/null; then
        AUR=paru
fi
$AUR -S --noconfirm joystickwake xpadneo-dkms-git xone-dkms-git xone-dongle-firmware dualsensectl-git
