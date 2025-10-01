source src/cmd.sh

function intel_drivers() {
    local -r inlst="
        mesa
        lib32-mesa
		xf86-video-intel
        vulkan-intel
        lib32-vulkan-intel
        intel-media-driver
        intel-gmmlib
        onevpl-intel-gpu
        vulkan-mesa-layers
        libva-mesa-driver
        lib32-libva-mesa-driver
        mesa-vdpau
        lib32-mesa-vdpau
		intel-gpu-tools
    "

    install_lst "${inlst}"
}
