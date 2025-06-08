#!/bin/bash

# Couleurs ANSI
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Titre avec figlet
if command -v figlet &> /dev/null; then
    echo -e "${CYAN}"
    figlet "$(hostname)"
    echo -e "${NC}"
else
    echo -e "${CYAN}*** $(hostname) ***${NC}"
fi

# Signature
echo -e "${YELLOW}by alchemist${NC}"
echo

# Récapitulatif système
echo -e "${GREEN}🕒 Uptime      :${NC} $(uptime -p)"
echo -e "${GREEN}🧠 RAM         :${NC} $(free -h | awk '/Mem:/ {print $3 " / " $2}')"
echo -e "${GREEN}📡 IP Adresse  :${NC} $(hostname -I | awk '{print $1}')"
echo -e "${GREEN}💾 Espace disque:${NC} $(df -h / | awk 'NR==2 {print $3 " / " $2 " used (" $5 ")"}')"
echo
