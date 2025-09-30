# =============================================================================
# Software installation script with automatic configuration if needed
# =============================================================================

# Load shared functions
source src/cmd.sh

set "FLAT=Flatpak"
set "AURT=Aur"

# Declare associative arrays for each software category
declare -A desktop_list
declare -A desktop_list2
declare -A desktop_list3
declare -A system_list
declare -A browser_list
declare -A accessibility_list
declare -A video_list
declare -A picture_list
declare -A gaming_list
declare -A gaming_list2
declare -A emulator_list
declare -A emulator_list2
declare -A emulator_list3

# Will store the complete list of packages to install
selected_packages=""

# -----------------------------------------------------------------------------
# Define software choices for each category
# -----------------------------------------------------------------------------
function set_software_list() {
    desktop_list=(
        ["Discord"]="discord|com.discordapp.Discord"
		["Vesktop"]="vesktop-bin|dev.vencord.Vesktop"
		["Ulauncher"]="ulauncher"
		["Meld"]="meld|org.gnome.meld"
		["Distrobox"]="distrobox|io.github.dvlv.boxbuddyrs"
        ["Kate"]="kate|org.kde.kate"
		["K3B"]="k3b"
		["RCloneBrowser"]="rclone-browser"
        ["LibreOffice"]="libreoffice-fresh|org.libreoffice.LibreOffice"
    )
	desktop_list2=(
		["Qbittorrent"]="qbittorrent|org.qbittorrent.qBittorrent"
		["Calibre"]="calibre|com.calibre_ebook.calibre"
		["Keepassxc"]="keepassxc|org.keepassxc.KeePassXC"
		["Syncthing"]="syncthing|com.github.zocker_160.SyncThingy"
		["Syncthing Tray 'Not Needed with 'Syncthing'"]="syncthingtray"
		["Thunderbird"]="thunderbird|org.mozilla.Thunderbird"
		["Filezilla"]="filezilla|org.filezillaproject.Filezilla"
		["Remmina"]="remmina|org.remmina.Remmina.desktop"
		["ProtonVPN"]="proton-vpn-gtk-app|com.protonvpn.www"
		["Switcheroo"]="switcheroo|io.gitlab.adhami3310.Converter"
	)
	desktop_list3=(
		["IPerf"]="iperf3"
		["Wireshark"]="wireshark|org.wireshark.Wireshark"
		["Audacity"]="audacity|org.audacityteam.Audacity"
		["Notepadqq"]="|com.notepadqq.Notepadqq"
		["FFaudioConverter"]="|com.github.Bleuzen.FFaudioConverter"
		["NTag"]="|com.github.nrittsti.NTag"
		["SpeechNote"]="net.mkiol.SpeechNote"
	)
    system_list=(
        ["Open RGB"]="openrgb i2c-tools"
        ["Open Razer"]="openrazer-daemon libnotify polychromatic"
        ["Arch Update"]="arch-update vim"
		["Virtualbox"]="virtualbox virtualbox-host-dkms virtualbox-guest-iso"
        ["Virtmanager"]="qemu-full libvirt virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat dmidecode libguestfs guestfs-tools"
    )

    picture_list=(
        ["Gimp"]="gimp|org.gimp.GIMP"
        ["Krita"]="krita|org.kde.krita"
        ["Inkscape"]="inkscape|org.inkscape.Inkscape"
        ["Blender"]="blender|org.blender.Blender"
		["Digikam"]="digikam|org.kde.digikam.desktop"
		["Converseen"]="converseen|net.fasterland.converseen"
    )

    video_list=(
        ["Kdenlive(A non-linear video editor for Linux)"]="kdenlive|org.kde.kdenlive"
        ["OBS Studio(software for live streaming and recording)"]="obs-studio|com.obsproject.Studio"
        ["VLC(multimedia player)"]="vlc|org.videolan.VLC"
        ["MPV(minimalistic media player)"]="mpv|io.mpv.Mpv"
		["mediainfo(Supplies technical and tag information about media files)"]="mediainfo-gui|net.mediaarea.MediaInfo"
		["Aegisub (general-purpose subtitle editor)"]="aegisub|org.aegisub.Aegisub"
    )

    browser_list=(
        ["Firefox (Mozilla web browser)"]="firefox|org.mozilla.firefox"
		["Firefox Beta (Mozilla web browser - Beta branch)"]="firefox-beta-bin"
        ["Brave (Chromium-based 'Private' web browser)"]="brave-bin|com.brave.Browser"
        ["Chromium (Ungoogled Chromium-based web browser)"]="chromium|org.chromium.Chromium"
        ["Vivaldi (Chromium-based 'Private' web browser)"]="vivaldi vivaldi-ffmpeg-codecs|com.vivaldi.Vivaldi"
        ["Google Chrome (Googles web browser)"]="google-chrome|com.google.Chrome"
        ["Microsoft Edge (Microsoft web browser)"]="microsoft-edge-stable-bin|com.microsoft.Edge"
		["Pipeline (Client for Youtube watch, download,make 'Subscriptions without Login)"]="de.schmidhuberj.tubefeeder"
    )
	accessibility_list=(
        ["ESpeakup (light weight connector for espeak-ng and speakup)"]="espeakup"
        ["MouseTweaks (Mouse accessibility enhancements)"]="mousetweaks"
		["Orca (Screen reader for individuals who are blind or visually impaired)"]="orca"
    )
    gaming_list=(
        ["Steam (Game Launcher/Manager/Store) Only:Native"]="steam"
        ["Lutris (Game Launcher/Manager)"]="lutris|net.lutris.Lutris"
        ["Heroic Games Launcher(Game Launcher/Manager/Store) Only:AURT"]="com.heroicgameslauncher.hgl"
        ["Prism Launcher (Minecraft)"]="prismlauncher|org.prismlauncher.PrismLauncher"
		["vkBasalt (Vulkan post processing layer-ReShade)"]="org.freedesktop.Platform.VulkanLayer.vkBasalt//24.08"
		["ProtonPlus (Manage supported compatibility tools across supported launchers)"]="com.vysp3r.ProtonPlus"
		["MameTools (Tools for emulators:chdman)"]="mame-tools"
		["Restic (Fast, secure, efficient backup program)"]="restic"
        ["RuneLite (Old School RuneScape client)"]="runelite|net.runelite.RuneLite"
    )
	gaming_list2=(
		["Goverlay/Mangohud (GUI to help manage Vulkan/OpenGL overlays)"]="mangohud lib32-mangohud gamescope goverlay org.freedesktop.Platform.VulkanLayer.MangoHud /
		org.freedesktop.Platform.VulkanLayer.MangoHud org.freedesktop.Platform.VulkanLayer.gamescope"
		["ProtonTricks (Apps and fixes for Proton games)"]="com.github.Matoking.protontricks"
        ["Gamemode (Daemon that allows games to request a set of optimisations)"]="gamemode lib32-gamemode"
		["ProtonUp QT (Install Wine- and Proton-based compatibility tools)"]="net.davidotek.pupgui2"
		["Moonlight (Client for Sunshine server)"]="moonlight-qt|com.moonlight_stream.Moonlight"
		["Sunshine (Self-hosted game stream host for Moonlight)"]="dev.lizardbyte.app.Sunshine"
		["Ludusavi (backing up your PC video game save data)"]="com.github.mtkennerly.ludusavi"
	)
	emulator_list=(
		["Ryubing(Switch-Ryujinx) Only:$FLAT"]="io.github.ryubing.Ryujinx"
		["Azahar(3DS) Only:$FLAT"]="org.azahar_emu.Azahar"
		["Cemu(WiiU) Only:$FLAT"]="info.cemu.Cemu"
		["PPSSPP(PSP) Only:$FLAT"]="org.ppsspp.PPSSPP"
		["mGBA(GameBoy Adv) Only:$FLAT"]="io.mgba.mGBA"
		["Pcsx2(PS2) Only:$FLAT"]="net.pcsx2.PCSX2"
		["melonDS(DS) Only:$FLAT"]="net.kuribo64.melonDS"
		["PrimeHack(Metroid Prime) Only:$FLAT"]="io.github.shiiion.primehack"
		["Rosalies Mupen GUI(N64) Only:$FLAT"]="com.github.Rosalie241.RMG"
	)
	emulator_list2=(
		["ShadPS4(PS4) Only:$FLAT"]="net.shadps4.shadPS4"
		["Dolphin(GC-Wii) Only:$FLAT"]="org.DolphinEmu.dolphin-emu"
		["Snes9x(SNES) Only:$FLAT"]="com.snes9x.Snes9x"
		["Xemu(Xbox) Only:$FLAT"]="app.xemu.xemu"
		["Rpcs3(PS3) Only:$FLAT"]="net.rpcs3.RPCS3"
		["Vita3K(PS Vita) Only:$AURT"]="vita3k-bin"
		["Mednafen(Multi) Only:$FLAT"]="com.github.AmatCoder.mednaffe"
		["Flycast(Dreamcast) Only:$FLAT"]="flycast-git|org.flycast.Flycast"
		["Xenia Canary(Xbox360) Only:$AURT"]="xenia-canary-bin"
	)
	emulator_list3=(
		["Mesen(Multi) Only:$AURT"]="mesen2-git"
		["Ares(Multi) Only:$FLAT"]="dev.ares.ares"
		["RetroArch(Multi)"]="retroarch|org.libretro.RetroArch"
		["Eden(Switch) Only:$AURT"]="eden-bin"
		["Citron(Switch-Yuzu) Only:$AURT"]="citron"
		["DuckStation(PSX) Only:$FLAT -Deprecated"]="org.duckstation.DuckStation"
	)
}

