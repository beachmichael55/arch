# Load shared functions
source src/cmd.sh

function usefull_package() {
    local inlst="
        joystickwake
        gstreamer
        gst-plugins-base
        gst-plugin-pipewire
        gstreamer-vaapi
        gst-plugins-good
        gst-libav
        gstreamer-vaapi
        libva-mesa-driver
        mesa-vdpau
        xdg-utils
		dkms
        rebuild-detector
        fastfetch
        power-profiles-daemon
        ttf-dejavu
        ttf-liberation
        ttf-meslo-nerd
        noto-fonts-emoji
        adobe-source-code-pro-fonts
        otf-font-awesome
        ttf-droid
        ntfs-3g
        fuse2
        fuse2fs
        fuse3
        exfatprogs
        bash-completion
        ffmpegthumbs
        man-db
        man-pages
		lsscsi
		mtools
		sg3_utils
		efitools
		nfs-utils
		ntp
		unrar
		unzip
		libgsf
		networkmanager-openvpn
		networkmanager-l2tp
		network-manager-applet
		cpupower
		nano-syntax-highlighting
		xdg-desktop-portal
		btop
		duf
		pv
		jq
		rsync
		duperemove
		curl
		iperf3
		python-pip
		wine-staging
		jre-openjdk
    "

    if [[ ${BTRFS} == true ]]; then
        inlst+=" btrfs-progs btrfs-assistant btrfsmaintenance"
    fi

    install_lst "${inlst}"
}
