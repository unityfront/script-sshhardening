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
# Contact us at unityfront.org or @unityfront on Twitter.
################################################################################################################

################################################################################################################
#    _____                    __  .__                      
# _/ ____\_ __  ____   _____/  |_|__| ____   ____   ______
# \   __\  |  \/    \_/ ___\   __\  |/  _ \ /    \ /  ___/
#  |  | |  |  /   |  \  \___|  | |  (  <_> )   |  \\___ \ 
#  |__| |____/|___|  /\___  >__| |__|\____/|___|  /____  >
#                  \/     \/                    \/     \/ 
################################################################################################################
# Random port generator function
generate_random_port() {
    echo $(( (RANDOM % 64510) + 1025 ))
}

# Update and install necessary packages
update_system() {
    echo "Updating system and installing necessary packages..."
    sudo apt update -y && sudo apt upgrade -y && sudo apt install openssh-server fail2ban ufw -y
}

generate_ssh_key() {
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 4096
}

# Function to prompt user for custom SSH port or generate a random one
prompt_ssh_port() {
    read -p "Enter a custom port for SSH or press enter to generate a random port: " CUSTOM_PORT
    if [ -z "$CUSTOM_PORT" ]; then
        RANDOM_PORT=$(generate_random_port)
        SSH_PORT=$RANDOM_PORT
        echo "Generated random SSH port: $SSH_PORT"
    else
        SSH_PORT=$CUSTOM_PORT
        echo "Using custom SSH port: $SSH_PORT"
    fi
}

# Function to use SED to configure the SSH daemon
configure_sshd () {
    echo "Configuring SSH..."
    sudo sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
    sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
}

# Function to restart the SSH service
restart_ssh_service() {
    echo "Restarting SSH service..."
    sudo systemctl restart sshd
}

# Function to set up UFW to allow the SSH port selected and enable the firewall
setup_firewall() {
    echo "Setting up the firewall..."
    sudo ufw enable
    sudo ufw allow ${SSH_PORT}/tcp
}

# Function to set up Fail2Ban to monitor the SSH port
setup_fail2ban() {
    echo "Setting up Fail2Ban..."
    sudo cp /etc/fail2ban/jail.{conf,local}
    sudo sed -i "s/port    = ssh/port    = $SSH_PORT/" /etc/fail2ban/jail.local
    sudo sed -i "/^enabled = false/c\enabled = true" /etc/fail2ban/jail.local
    sudo systemctl restart fail2ban
}

# Function to indicate that the SSH Secure Setup Wizard is complete
gaming_time() {
    echo "SSH Secure Setup is complete!"
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
update_system
generate_ssh_key
prompt_ssh_port
configure_sshd
restart_ssh_service
setup_firewall
setup_fail2ban
gaming_time