# -----------------------------------------------------------------------------
# Display the available software, ask the user to make a choice, 
# and populate the global 'selected_packages' variable accordingly.
# -----------------------------------------------------------------------------
function select_and_install() {
    declare -n software_list=$1
    local -r software_type=$2
    local i=1
    local options=()
    local input

    echo "${GREEN}${software_type}${RESET} :"
    for software in "${!software_list[@]}"; do
        printf " ${PURPLE}%2d${RESET}) %s\n" "$i" "$software"
        options+=("$software")
        ((i++))
    done

    echo "${BLUE}::${RESET} Packages to install (${CYAN}e.g., 1 2 3, 1-3, all or press enter to skip):${RESET} "
    read -ra input

    for item in "${input[@]}"; do
        if [[ "$item" == "$(eval_gettext "all")" ]]; then
            for software in "${!software_list[@]}"; do
                selected_packages+=" ${software_list[$software]} "
            done
            break
        elif [[ $item =~ ^[0-9]+$ ]]; then
            selected_packages+=" ${software_list[${options[$item - 1]}]} "
        elif [[ $item =~ ^[0-9]+-[0-9]+$ ]]; then
            IFS='-' read -ra range <<<"$item"
            for ((j = ${range[0]}; j <= ${range[1]}; j++)); do
                selected_packages+=" ${software_list[${options[$j - 1]}]} "
            done
        fi
    done
}

