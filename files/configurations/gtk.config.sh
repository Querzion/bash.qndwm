#!/bin/bash

# Function to install and activate icon pack, desktop theme, mouse theme, and font for DWM
setup_custom_themes_dwm() {
    # Define colors
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color

    echo -e "${GREEN}Starting setup of custom themes for DWM...${NC}"

    # Install necessary packages
    echo -e "${YELLOW}Installing necessary packages...${NC}"
    sudo pacman -S --noconfirm git unzip wget

    # Create a temporary directory for downloads
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || { echo -e "${RED}Failed to create temporary directory!${NC}"; exit 1; }

    # Install icon pack
    echo -e "${YELLOW}Downloading and installing icon pack...${NC}"
    wget -qO- https://github.com/vinceliuice/Tela-icon-theme/archive/refs/heads/master.zip -O tela-icon-theme.zip
    unzip -q tela-icon-theme.zip
    cd Tela-icon-theme-master || { echo -e "${RED}Failed to enter icon theme directory!${NC}"; exit 1; }
    ./install.sh -a
    cd ..

    # Install desktop theme
    echo -e "${YELLOW}Downloading and installing desktop theme...${NC}"
    wget -qO- https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/heads/master.zip -O whitesur-gtk-theme.zip
    unzip -q whitesur-gtk-theme.zip
    cd WhiteSur-gtk-theme-master || { echo -e "${RED}Failed to enter desktop theme directory!${NC}"; exit 1; }
    ./install.sh -a
    # Extra settings
    #./install.sh -c Light          # install light theme color only
    #./install.sh -c Dark -c Light  # install dark and light theme colors
    #./install.sh -t red            # install red theme accent only | There are more colours like purple, green, blue etc.
    #./install.sh -t red -t green   # install red and green theme accents
    #./install.sh -t all            # install all available theme accents
    cd ..

    # Install custom mouse theme
    echo -e "${YELLOW}Downloading and installing custom mouse theme...${NC}"
    wget -qO- https://github.com/ful1e5/Bibata_Cursor/archive/refs/heads/main.zip -O bibata-cursor.zip
    unzip -q bibata-cursor.zip
    cd Bibata_Cursor-main || { echo -e "${RED}Failed to enter mouse theme directory!${NC}"; exit 1; }
    sudo cp -r Bibata-* /usr/share/icons/
    cd ..

    # Install JetBrains Mono font
    echo -e "${YELLOW}Downloading and installing JetBrains Mono font...${NC}"
    wget -qO- https://github.com/JetBrains/JetBrainsMono/releases/download/v2.242/JetBrainsMono-2.242.zip -O jetbrains-mono.zip
    unzip -q jetbrains-mono.zip -d jetbrains-mono
    sudo mkdir -p /usr/share/fonts/jetbrains-mono
    sudo cp jetbrains-mono/fonts/ttf/* /usr/share/fonts/jetbrains-mono/
    sudo fc-cache -fv

    # Cleanup temporary directory
    echo -e "${YELLOW}Cleaning up...${NC}"
    cd ..
    rm -rf "$temp_dir"

    # Apply themes and font by modifying configuration files
    echo -e "${YELLOW}Applying themes and font...${NC}"

    # Update .Xresources for the cursor and font
    echo -e "${YELLOW}Updating .Xresources...${NC}"
    {
        echo 'Xcursor.theme: Bibata-Original-Ice'
        echo 'Xcursor.size: 24'
        echo 'URxvt.font: xft:JetBrains Mono:pixelsize=14'
        echo 'URxvt.boldFont: xft:JetBrains Mono:bold:pixelsize=14'
    } >> ~/.Xresources

    xrdb -merge ~/.Xresources

    # Update DWM config.h file for the font (assumes you have the source code)
    if [ -f ~/dwm/config.h ]; then
        echo -e "${YELLOW}Updating DWM config.h...${NC}"
        sed -i 's/^\(#define\s\+FONT.*\)"[a-zA-Z0-9 :.-]*"/\1"JetBrains Mono:size=14"/' ~/dwm/config.h
        echo -e "${YELLOW}Recompiling DWM...${NC}"
        (cd ~/dwm && sudo make clean install)
    else
        echo -e "${RED}DWM config.h not found! Skipping DWM font update.${NC}"
    fi

    echo -e "${GREEN}Custom themes setup completed for DWM!${NC}"
}

# Uncomment the following line to run the function if this script is executed directly
# setup_custom_themes_dwm
