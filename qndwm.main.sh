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
ERROR_LOG="$HOME/install.errors.txt"

FROM_FONT="$BASEDIR/files/fonts.txt"
FROM_APP="$BASEDIR/files/app_info.txt"
FROM_PATCH="$BASEDIR/files/patches.txt"
FROM_PACKAGES_LIST="$BASEDIR/files/packages.txt"
FROM_THEMES="$BASEDIR/files/configurations/theming" 
FROM_THEME_FIREFOX="$FROM_THEMES/firefox"
FROM_THEME_FASTFETCH="$FROM_THEMES/fastfetch"
FROM_THEME_GRUB_1K="$FROM_THEMES/grub/1920x1080"
FROM_THEME_GRUB_2K="$FROM_THEMES/grub/2560x1440"
FROM_THEME_GRUB_4K="$FROM_THEMES/grub/3840x2160"
FROM_SCRIPT="$BASEDIER/files/scripts"

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
################### ENABLE MULTILIB & ARCO MIRRORS

enable_multilib() {
    local pacman_conf="/etc/pacman.conf"
    
    if [ ! -f "$pacman_conf" ]; then
        echo "Error: $pacman_conf not found."
        return 1
    fi

    # Check if the multilib section is already uncommented
    if grep -q '^\[multilib\]' "$pacman_conf"; then
        echo "Multilib repository is already enabled."
        return 0
    fi

    # Backup the original pacman.conf
    sudo cp "$pacman_conf" "${pacman_conf}.bak"

    # Uncomment the multilib section
    sudo sed -i '/#\[multilib\]/{s/^#//;n;s/^#//}' "$pacman_conf"

    echo "Multilib repository has been enabled."
    return 0
}


############################################################################################################################### FUNCTION
################### PREREQUSITES | INSTALLATION OF PACKAGE MANAGERS

install_aur_helper() {
    local helper=$1

    if [[ -z "$helper" ]]; then
        echo -e "${RED} Usage: install_aur_helper <helper_name>${NC}"
        return 1
    fi

    if command -v "$helper" &>/dev/null; then
        echo -e "${GREEN} $helper is already installed.${NC}"
        return 0
    fi

    echo -e "${CYAN} Installing $helper...${NC}"

    sudo pacman -S --needed base-devel git

    git clone https://aur.archlinux.org/${helper}.git
    cd $helper || { echo -e "${RED} Failed to enter directory${NC}"; return 1; }

    makepkg -si

    cd ..
    rm -rf $helper

    echo -e "${GREEN} $helper installed successfully.${NC}"
}

install_flatpak() {
    if command -v flatpak &>/dev/null; then
        echo -e "${GREEN} flatpak is already installed.${NC}"
        return 0
    fi

    echo -e "${CYAN} Installing flatpak...${NC}"

    sudo pacman -S flatpak

    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    flatpak update

    echo -e "${GREEN} flatpak installed successfully.${NC}"
}

install_package_managers() {
    install_aur_helper paru
    install_aur_helper yay
    install_flatpak
}

package_manager_version() {
    
    echo -e "${YELLOW}                       $(yay --version)${NC}"
    echo -e "${YELLOW}                       $(paru --version)${NC}"
    echo -e "${YELLOW}                       $(flatpak --version)${NC}"
    echo -e "${YELLOW}  $(pacman --version)${NC}"
}

############################################################################################################################### FUNCTION
################### INSTALLATION OF PACKAGES


# Function to install packages using different package managers
install_package() {
    local manager=$1
    local package=$2

    # Check if the package is already installed
    case "$manager" in
        pacman)
            if pacman -Q "$package" &>/dev/null; then
                echo -e "${YELLOW} Package $package is already installed. Skipping.${NC}"
                return
            fi
            ;;
        yay|paru)
            if pacman -Q "$package" &>/dev/null; then
                echo -e "${YELLOW} Package $package is already installed. Skipping.${NC}"
                return
            fi
            ;;
        flatpak)
            if flatpak list --app | grep -q "$package"; then
                echo -e "${YELLOW} Package $package is already installed. Skipping.${NC}"
                return
            fi
            ;;
        *)
            echo -e "${BLUE} Unknown package manager: $manager${NC}"
            return
            ;;
    esac

    # Attempt to install the package
    case "$manager" in
        pacman)
            echo -e "${PURPLE} Installing $package with $manager...${NC}"
            sudo pacman -S --noconfirm "$package" || echo "$manager $package" >> "$ERROR_LOG"
            ;;
        yay)
            echo -e "${PURPLE} Installing $package with $manager...${NC}"
            yay -S --noconfirm "$package" || echo "$manager $package" >> "$ERROR_LOG"
            ;;
        paru)
            echo -e "${PURPLE} Installing $package with $manager...${NC}"
            paru -S --noconfirm "$package" || echo "$manager $package" >> "$ERROR_LOG"
            ;;
        flatpak)
            echo -e "${PURPLE} Installing $package with $manager...${NC}"
            remote=$(echo "$package" | cut -d'/' -f1)
            app_id=$(echo "$package" | cut -d'/' -f2-)
            flatpak install -y "$remote" "$app_id" || echo "$manager $package" >> "$ERROR_LOG"
            ;;
    esac
}

# Function to read the package list and install packages
read_package_list() {
    local package_list="$1"

    # Read the package list file line by line
    while IFS= read -r line; do
        # Skip empty lines and lines starting with #
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Parse the line to get the package manager and package name
        if [[ "$line" =~ ^\"(.+)\"\ \"(.+)\" ]]; then
            manager="${BASH_REMATCH[1]}"
            package="${BASH_REMATCH[2]}"
            install_package "$manager" "$package"
        fi
    done < "$package_list"
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
################### SET UP THE NETWORK

git clone https://github.com/Querzion/bash.network.git $HOME

chmod +x -r $HOME/bash.network

sh $HOME/bash.network/start.sh


############################################################################################################################### FUNCTION
################### 


############################################################################################################################### FUNCTION
################### 


############################################################################################################################### FUNCTION
################### 


############################################################################################################################### MAIN FUNCTION
################### MAIN LOGIC

# Fast Track mirrors
sudo pacman-mirrors --fasttrack

# Call the function
enable_multilib

# Install package managers paru, yay, flatpak.
install_package_managers
install_package_managers # to ensure that they are indeed installed
    
# Check the version of pacman, yay, paru, flatpak
package_manager_version
    
# Pause the script
echo -e "${GREEN} PRESS ENTER TO CONTINUE. ${NC}"
read

# Clear the error log file
> "$ERROR_LOG"

# Call the function to read the package list and install packages
echo -e "${CYAN} Starting package installation...${NC}"
read_package_list "$FROM_PACKAGES_LIST"
echo -e "${CYAN} Package installation complete.${NC}"

# Check if there were any errors
if [[ -s "$ERROR_LOG" ]]; then
    echo -e "${RED} Some packages failed to install. See $ERROR_LOG for details.${NC}"
else
    echo -e "${GREEN} All packages installed successfully.${NC}"
fi











echo -e "${CYAN} Installation complete!${NC}"

