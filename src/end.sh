# Function called at the end of the main script
function endscript() {
    # Get the current time (in seconds since epoch)
    local -r end_time="$(date +%s)"
    # Calculate the total duration of the script (end - start)
    local -r duration="$((${end_time} - ${1}))"
    # Display execution time in the terminal
    echo "Done in {GREEN}{duration}{RESET} seconds."
    # Also write the duration to the log file
    echo -e "Done in ${duration} seconds." >>"${LOG_FILE}"
    # If NOREBOOT is true, skip the reboot and just exit the script
    if [[ "${NOREBOOT}" == "true" ]]; then
        echo "\${GREEN}Script completed successfully.\${RESET}"; echo
        exit 0
    fi
    # Otherwise, ask the user to confirm system reboot
    read -rp "$(echo "\${GREEN}Script completed successfully, the system must restart\${RESET}: Press \${GREEN}Enter\${RESET} to restart or \${RED}Ctrl+C\${RESET} to cancel.")"
    # 5-second countdown before rebooting
    for i in {5..1}; do
        echo "\${GREEN}Restarting in \${i} seconds...\${RESET}"; echo -ne "\r"
        sleep 1
    done
    # Reboot the system
    reboot
}
