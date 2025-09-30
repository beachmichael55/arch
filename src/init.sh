# Display the script header and warning message before execution
function header() {
    clear

    # Display stylized ASCII art with color codes
    cat <<-EOF
-----------------------------------------------------------------------------------------------------------

       ${PURPLE}%%%%%%%%%%${RESET}  ${GREEN}*********${RESET}            
       ${PURPLE}%%%${RESET}                 ${GREEN}******${RESET}       
       ${PURPLE}%%%${RESET}                     ${GREEN}***${RESET}      "Script for Arch Linux"
       ${PURPLE}%%%${RESET}                     ${GREEN}***${RESET}
       ${PURPLE}%%%${RESET}                     ${GREEN}***${RESET}
       ${PURPLE}%%%${RESET}                     ${GREEN}***${RESET}
       ${PURPLE}%%%${RESET}                     ${GREEN}***${RESET}
        ${PURPLE}%%%%%%${RESET}                 ${GREEN}***${RESET}
             ${PURPLE}%%%%%%%%${RESET}  ${GREEN}***********${RESET}

-----------------------------------------------------------------------------------------------------------
EOF

    sleep 1

    # Display warning and user prompt
    echo "${RED}This script will make changes to your system.${RESET}"
    echo "Some steps may take longer, depending on your Internet connection and CPU."
    echo "Press ${GREEN}Enter${RESET} to continue, or ${RED}Ctrl+C${RESET} to cancel."

    # Wait for user confirmation
    read -rp "" choice

    # If the user types something instead of pressing Enter, exit the script
    [[ -n $choice ]] && exit 0
}

# Initialize the log file for the script
function init_log() {
    # Remove the existing log file if it already exists
    if [[ -f "${LOG_FILE}" ]]; then
        rm -f "${LOG_FILE}"
    fi

    # Create a new empty log file
    touch "${LOG_FILE}"

    # Log the current Git commit hash and log file path for reference
    echo -e "Commit hash: $(git rev-parse HEAD)" >>"${LOG_FILE}"
    echo -e "Log file: ${LOG_FILE}\n" >>"${LOG_FILE}"
}
