#!/bin/bash

################################################################################################################
#  ____ ___      .__  __           ___________                     __   
# |    |   \____ |__|/  |_ ___.__. \_   _____/______  ____   _____/  |_ 
# |    |   /    \|  \   __<   |  |  |    __) \_  __ \/  _ \ /    \   __\
# |    |  /   |  \  ||  |  \___  |  |     \   |  | \(  <_> )   |  \  |  
# |______/|___|  /__||__|  / ____|  \___  /   |__|   \____/|___|  /__|  
#              \/          \/           \/                      \/      
################################################################################################################
# WHEN INJUSTICE BECOMES LAW, 
#                                RESISTANCE BECOMES DUTY
################################################################################################################
#       ___.                  __   
# _____ \_ |__   ____  __ ___/  |_ 
# \__  \ | __ \ /  _ \|  |  \   __\
#  / __ \| \_\ (  <_> )  |  /|  |  
# (____  /___  /\____/|____/ |__|  
#      \/    \/                    
################################################################################################################
# This script hardens SSH by generating a random port, configuring the SSH daemon, restarting the SSH service, setting up UFW, and configuring Fail2Ban.
# 
# This script was created by jessthnthree for Unity Front. Modifications are welcome. 
# Contact us at unityfront.org or @unityfrontcomms on Twitter.
################################################################################################################

################################################################################################################
#    _____                    __  .__                      
# _/ ____\_ __  ____   _____/  |_|__| ____   ____   ______
# \   __\  |  \/    \_/ ___\   __\  |/  _ \ /    \ /  ___/
#  |  | |  |  /   |  \  \___|  | |  (  <_> )   |  \\___ \ 
#  |__| |____/|___|  /\___  >__| |__|\____/|___|  /____  >
#                  \/     \/                    \/     \/ 
################################################################################################################

# Function to ensure the script is running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root."
        exit 1
    fi
}

# Function to create a log file for SSH secure setup
### The function prompts the user to choose the location for the log file
### The log file is created at the specified location with the name "ssh_secure_setup.log"
### If the log file creation fails, the function prompts the user to retry or skip creating the log file
### The function appends a header and timestamp to the log file upon successful creation
### The function returns if the user chooses to skip creating the log file
create_log() {
    read -p "Would you like to save the log in /var/log, current home directory, or skip the creation of a log file? (v, c, X): " LOG_PATH_CHOICE
    case "$LOG_PATH_CHOICE" in
        v) LOG_PATH="/var/log" ;;
        c) LOG_PATH=$(pwd) ;;
        x) echo "Skipping log file creation."; return ;;
        *) LOG_PATH="/var/log" ;;
    esac

    LOG_FILE="$LOG_PATH/ssh_secure_setup.log"
    
    # Create log file and handle errors
    if ! touch "$LOG_FILE"; then
        echo "Failed to create log file at $LOG_FILE. Check your permissions."
        read -p "Would you like to create the file in the current directory or skip creating a log file? (c/X): " TRY_AGAIN
        if [ "$TRY_AGAIN" == "c" ]; then
            LOG_PATH=$(pwd)
            LOG_FILE="$LOG_PATH/ssh_secure_setup.log"
            if ! touch "$LOG_FILE"; then
                echo "Failed to create log file in the current directory. Skipping log file creation."
                return
            fi
        else
            echo "Skipping log file creation."
            return
        fi
    fi

    {
        echo "---------------------------------"
        echo "---------------------------------"
        echo "
  ____ ___      .__  __           ___________                     __   
 |    |   \____ |__|/  |_ ___.__. \_   _____/______  ____   _____/  |_ 
 |    |   /    \|  \   __<   |  |  |    __) \_  __ \/  _ \ /    \   __\
 |    |  /   |  \  ||  |  \___  |  |     \   |  | \(  <_> )   |  \  |  
 |______/|___|  /__||__|  / ____|  \___  /   |__|   \____/|___|  /__|  
              \/          \/           \/                      \/  
        "
        echo "@unityfrontcomms on Twitter -"
        echo "---------------------------------"
        echo "---------------------------------"
        echo "SSH Secure Setup Log"
        echo "---------------------------------"
        echo "$(date): Log created."
    } >> "$LOG_FILE"

    echo "Log file created at $LOG_FILE"
}

# Function to generate a random port number between 1025 and 65534.
generate_random_port() {
    echo $(( (RANDOM % 64510) + 1025 ))
}