# -----------------------------------------------------------------------------
# Main function:
# 1. Initialize software lists
# 2. Let user select and install
# 3. Perform post-install actions (groups, timers, etc.)
# 4. Manage firewall configuration (firewalld and ufw) if needed
# -----------------------------------------------------------------------------
function install_software() {
	# Ask how to install software when both Flatpak and native versions exist
	prompt_choice INSTALL_METHOD "Choose preferred software installation method" "Native" "Flatpak"

    # 1. Initialize lists
    set_software_list

    # 2. Selection
    select_and_install browser_list "Browsers"
	select_and_install accessibility_list "Accessibility Apps"
    select_and_install system_list "System Software"
    select_and_install desktop_list "Desktop Apps P1"
	select_and_install desktop_list2 "Desktop Apps P2"
	select_and_install desktop_list3 "Desktop Apps P3"
    select_and_install video_list "Video Software"
    select_and_install picture_list "Image Editors"
    select_and_install gaming_list "Gaming Software"
	select_and_install gaming_list2 "Gaming Software P2"
	select_and_install emulator_list "Gaming Emulator Software"
	select_and_install emulator_list2 "Gaming Emulator Software P2"
	select_and_install emulator_list3 "Gaming Emulator Software P3"

    # Retrieve selected packages to install
    local -r packages="${selected_packages}"
    selected_packages=""

    # Install
    # install_lst "${packages}" "aur"
	install_mixed_lst "${packages}"

    # 3. Post-install actions
    # -------------------------------------------------------------------------
    # Arch Update
    if [[ "${packages}" =~ "arch-update" ]]; then
        exec_log "systemctl --user enable arch-update.timer" "Enable arch-update.timer"
        exec_log "arch-update --tray --enable" "Enable arch-update tray"
    fi

    # Open Razer
    if [[ "${packages}" =~ "openrazer-daemon" ]]; then
        exec_log "sudo usermod -aG plugdev $(whoami)" "Add the current user to the plugdev group"
    fi

    # VirtualBox
    if [[ "${packages}" =~ "virtualbox" ]]; then
        exec_log "sudo usermod -aG vboxusers $(whoami)" "Add the current user to the vboxusers group"
        exec_log "sudo systemctl enable vboxweb.service" "Enable vboxweb"
    fi

    # Virt-Manager
    if [[ "${packages}" =~ "virt-manager" ]]; then
        exec_log "sudo usermod -aG libvirt $(whoami)" "Add the current user to the libvirt group"
        exec_log "sudo usermod -aG kvm $(whoami)" "Add the current user to the kvm group"
        exec_log "sudo systemctl enable --now libvirtd" "Enable libvirtd"

        # Configure libvirtd socket (permissions)
        sudo sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' /etc/libvirt/libvirtd.conf
        sudo sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf

        # -- Open relevant ports if firewalld is installed
        if command -v firewall-cmd >/dev/null 2>&1; then
            sudo firewall-cmd --permanent --add-service=libvirt &> /dev/null
            sudo firewall-cmd --permanent --add-port=5900-5999/tcp &> /dev/null
            sudo firewall-cmd --permanent --add-port=16509/tcp &> /dev/null
            sudo firewall-cmd --permanent --add-port=5666/tcp &> /dev/null
            sudo firewall-cmd --reload &> /dev/null
        fi

        # -- Open the same ports if ufw is installed
        if command -v ufw >/dev/null 2>&1; then
            sudo ufw allow 5900:5999/tcp
            sudo ufw allow 16509/tcp
            sudo ufw allow 5666/tcp
            sudo ufw reload &> /dev/null
        fi
    fi

    # Gamemode
    if [[ "${packages}" =~ "gamemode" ]]; then
        exec_log "sudo usermod -aG gamemode $(whoami)" "Add the current user to the gamemode group"

        # Default configuration for /etc/gamemode.ini
	if [ ! -f /etc/gamemode.ini ]; then
	sudo tee /etc/gamemode.ini > /dev/null <<EOF
[general]
reaper_freq=5
desiredgov=performance
desiredgov=performance
igpu_desiredgov=powersave
igpu_power_threshold=0.3
softrealtime=off
renice=0
ioprio=0
inhibit_screensaver=1
disable_splitlock=1

[filter]
;whitelist=RiseOfTheTombRaider
;blacklist=HalfLife3

[gpu]
;apply_gpu_optimisations=0
;gpu_device=0
;nv_powermizer_mode=1
;nv_core_clock_mhz_offset=0
;nv_mem_clock_mhz_offset=0
;amd_performance_level=high

[cpu]
;park_cores=no
;pin_cores=yes

[supervisor]
;supervisor_whitelist=
;supervisor_blacklist=
;require_supervisor=0

[custom]
;start=notify-send "GameMode started"
;end=notify-send "GameMode ended"
;script_timeout=10'
EOF
fi

    # 4. Firewall configuration for Steam if necessary
    # -------------------------------------------------------------------------
    if [[ "${packages}" =~ "steam" ]]; then
        # -- firewalld
        if command -v firewall-cmd >/dev/null 2>&1; then
            # Steam Remote Play https://help.steampowered.com/en/faqs/view/0689-74B8-92AC-10F2
            sudo firewall-cmd --permanent --add-port=27031-27036/udp &> /dev/null
            sudo firewall-cmd --permanent --add-port=27036/tcp &> /dev/null
            sudo firewall-cmd --permanent --add-port=27037/tcp &> /dev/null
            # Apply changes
            sudo firewall-cmd --reload &> /dev/null
        fi

        # -- ufw
        if command -v ufw >/dev/null 2>&1; then
            # Steam Remote Play https://help.steampowered.com/en/faqs/view/0689-74B8-92AC-10F2
            sudo ufw allow 27031:27036/udp
            sudo ufw allow 27036/tcp
            sudo ufw allow 27037/tcp
            # Apply changes
            sudo ufw reload &> /dev/null
        fi
    fi
}
