#!/bin/bash

# Author: Thomas Francois
# Mail: contact@thomasfrancois.net

# Description: Give a brief report of the systems


# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Check if the script is run as root
if [ "$(id -u)" -ne 0; then
    echo -e "${RED}Please run this script as root.${NC}"
    exit 1
fi

# Parsing arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output)
            enabled=true
            output=$2
            shift 2
            ;;
        *)
            echo -e "${RED}Invalid argument: $1${NC}"
            exit 1
            ;;
    esac
done

# Clear the output file
> $output

echo -e "${CYAN}Gathering system information...${NC}"

# Function to gather OS Information
gather_os_info() {
    echo -e "\n${YELLOW}=== OS Information ===${NC}" | tee -a $output
    cat /etc/os-release | tee -a $output
    echo -e "${WHITE}Kernel:${NC} $(uname -r)" | tee -a $output
}

# Function to gather Hardware Information
gather_hardware_info() {
    echo -e "\n${YELLOW}=== Hardware Information ===${NC}" | tee -a $output
    echo -e "${WHITE}CPU:${NC} $(lscpu | grep 'Model name' | awk -F: '{print $2}' | sed 's/^ *//g')" | tee -a $output
    echo -e "${WHITE}RAM:${NC} $(free -h | grep Mem | awk '{print $2}')" | tee -a $output
    echo -e "${WHITE}Disk:${NC} $(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep disk | awk '{print $1, $2}')" | tee -a $output
}

# Function to gather Network Information
gather_network_info() {
    echo -e "\n${YELLOW}=== Network Information ===${NC}" | tee -a $output
    ip a | grep -w inet | awk '{print $2, $7}' | tee -a $output
    echo -e "\n${WHITE}Routing Table:${NC}" | tee -a $output
    route -n | tee -a $output
    echo -e "\n${WHITE}DNS Configuration:${NC}" | tee -a $output
    cat /etc/resolv.conf | tee -a $output
}

# Function to gather Storage Information
gather_storage_info() {
    echo -e "\n${YELLOW}=== Storage Information ===${NC}" | tee -a $output
    df -h | tee -a $output
    echo -e "\n${WHITE}Mounted Filesystems:${NC}" | tee -a $output
    lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT | tee -a $output
}

# Function to gather Security Settings
gather_security_info() {
    echo -e "\n${YELLOW}=== Security Settings ===${NC}" | tee -a $output
    echo -e "\n${WHITE}Firewall Status:${NC}" | tee -a $output

    # Check for firewalld
    if systemctl is-active --quiet firewalld; then
        echo -e "${GREEN}firewalld is active${NC}" | tee -a $output
        firewall-cmd --list-all | tee -a $output
    fi

    # Check for iptables
    if systemctl is-active --quiet iptables; then
        echo -e "${GREEN}iptables is active${NC}" | tee -a $output
        iptables -L | tee -a $output
    fi

    # Check for nftables
    if systemctl is-active --quiet nftables; then
        echo -e "${GREEN}nftables is active${NC}" | tee -a $output
        nft list ruleset | tee -a $output
    fi

    # Check for ufw
    if systemctl is-active --quiet ufw; then
        echo -e "${GREEN}ufw is active${NC}" | tee -a $output
        ufw status verbose | tee -a $output
    fi

    # Check for csf
    if command -v csf > /dev/null 2>&1; then
        if csf -l > /dev/null 2>&1; then
            echo -e "${GREEN}csf is active${NC}" | tee -a $output
            csf -l | tee -a $output
        fi
    fi
}

# Function to gather User Information
gather_user_info() {
    echo -e "\n${YELLOW}=== User Information ===${NC}" | tee -a $output
    echo -e "${WHITE}Current User:${NC} $(whoami)" | tee -a $output
    echo -e "${WHITE}Logged in Users:${NC}" | tee -a $output
    who | tee -a $output
}

# Function to gather Process Information
gather_process_info() {
    echo -e "\n${YELLOW}=== Process Information ===${NC}" | tee -a $output
    echo -e "${WHITE}Top 10 memory-consuming processes:${NC}" | tee -a $output
    ps aux --sort=-%mem | head -n 11 | tee -a $output
}

# Main function to call all the other functions
main() {
    gather_os_info
    gather_hardware_info
    gather_network_info
    gather_storage_info
    gather_security_info
    gather_user_info
    gather_process_info

    echo -e "\n${CYAN}=== End of Report ===${NC}" | tee -a $output
    if [ "$enabled" = true ]; then
        echo -e "\n${CYAN}System information has been saved to $output.${NC}"
    fi
}

# Execute the main function
main
