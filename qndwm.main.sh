#!/bin/bash

###
###  This script downloads and installs multiple applications specified from a txt file (../files/app_info.txt),
###  applies patches that are added and uncommented in a txt file (../files/patches.txt), 
###  creates a startup script that is placed in (~/.config/wm/start_apps.sh), 
###  and updates .xinitrc to include this startup script (~/.xinitrc).
###
###  MODIFIED| You do not have to comment or uncomment patches anymore, 
###  since it will ask you if you want to install a patch. . . ON EVERY SINGLE PATCH added to patches.txt,
###  but the formatting is different from patches.txt, so I will make a patches.modified.txt, I am however
###  unsure to if the one that I already have created will even work, since chatgpt gave me 'fake' links. . . 
###
###  This is a visualisation of how the default Folder structure looks like:
###  $HOME/
###  └── .config/
###      └── wm/
###          ├── backups/           # Backup directory for previous installations
###          ├── start_apps.sh      # Startup script for launching applications
###          ├── dwm/                # Directory for dwm installation
###          │   ├── patches/        # Directory for dwm patches
###          │   └── (other files)
###          ├── dmenu/              # Directory for dmenu installation
###          │   ├── patches/        # Directory for dmenu patches
###          │   └── (other files)
###          ├── st/                 # Directory for st installation
###          │   ├── patches/        # Directory for st patches
###          │   └── (other files)
###          ├── slstatus/           # Directory for slstatus installation
###          │   ├── patches/        # Directory for slstatus patches
###          │   └── (other files)
###          └── dwmblocks/          # Directory for dwmblocks installation
###              ├── patches/        # Directory for dwmblocks patches
###              └── (other files)
###

# THIS SCRIPT IS ONLY FUNCTIONAL ON ARCH/ARCH BASED DISTRIBUTIONS.


############ COLOURED BASH TEXT
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


############################################################################################################################### DIRECTORIES

USER="$(whoami)"
BASEDIR="$HOME/bash.qndwm"

FROM_FONT="$BASEDIR/files/fonts.txt"
FROM_APP="$BASEDIR/files/app_info.txt"
FROM_PATCH="$BASEDIR/files/patches.txt"
FROM_PACKAGES="$BASEDIR/files/packages.txt"
FROM_THEMES="$BASEDIR/files/configurations/theming" 
FROM_THEME_FIREFOX="$FROM_THEMES/firefox"
FROM_THEME_FASTFETCH="$FROM_THEMES/fastfetch"
FROM_THEME_GRUB_1K="$FROM_THEMES/grub/1920x1080"
FROM_THEME_GRUB_2K="$FROM_THEMES/grub/2560x1440"
FROM_THEME_GRUB_4K="$FROM_THEMES/grub/3840x2160"

TO_INSTALL_WM_DIR="~/.config/wm"
TO_BACKUP_WM_DIR="$TO_INSTALL_WM_DIR/backups"
TO_INSTALL_FONTS_DIR="~/.local/share/fonts"
TO_INSTALL_FASTFETCH_DIR="~/.config/fastfetch"
TO_INSTALL_GRUB_THEME_DIR="/boot/grub/themes"

CRITICAL_FONT_NAME="JetBrains Mono"
CRITICAL_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"

SESSION_NAME="QnDWM"
SESSION_FILE_NAME="qndwm.session"
QnDWM_FILE_NAME="run.qndwm.sh"
TO_INSTALL_SESSION_FILE_DIR="/usr/share/xsessions/$SESSION_FILE_NAME"
INSTALL_QnDWM_FILE_DIR="$INSTALL_WM_DIR"


############################################################################################################################### FUNCTION
################### PREREQUSITES FROM PACKAGES.TXT (YAY/PARU, FLATPAK & PACMAN)

install_aur_helper() {
    local helper=$1

    if [[ -z "$helper" ]]; then
        echo "Usage: install_aur_helper <helper_name>"
        return 1
    fi

    echo "Installing $helper..."
    
    sudo pacman -S --needed base-devel git -y
    
    git clone https://aur.archlinux.org/${helper}.git
    cd $helper || { echo "Failed to enter directory"; return 1; }
    
    makepkg -si
    
    cd ..
    rm -rf $helper

    echo "$helper installed successfully."
}

install_flatpak() {
    echo "Installing flatpak..."
    
    sudo pacman -S flatpak --noconfirm
    
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    flatpak update

    echo "flatpak installed successfully."
}

install_all() {
    install_aur_helper paru
    install_aur_helper yay
    install_flatpak
}

# Old install script.
install_packages() {
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^# || -z "$line" ]] && continue

        # Extract package manager and package
        package_manager=$(echo "$line" | awk '{print $1}' | tr -d '"')
        package=$(echo "$line" | awk '{print $2}' | tr -d '"')

        # Check if the package is already installed
        if ! command -v "$package" &>/dev/null; then
            echo -e "${PURPLE}Installing $package using $package_manager...${NC}"
            case $package_manager in
                pacman)
                    sudo pacman -S --noconfirm "$package"
                    ;;
                yay)
                    yay -S --noconfirm "$package"
                    ;;
                paru)
                    paru -S --noconfirm "$package"
                    ;;
                flatpak)
                    flatpak install -y "$package"
                    ;;
                *)
                    echo -e "${RED}Unknown package manager: $package_manager${NC}"
                    ;;
            esac
        else
            echo -e "${YELLOW}$package is already installed.${NC}"
        fi
    done < "$FROM_PACKAGES"
}


############################################################################################################################### FUNCTION
################### INSTALL DWM IN "TO_INSTALL_WM_DIR" FROM "~/bash.qndwm/files/scripts/install.and.patch.dwm.sh"


############################################################################################################################### FUNCTION
################### INSTALL ST IN "TO_INSTALL_WM_DIR" FROM "~/bash.qndwm/files/scripts/install.and.patch.st.sh"


############################################################################################################################### FUNCTION
################### INSTALL DMENU IN "TO_INSTALL_WM_DIR" FROM "~/bash.qndwm/files/scripts/install.and.patch.dmenu.sh"


############################################################################################################################### FUNCTION
################### INSTALL ROFI IN "TO_INSTALL_WM_DIR" FROM "~/bash.qndwm/files/scripts/install.and.patch.rofi.sh"


############################################################################################################################### FUNCTION
################### INSTALL DWMBLOCKS IN "TO_INSTALL_WM_DIR" FROM "~/bash.qndwm/files/scripts/install.and.patch.dwmblocks.sh"


############################################################################################################################### FUNCTION
################### INSTALL SLSTATUS IN "TO_INSTALL_WM_DIR" FROM "~/bash.qndwm/files/scripts/install.and.patch.slstatus.sh"


############################################################################################################################### FUNCTION
################### INSTALL NNN IN "TO_INSTALL_WM_DIR" FROM "~/bash.qndwm/files/scripts/install.and.patch.nnn.sh"


############################################################################################################################### FUNCTION
################### 


############################################################################################################################### FUNCTION
################### 


############################################################################################################################### FUNCTION
################### 


############################################################################################################################### FUNCTION
################### 


############################################################################################################################### MAIN FUNCTION
################### MAIN LOGIC

#Install package managers paru, yay, flatpak.
install_all

echo -e "${GREEN}Installing packages from $FROM_PACKAGES...${NC}"
#install_packages
echo -e "${CYAN}Installation complete!${NC}"

