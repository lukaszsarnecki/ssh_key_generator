#!/bin/bash

# =============================================================================
# Script: ssh_key_generator.sh
# Author: Lukasz Sarnecki
# Date: 11.11.2025
# =============================================================================

# --- SCRIPT SETTINGS ---
# These options make the script stop if any error occurs.
set -Eeuo pipefail

# If an error occurs, this command will display a message with the line number where it happened.
trap 'echo -e "\e[31mERROR:\e[0m the script stopped at line $LINENO." >&2' ERR

# --- VARIABLE PREPARATION ---
# Here we define variables that will store data provided by the user.
SSH_KEY_DIR="${HOME}/.ssh" # Path to the .ssh folder in the home directory.
HOST=""                   # Stores the name of the server where the key will be copied.
HOST_USER=""              # Stores the username on that server.
PORT=""                   # Stores the SSH port number.
NAME=""                   # Stores the name for the new key.

# --- HELP FUNCTION ---
# This function displays the script usage instructions.
print_help() {
# Displays the following block of text until the line containing 'EOF'.
cat <<'EOF'
DESCRIPTION:
  A script for generating a new SSH key pair (ed25519) and securely
  copying the public key to a remote server.

USAGE:
  ./ssh-key-helper.sh -n <key_name> -H <remote_host> -u <user> [OPTIONS]

  If the script is run without arguments, this help menu will be displayed.

REQUIRED OPTIONS:
  -n, --name <name>       Name for the key (e.g., "devops"). Resulting file: id_devops_ed25519
  -H, --hostname <host>   Remote host name or IP address where the key will be copied.
  -u, --user <user>       Username on the remote host.

OPTIONAL OPTIONS:
  -P, --port <number>     SSH port on the remote host (default: 22).
  -h, --help              Display this help message.
EOF
}

# --- MAIN SCRIPT LOGIC ---
# Checks if the user ran the script without any parameters.
if [ "$#" -eq 0 ]; then
    print_help # If so, show help.
    exit 0     # And exit.
fi

# --- READING PARAMETERS ---
# This command parses and organizes the parameters provided when running the script (e.g. -n, --name).
PARSED=$(getopt -o n:H:u:P:h --long name:,hostname:,user:,port:,help -- "$@")
# Checks if the parameters were provided correctly.
if ! [ "$?" -eq 0 ]; then
    print_help
    exit 1
fi
# Updates the list of parameters so the loop below can read them properly.
eval set -- "$PARSED"

# This loop reads each parameter and assigns its value to the correct variable.
while true; do
  case "$1" in
    -n|--name) NAME="$2"; shift 2;;
    -H|--hostname) HOST="$2"; shift 2;;
    -u|--user) HOST_USER="$2"; shift 2;;
    -P|--port) PORT="$2"; shift 2;;
    -h|--help) print_help; exit 0;;
    --) shift; break;;
    *) echo "Error - missing or invalid parameters"; exit 1 ;;
  esac
done

# --- PARAMETER VALIDATION ---
# Checks if the user provided all required information.
if [[ -z "$NAME" || -z "$HOST" || -z "$HOST_USER" ]]; then
  # If something is missing, show an error and explain what is required.
  echo -e "\e[31mERROR:\e[0m Missing required arguments: -n, -H, and -u are mandatory." >&2
  echo -e "\e[33mUse the -h option to display help.\e[0m" >&2
  exit 1
fi

# --- FILE NAME PREPARATION ---
# Based on the given name, build the full filenames for the SSH key files.
SSH_KEY_NAME="id_${NAME}_rsa"
SSH_KEY_PATH="${SSH_KEY_DIR}/${SSH_KEY_NAME}"
SSH_PUB_KEY="${SSH_KEY_PATH}.pub"

# --- SSH KEY GENERATION ---
echo -e "\e[34m===> Checking/Creating SSH key...\e[0m"
# Creates the .ssh folder if it doesn’t already exist.
mkdir -p "$SSH_KEY_DIR"
# Sets secure permissions for this folder (only the owner can access it).
chmod 700 "$SSH_KEY_DIR"

# Checks if a key file with that name already exists.
if [[ -f "$SSH_KEY_PATH" ]]; then
    # If it exists, show a warning and skip creation.
    echo -e "\e[33mWARNING:\e[0m Key ${SSH_KEY_PATH} already exists. Skipping creation."
else
    # If not, generate a new SSH key with no passphrase.
    ssh-keygen -t ed25519 -a 100 -f "$SSH_KEY_PATH" -C "${USER}@$(hostname)-$(date +%F)" -N ""
    echo -e "\e[32m✓ Key generated successfully:\e[0m ${SSH_KEY_PATH}"
fi

# --- COPYING KEY TO REMOTE SERVER ---
echo -e "\n\e[34m===> Copying public key to ${HOST_USER}@${HOST}...\e[0m"

# Prepare the port option (-p) if provided by the user.
PORT_ARG=""
if [[ -n "$PORT" ]]; then
    PORT_ARG="-p ${PORT}"
fi

# Check if the 'ssh-copy-id' command is available.
if command -v ssh-copy-id > /dev/null 2>&1; then
    # If 'ssh-copy-id' is available, use it to copy the key (recommended method).
    ssh-copy-id -i "$SSH_PUB_KEY" ${PORT_ARG} "${HOST_USER}@${HOST}"
    echo -e "\e[32m✓ Key successfully copied using ssh-copy-id.\e[0m"
else
    # If 'ssh-copy-id' is not available, use an alternative manual method.
    echo -e "\e[33mWARNING:\e[0m ssh-copy-id command not found. Using alternative method.\e[0m"
    # This command logs in to the server and appends the public key to the `authorized_keys` file.
    ssh "${HOST_USER}@${HOST}" ${PORT_ARG} "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" < "$SSH_PUB_KEY"
    echo -e "\e[32m✓ Key should now be added to authorized_keys on the remote host.\e[0m"
fi

# --- COMPLETION ---
echo -e "\n\e[32mDONE!\e[0m"
# Displays a message with an example SSH login command.
echo -e "You can now log in using: ssh ${PORT_ARG} -i ${SSH_KEY_PATH} ${HOST_USER}@${HOST}"