# Function to update the system and install necessary packages
### This function updates the system by running 'apt update' and 'apt upgrade' commands.
### It also installs the necessary packages including openssh-server, fail2ban, and ufw.
### If any error occurs during the update or installation process, an error message is displayed and the script exits with a status code of 1.
### The progress and status of the update and installation process are logged in a log file.
update_system() {
    echo "Updating system and installing necessary packages..."
    echo "$(date): Updating system and installing necessary packages..." >> "$LOG_FILE"
    if ! sudo apt update -y && sudo apt upgrade -y && sudo apt install openssh-server fail2ban ufw -y; then
        echo "Error updating system and installing necessary packages."
        echo "$(date): Error updating system and installing necessary packages." >> "$LOG_FILE"
        exit 1
    fi
    echo "$(date): System updated and necessary packages installed." >> "$LOG_FILE"
}

# Function to generate an SSH key
### If the user chooses to generate a key, it proceeds with the key generation process.
### If the user chooses not to generate a key, it skips the key generation process.
generate_ssh_key() {
    read -p "Would you like to generate an SSH key? (Y/n): " GENERATE_KEY
    if [ "$GENERATE_KEY" == "n" ]; then
        echo "Skipping SSH key generation..."
        echo "$(date): Skipping SSH key generation." >> "$LOG_FILE"
        return
    fi

    echo "Generating SSH key..."
    if ! ssh-keygen -t rsa -b 4096; then
        echo "Error generating SSH key."
        echo "$(date): Error generating SSH key." >> "$LOG_FILE"
        exit 1
    fi
    echo "$(date): SSH key generated." >> "$LOG_FILE"
}

# Function to prompt the user for a custom port for SSH or generate a random port if no input is provided.
### If a custom port is provided, it will be stored in the SSH_PORT variable.
### If no input is provided, a random port will be generated using the generate_random_port function.
### The chosen SSH port will be logged with the current date and time in the LOG_FILE.
prompt_ssh_port() {
    read -p "Enter a custom port for SSH or press enter to generate a random port (22 is the default port for SSH): " CUSTOM_PORT
    if [ -z "$CUSTOM_PORT" ]; then
        SSH_PORT=$(generate_random_port)
    else
        SSH_PORT=$CUSTOM_PORT
    fi
    echo "$(date): Using SSH port: $SSH_PORT" >> "$LOG_FILE"
}

# Function to prompt the user for disabling password authentication and configure SSH authentication settings accordingly.
### If the user chooses to disable password authentication, the function sets PasswordAuthentication to no and PublicKeyAuthentication to yes in the sshd_config file.
### It also logs the configuration changes and any errors encountered.
prompt_password_authentication() {
    read -p "Would you like to disable password authentication? You will need to make sure you run ssh-copy-id on all machines you plan on connecting with! (Y/n): " SET_AUTH 
    if [ "$SET_AUTH" == "n" ]; then
        echo "Skipping authentication configuration..."
        echo "$(date): Skipping authentication configuration." >> "$LOG_FILE"
        return
    fi

    echo "Setting PasswordAuthentication to no and PublicKeyAuthentication to yes..."
    if ! sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config && sudo sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config; then
        echo "Error setting authentication."
        echo "$(date): Error setting authentication." >> "$LOG_FILE"
        exit 1
    fi
    echo "$(date): Authentication set successfully." >> "$LOG_FILE"
}

# Function to configure SSH
### This function configures the SSH service by modifying the sshd_config file.
### It replaces the default SSH port with the specified SSH_PORT variable.
### The function also logs the configuration process and any errors encountered.
configure_sshd() {
    echo "Configuring SSH..."
    echo "$(date): Configuring SSH..." >> "$LOG_FILE"
    if ! sudo sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config; then
        echo "Error configuring SSH."
        echo "$(date): Error configuring SSH." >> "$LOG_FILE"
        exit 1
    fi
    echo "$(date): SSH configured successfully." >> "$LOG_FILE"
}

# Function to restart the SSH service.
### This function restarts the SSH service using the systemctl command.
### If the restart fails, an error message is printed and the script exits with a non-zero status code.
### The error message is also logged to the specified log file.
restart_ssh_service() {
    echo "Restarting SSH service..."
    if ! sudo systemctl restart sshd; then
        echo "Error restarting SSH service."
        echo "$(date): Error restarting SSH service." >> "$LOG_FILE"
        exit 1
    fi
}

