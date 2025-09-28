source src/cmd.sh

function amd_drivers() {
    local inlst="
        mesa
        lib32-mesa
        vulkan-radeon
        lib32-vulkan-radeon
        vulkan-icd-loader
        lib32-vulkan-icd-loader
        libva-mesa-driver
        lib32-libva-mesa-driver
        vulkan-mesa-layers
        mesa-vdpau
        lib32-mesa-vdpau
		radeontop
		xf86-video-amdgpu
		xf86-video-ati
		corectrl
    "

    if ask_question "$(eval_gettext "Would you like to install ROCM (\${RED}say No if unsure\${RESET})")"; then
        inlst="${inlst} rocm-opencl-runtime rocm-hip-runtime rocm-clinfo"
    fi

    install_lst "${inlst}"
}
