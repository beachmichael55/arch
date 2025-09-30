# Utility logging and command execution functions for the Architect installer

# Append a timestamped log entry to the logfile
function log() {
    local -r comment="$1"

    echo "[$(date "+%Y-%m-%d %H:%M:%S")] ${comment}" >>"${LOG_FILE}"
    # Clean escape characters, color codes, unicode, etc.
    sed -i -E "s/\x1B\[[0-9;]*[JKmsu]|\x1B\(B|\\u[0-9]{0,4}|\\n//g" ${LOG_FILE}
}

# Echo the message and write it to the log file
function log_msg() {
    local -r comment="$1"

    echo "${comment}"
    log "${comment}"
}

# Prompt user for a choice between two options
function prompt_choice() {
	local var_name=$1
	local prompt=$2
	local opt1=$3
	local opt2=$4

	while true; do
		echo -e ":${prompt} ${CYAN}(1) ${opt1}, (2) ${opt2}${RESET}"
		read -rp "Choice: " choice
		case "$choice" in
			1) eval "$var_name=\"$opt1\"" ; break ;;
			2) eval "$var_name=\"$opt2\"" ; break ;;
			*) echo "${RED}Invalid option. ${RESET}Please enter 1 or 2." ;;
		esac
	done
}

# Ask user how to install a specific app if both Flatpak and Native are available
function prompt_per_package_choice() {
    local app_name="$1"
    local native_pkg="$2"
    local flatpak_pkg="$3"
    local choice=""

    while true; do
        echo -e "How would you like to install '${BLUE}${app_name}'?${RESET}"
        echo -e "${CYAN}  (1) Native${RESET}:  ${BLUE}${native_pkg}${RESET}"
        echo -e "${CYAN}  (2) Flatpak${RESET}: ${BLUE}${flatpak_pkg}${RESET}"
        read -rp "Choice: " choice
        case "$choice" in
            1) echo "native"; return ;;
            2) echo "flatpak"; return ;;
            *) echo "${RED}Invalid choice. Please enter 1 or 2.${RESET}" ;;
        esac
    done
}

# Execute a shell command (with optional verbose and log mode)
function exec() {
    local -r command="$1"

    if [[ ${VERBOSE} == true ]]; then
        # Display output and log
        eval "${command}" 2>&1 | tee -a "${LOG_FILE}"
    else
        # Run in background and show spinner dots
        eval "${command}" >>"${LOG_FILE}" 2>&1 &
        job_pid=$!
        progress_dots
        wait -n
        exit_status "${comment}"
    fi
}

# Execute a command with a user-visible comment
function exec_log() {
    local -r command="$1"
    local -r comment="$2"

    log_msg "${comment}"
    exec "${command}"
}

# Install a single package via AUR helper and Pacman
function install_one() {
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
        # Official repo
        exec_log "sudo pacman -S --noconfirm --needed ${package}" "${GREEN}[pacman]${RESET} ${BLUE}${package}${RESET}${warning_msg}"
    else
        # AUR
        if [[ -z "${AUR}" ]]; then
            log_msg "${RED}AUR helper not set. Cannot install${RESET} ${BLUE}${package}${RESET}.${RESET}"
            return 1
        fi
        exec_log "${AUR} -S --noconfirm --needed ${package}" "${GREEN}[AUR]${RESET} ${BLUE}${package}${RESET}${warning_msg}"
    fi
}
# Install a list of packages, choosing Native or Flatpak based on user choice
function install_mixed_lst() {
    local -r lst=$1
    local -r lst_split=(${lst// / })
    for entry in "${lst_split[@]}"; do
        IFS="|" read -r native flatpak <<< "${entry}"
        if [[ "$INSTALL_METHOD" == "Flatpak" && -n "$flatpak" ]]; then
			if flatpak info "$flatpak" &>/dev/null; then
				log_msg "${ORANGE}[I]${RESET} Flatpak package ${BLUE}${flatpak}${RESET} is already installed."
			else
				exec_log "flatpak install -y --noninteractive $flatpak" "${GREEN}[Flatpak]${RESET} ${flatpak}"
			fi
		else
			install_one "${native}" "aur"
		fi
    done
}


# Uninstall a package if it is present
function uninstall_one() {
    local -r package=$1
    if pacman -Q ${package} &> /dev/null; then
        exec_log "sudo pacman -Rdd --noconfirm ${package}" "${RED}[-]${RESET} ${BLUE}${package}${RESET}"
    else
        log_msg "${RED}[U]${RESET} Package ${BLUE}${package}${RESET} is not installed."
    fi
}

# Install a space-separated list of packages
function install_lst() {
    local -r lst=$1
    local -r type=$2
    local -r lst_split=(${lst// / })

    for package in ${lst_split[@]}; do
        install_one "${package}" "${type}"
    done
}

# Uninstall a space-separated list of packages
function uninstall_lst() {
    local -r lst=$1
    local -r lst_split=(${lst// / })

    for package in ${lst_split[@]}; do
        uninstall_one "${package}"
    done
}

# Ask a yes/no question, return 0 for yes, 1 for no
function ask_question() {
    read -rp "$1 (y/N): " choice
    case "${choice,,}" in
        y|yes) return 0 ;;
        *) return 1 ;;
    esac
}

# Show animated progress dots while waiting on background command
function progress_dots() {
    local dots="....."

    while kill -0 $job_pid 2> /dev/null; do
        printf "%b [     ]%b\n" "\033[1A${comment}" "\033[6D${BOLD}${GREEN}${dots}${RESET}"
        sleep 0.5
        dots+="."
        if [[ ${dots} == "......" ]]; then
            dots=""
        fi
    done
}

# Display exit status of the last command with a visual checkmark or cross
function exit_status() {
    local exit_status=$?
    local -r comment="$1"

	echo "[INFO]: Exit status: ${exit_status}" >>"${LOG_FILE}"
	if [[ ${exit_status} -ne 0 ]]; then
		printf "%b\n" "\033[1A\033[2K${comment} ${RED}\u2718${RESET}"
		log_msg "${RED}Error: installation failed${RESET}"
	else
		printf "%b\n" "\033[1A\033[2K${comment} ${GREEN}\u2714${RESET}"
	fi

}
