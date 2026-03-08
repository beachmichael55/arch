#!/bin/bash
function prompt_choice() {
    local var_name=$1
    local prompt=$2
    shift 2
    local options=("$@")
    while true; do
        echo -e "${prompt}"
        for i in "${!options[@]}"; do
            printf "  %s) %s\n" "$((i + 1))" "${options[i]}"
        done
        read -rp "Choice [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            declare -g "$var_name=${options[choice-1]}"
            break
        else
            echo -e "${RED}Invalid option.${RESET} Please enter a number between 1 and ${#options[@]}."
        fi
    done
}
AUR=""
sudo pacman -S git base-devel pkgfile cmake --noconfirm
# Prompt user only if neither is installed
prompt_choice AUR "Which AUR helper do you want to install? ${CYAN}(yay/paru)${RESET}:" "yay" "paru"
if [[ "$AUR" == "yay" ]]; then
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si --noconfirm
    cd .. && rm -rf yay
    export PATH="$PATH:$HOME/.local/bin"
    yay -Y --gendb
    yay -Y --devel --save
    sed -i 's/\"sudoloop\": false,/\"sudoloop\": true,/' ~/.config/yay/config.json
fi
if [[ "$AUR" == "paru" ]]; then
    git clone https://aur.archlinux.org/paru.git
    cd paru || exit
    makepkg -si --noconfirm
    cd .. && rm -rf paru
    export PATH="$PATH:$HOME/.local/bin"
    paru --gendb
    sudo sed -i 's/#BottomUp/BottomUp/' /etc/paru.conf
    sudo sed -i 's/#SudoLoop/SudoLoop/' /etc/paru.conf
    sudo sed -i 's/#CombinedUpgrade/CombinedUpgrade/' /etc/paru.conf
    sudo sed -i 's/#UpgradeMenu/UpgradeMenu/' /etc/paru.conf
    sudo sed -i 's/#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf
    sudo sed -i 's/#SkipReview/SkipReview/' /etc/paru.conf
fi
# for all other packages
# $AUR -S --noconfirm f vmware-workstation
# sudo systemctl enable vmware-networks-configuration vmware-usbarbitrator vmware-hostd
# modprobe -a vmw_vmci vmmon
sudo pacman -S --noconfirm --needed virt-what konsole dolphin ark plasma-meta plasma-workspace print-manager gwenview spectacle partitionmanager ffmpegthumbs qt6-multimedia qt6-multimedia-gstreamer qt6-multimedia-ffmpeg qt6-wayland kdeplasma-addons kcalc plasma-systemmonitor kwalletmanager kio-admin egl-wayland sddm-kcm filelight xdg-desktop-portal-kde kdegraphics-thumbnailers kdialog gtkmm3 pipewire wireplumber pipewire-alsa pipewire-pulse gst-plugin-pipewire alsa-utils libpulse alsa-plugins alsa-ucm-conf sof-firmware rtkit timeshift btrfs-progs btrfs-assistant btrfsmaintenance grub-btrfs timeshift-autosnap flatpak gstreamer gst-plugins-base vulkan-swrast lib32-vulkan-swrast gstreamer-vaapi gst-plugins-good gst-libav gstreamer-vaapi libva-mesa-driver mesa-vdpau libnotify openbsd-netcat xdg-utils rebuild-detector fastfetch power-profiles-daemon ttf-dejavu ttf-liberation ttf-meslo-nerd noto-fonts-emoji adobe-source-code-pro-fonts python-pyqt5 python-capng iproute2 otf-font-awesome ttf-droid ntfs-3g fuse2 fuse2fs fuse3 exfatprogs bash-completion ffmpegthumbs man-db man-pages lsscsi mtools sg3_utils dialog efitools nfs-utils ntp unrar unzip libgsf networkmanager-openvpn networkmanager-l2tp network-manager-applet cpupower nano-syntax-highlighting xdg-desktop-portal btop duf pv jq rsync duperemove curl iperf3 python-pip wine-staging jre-openjdk dkms xorg-server xorg-xinit libappindicator Firewalld ghostscript gsfonts cups cups-filters cups-pdf system-config-printer avahi foomatic-db-engine foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds gutenprint foomatic-db-gutenprint-ppds splix bluez bluez-plugins bluez-utils bluez-hid2hci bluez-libs gamemode lib32-gamemode mangohud lib32-mangohud gamescope restic  mame-tools lutris steam firefox mousetweaks aegisub mediainfo-gui vlc obs-studio switcheroo converseen krita arch-update vim audacity wireshark-qt iperf3 ekpar2 remmina thunderbird syncthing keepassxc calibre qbittorrent libreoffice-fresh rclone-browser k3b distrobox meld discord prismlauncher docker docker-compose
$AUR -S --noconfirm freerdp-git xwaylandvideobridge epson-inkjet-printer-escpr epson-inkjet-printer-escpr2 arch-update
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update -y
flatpak install -y --noninteractive flathub com.protonvpn.www com.github.Bleuzen.FFaudioConverter com.github.nrittsti.NTag net.mkiol.SpeechNote com.heroicgameslauncher.hgl org.freedesktop.Platform.VulkanLayer.vkBasalt//24.08 com.vysp3r.ProtonPlus com.adamcake.Bolt org.freedesktop.Platform.VulkanLayer.MangoHud io.github.radiolamp.mangojuice org.freedesktop.Platform.VulkanLayer.gamescope com.github.Matoking.protontricks net.davidotek.pupgui2 com.github.mtkennerly.ludusavi com.rustdesk.RustDesk com.github.tchx84.Flatseal io.github.Faugus.faugus-launcher com.georgefb.mangareader com.github.zocker_160.SyncThingy com.steamgriddb.SGDBoop com.steamgriddb.steam-rom-manager com.usebottles.bottles com.valvesoftware.SteamLink fr.handbrake.ghb info.febvre.Komikku io.github.dvlv.boxbuddyrs io.github.hakuneko.HakuNeko io.github.ilya_zlobintsev.LACT io.github.peazip.PeaZip io.github.shiiion.primehack org.chromium.Chromium io.gitlab.adhami3310.Converter io.missioncenter.MissionCenter it.mijorus.gearlever org.bionus.Grabber org.DolphinEmu.dolphin-emu org.freefilesync.FreeFileSync org.jdownloader.JDownloader org.x.Warpinator
