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
BASEDIR="~/bash.qndwm"

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

# Function to check if a package is installed
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package using the appropriate package manager
install_with_package_manager() {
    local manager="$1"
    local package="$2"

    case $manager in
        yay|paru)
            if ! is_installed "$manager"; then
                echo "$manager is not installed. Installing $manager..."
                sudo pacman -S --noconfirm "$manager"
            fi
            sudo "$manager" -S --noconfirm "$package"
            ;;
        pacman)
            if ! is_installed "pacman"; then
                echo "Pacman is not installed. Please install it first."
                exit 1
            fi
            sudo pacman -S --noconfirm "$package"
            ;;
        flatpak)
            if ! is_installed "flatpak"; then
                echo "Flatpak is not installed. Installing Flatpak..."
                sudo pacman -S --noconfirm flatpak
            fi
            flatpak install -y "$package"
            ;;
        *)
            echo "Unknown package manager: $manager"
            ;;
    esac
}

# Function to read and install packages from the packages.txt file
install_packages() {
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Extract manager, package, and description
        if [[ "$line" =~ ^\# ]]; then
            continue
        elif [[ "$line" =~ ^##### ]]; then
            section="${line###### }"
            echo "Installing packages from section: $section"
        else
            # Read the manager and package
            if [[ "$line" =~ ^\"([^\"]+)\" ]]; then
                manager="${BASH_REMATCH[1]}"
                package="$(echo "$line" | awk '{print $2}' | tr -d '\"')"
                install_with_package_manager "$manager" "$package"
            fi
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
