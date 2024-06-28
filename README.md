# SSH Hardening Script

## Overview

This script hardens SSH by generating a random port, configuring the SSH daemon, restarting the SSH service, setting up UFW, and configuring Fail2Ban.

**Author:** jessthnthree  
**Organization:** Unity Front  
**Contact:** [unityfront.org](https://unityfront.org) | [@unityfront](https://twitter.com/unityfront) on Twitter

## Features

- **Random SSH Port Generation:** Ensures SSH runs on a non-standard port to enhance security.
- **SSH Daemon Configuration:** Modifies SSH settings for enhanced security.
- **Firewall Configuration:** Sets up UFW to allow traffic only on the configured SSH port.
- **Fail2Ban Configuration:** Protects against brute-force attacks by configuring Fail2Ban to monitor the SSH port.

## Usage

To use this script, follow these steps:

1. **Clone the repository:**
    ```bash
    git clone <repository_url>
    ```

2. **Navigate to the script directory:**
    ```bash
    cd <repository_directory>
    ```

3. **Make the script executable:**
    ```bash
    chmod +x SSHhardening.sh
    ```

4. **Run the script:**
    ```bash
    ./SSHhardening.sh
    ```

## Functions

### `generate_random_port()`
Generates a random port number between 1025 and 65535.

### `update_system()`
Updates the system and installs necessary packages (`openssh-server`, `fail2ban`, `ufw`).

### `generate_ssh_key()`
Generates an SSH key pair using RSA 4096-bit encryption.

### `prompt_ssh_port()`
Prompts the user for a custom SSH port or generates a random port if none is provided.

### `configure_sshd()`
Configures the SSH daemon with the selected port and disables password authentication.

### `restart_ssh_service()`
Restarts the SSH service to apply the new configuration.

### `setup_firewall()`
Sets up UFW to allow traffic on the selected SSH port and enables the firewall.

### `setup_fail2ban()`
Configures Fail2Ban to monitor the selected SSH port and restarts the Fail2Ban service.

### `gaming_time()`
Displays a completion message indicating the SSH hardening process is complete.

## Important Information

- **Modifications:** Contributions and modifications are welcome.
- **Contact:** For any queries or suggestions, reach out to us at [unityfront.org](https://unityfront.org) or on Twitter [@unityfront](https://twitter.com/unityfront).

## License

This script is open-source and free to use and modify.
