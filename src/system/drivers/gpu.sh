source src/cmd.sh
source src/system/drivers/nvidia.sh
source src/system/drivers/amd.sh
source src/system/drivers/intel.sh
source src/system/drivers/vm.sh

function video_drivers() {
    local -r valid_gpus=("intel" "amd" "nvidia" "vm")
    local choice index

	echo "Available GPU types:"
    for i in "${!valid_gpus[@]}"; do
        printf "  %d) %s\n" "$((i+1))" "${valid_gpus[$i]}"
    done
    echo "  Press Enter to skip driver selection."

	while true; do
        read -rp "Select your GPU by number (1-${#valid_gpus[@]}) or press Enter to skip: " choice

        if [[ -z "$choice" ]]; then
            echo -e "${YELLOW}Skipping GPU driver installation.${RESET}"
            return 0
        elif [[ "$choice" =~ ^[1-4]$ ]]; then
            index=$((choice - 1))
            break
        else
            echo -e "${RED}Invalid selection.${RESET} Please enter a number between 1 and ${#valid_gpus[@]}, or press Enter to skip."
        fi
    done

    local selected_gpu="${valid_gpus[$index]}"
    echo -e "${GREEN}You chose ${selected_gpu^^}${RESET}"
	
	local inlst="
		vulkan-icd-loader
        lib32-vulkan-icd-loader
		
	"
	install_lst "${inlst}"

    case "${selected_gpu^^}" in
        "NVIDIA") nvidia_drivers ;;
        "AMD")    amd_drivers ;;
        "INTEL")  intel_drivers ;;
        "VM")     vm_drivers ;;
        *)        echo "${RED}Unexpected error: unknown GPU type '${selected_gpu}'${RESET}" ;;
    esac
}

