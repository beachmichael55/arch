# Load shared functions
source src/cmd.sh

# The firewall function prompts the user to install a firewall (Firewalld or UFW),
# then lets the user choose which one to install.
function firewall() {
    # Ask the user if they want to install a firewall
    if ask_question "$(eval_gettext "Would you like to install a firewall? /!\\ WARNING: This script can install and enable either Firewalld or UFW. The default configuration may block local network devices such as printers or block some software functions.")"; then
        
        # Print an introduction message
        echo "Please choose which firewall to install by typing the number of your choice."

        # Customize the prompt shown by the 'select' command
        PS3="Enter your choice (1 for Firewalld, 2 for UFW): "

        # Present a simple interactive menu
        select firewall_choice in "Firewalld" "UFW"; do
            case $firewall_choice in
                
                # If the user selects "Firewalld"
                "Firewalld")
                    # Install the necessary packages: firewalld, python-pyqt5, and python-capng
                    install_lst "firewalld python-pyqt5 python-capng"
                    
                    # Enable and start the firewalld service immediately
                    sudo systemctl enable --now firewalld.service &> /dev/null
                    
                    # Remove SSH and DHCPv6-Client services from the default firewall zone (optional)
                    sudo firewall-cmd --remove-service="ssh" --permanent &> /dev/null
                    sudo firewall-cmd --remove-service="dhcpv6-client" --permanent &> /dev/null
                    
                    # Inform the user that Firewalld is set up
                    echo "Firewalld has been installed and enabled."
                    break
                    ;;
                
                # If the user selects "UFW"
                "UFW")
                    # Install the UFW package
                    install_lst "ufw"
                    
                    # Enable and start the ufw service
                    sudo systemctl enable --now ufw.service &> /dev/null
                    
                    # Activate ufw (by default, it may block all incoming connections except SSH)
                    sudo ufw enable
                    
                    # Inform the user that UFW is set up
                    echo "UFW has been installed and enabled."
                    break
                    ;;
                
                # Any invalid choice leads to a prompt to select again
                *)
                    echo "Invalid choice, please select '1' for Firewalld or '2' for UFW."
                    ;;
            esac
        done
    fi
}
