source src/cmd.sh
source src/system/drivers/nvidia.sh
source src/system/drivers/amd.sh
source src/system/drivers/intel.sh
source src/system/drivers/vm.sh

function video_drivers() {
    local -r valid_gpus=("INTEL" "AMD" "NVIDIA" "VM")
    local choice

    echo "Available GPU types: ${valid_gpus[*]}"
    
    while true; do
        read -rp "What is your graphics card type? (${valid_gpus[*]}): " choice
        choice="${choice^^}"  # Convert to uppercase

        if [[ " ${valid_gpus[*]} " =~ " ${choice} " ]]; then
            break
        else
            echo "Invalid choice. Please enter one of: ${valid_gpus[*]}"
        fi
    done

    echo -e "${GREEN}You chose ${choice}${RESET}"

    case "${choice}" in
        "NVIDIA") nvidia_drivers ;;
        "AMD")    amd_drivers ;;
        "INTEL")  intel_drivers ;;
        "VM")     vm_drivers ;;
        *)        echo "Unexpected error: unknown GPU type '${choice}'" ;;
    esac
}