# Function to set up the firewall for SSH hardening
### This function allows the SSH port through the firewall and enables the firewall
### If there is an error setting up the firewall, it logs the error and exits with status code 1
setup_firewall() {
    echo "Setting up the firewall..."
    echo "$(date): Setting up the firewall..." >> "$LOG_FILE"
    
    if ! sudo ufw allow "${SSH_PORT}/tcp"; then
        echo "Error allowing port ${SSH_PORT}/tcp through the firewall."
        echo "$(date): Error allowing port ${SSH_PORT}/tcp through the firewall." >> "$LOG_FILE"
        exit 1
    fi
    
    if ! sudo ufw enable; then
        echo "Error enabling the firewall."
        echo "$(date): Error enabling the firewall." >> "$LOG_FILE"
        exit 1
    fi

    if ! sudo ufw status; then
        echo "Error getting the firewall status."
        echo "$(date): Error getting the firewall status." >> "$LOG_FILE"
        exit 1
    fi

    echo "$(date): Firewall set up successfully." >> "$LOG_FILE"
}


# Function: setup_fail2ban
### Description: Sets up Fail2Ban by copying the jail.conf file to jail.local, modifying the SSH port, enabling Fail2Ban, and restarting the fail2ban service.
setup_fail2ban() {
    echo "Setting up Fail2Ban..."
    echo "$(date): Setting up Fail2Ban..." >> "$LOG_FILE"
    if ! sudo cp /etc/fail2ban/jail.{conf,local} || ! sudo sed -i "s/port    = ssh/port    = $SSH_PORT/" /etc/fail2ban/jail.local || ! sudo sed -i "/^enabled = false/c\enabled = true" /etc/fail2ban/jail.local || ! sudo systemctl restart fail2ban; then
        echo "Error setting up Fail2Ban."
        echo "$(date): Error setting up Fail2Ban." >> "$LOG_FILE"
        exit 1
    fi
    echo "$(date): Fail2Ban set up successfully." >> "$LOG_FILE"
}

# Function to restart services
### This function prompts the user if they want to restart all services.
### If the user chooses not to restart, it skips the service restart and logs the action.
### If the user chooses to restart, it restarts the sshd, fail2ban, and ufw services.
### If there is an error restarting the services, it logs the error and exits with a non-zero status code.
### Finally, it logs the successful restart of services.
restart_services() {
    read -p "Would you like to restart all services? THIS WILL AFFECT YOUR EXISTING NETWORK CONNECTIONS! (Y/n): " RESTART_SERVICES 
    if [ "$RESTART_SERVICES" == "n" ]; then
        echo "Skipping service restart..."
        echo "$(date): Skipping service restart." >> "$LOG_FILE"
        return
    fi

    echo "Restarting all services..."
    if ! sudo systemctl restart sshd fail2ban ufw; then
        echo "Error restarting services."
        echo "$(date): Error restarting services." >> "$LOG_FILE"
        exit 1
    fi
    echo "$(date): Services restarted." >> "$LOG_FILE"
}

# Function to display a message indicating that SSH Secure Setup is complete and print the SSH port and log file location.
## It also appends a timestamped message to the log file.
gaming_time() {
    echo "SSH Secure Setup is complete!"
    echo " Your SSH port is: $SSH_PORT"
    echo " Your log file is located at: $LOG_FILE"
    echo "$(date): SSH Secure Setup is complete!" >> "$LOG_FILE"
    echo " ---------------------------------" >> "$LOG_FILE"
    echo " ---------------------------------" >> "$LOG_FILE"
    echo "Your SSH port is: $SSH_PORT" >> "$LOG_FILE"
    echo "
     ____ ___      .__  __           ___________                     __   
    |    |   \____ |__|/  |_ ___.__. \_   _____/______  ____   _____/  |_ 
    |    |   /    \|  \   __<   |  |  |    __) \_  __ \/  _ \ /    \   __\
    |    |  /   |  \  ||  |  \___  |  |     \   |  | \(  <_> )   |  \  |  
    |______/|___|  /__||__|  / ____|  \___  /   |__|   \____/|___|  /__|  
                 \/          \/           \/                      \/      
    "
}

################################################################################################################
#               .__                             .__        __   
#  _____ _____  |__| ____     ______ ___________|__|______/  |_ 
# /     \\__  \ |  |/    \   /  ___// ___\_  __ \  \____ \   __\
#|  Y Y  \/ __ \|  |   |  \  \___ \\  \___|  | \/  |  |_> >  |  
#|__|_|  (____  /__|___|  / /____  >\___  >__|  |__|   __/|__|  
#      \/     \/        \/       \/     \/         |__|         
################################################################################################################

# Main execution starts here
check_root
create_log
update_system
generate_ssh_key
prompt_ssh_port
prompt_password_authentication
configure_sshd
restart_ssh_service
setup_firewall
setup_fail2ban
restart_services
gaming_time
