function test_size() {
    local -r warning="
        cuda
        nvidia-dkms
    "
    local -r package=$1
    local type=$2  # Not used anymore but kept for compatibility
    # Skip if already installed
    if pacman -Qi "${package}" &> /dev/null; then
        log_msg "${ORANGE}[I]${RESET} Package ${BLUE}${package}${RESET} is already installed."
        return
    fi
    local warning_msg=""
    if [[ ${warning} =~ ${package} ]]; then
        warning_msg=" ${RED}(might be long)${RESET}"
    fi
    # Determine installation source
    if pacman -Si "${package}" &> /dev/null; then
		local download_size installed_size
		download_size=$(pacman -Si "${package}" | grep -E "^Download Size" | awk -F: '{print $2}' | xargs)
        installed_size=$(pacman -Si "${package}" | grep -E "^Installed Size" | awk -F: '{print $2}' | xargs)
        echo "${package}:Download size=${download_size},Installed Size=${installed_size}${warning_msg}" >> package_sizes.txt
    else
        echo "${package} not found."
    fi
}
function pakages() {
	local -r inlst="
		intel-media-driver
        intel-gmmlib
        onevpl-intel-gpu
		xf86-video-intel
		xorg-xrandr
		nvidia-prime
		optimus-manager-qt
	"
    for pkg in ${inlst}; do
		test_size "${pkg}"
	done
}

pakages