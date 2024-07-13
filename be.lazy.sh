#!/bin/bash

###
###  This script downloads and installs multiple applications specified from a txt file (../files/app_info.txt),
###  applies patches that are added and uncommented in a txt file (../files/patches.txt), 
###  creates a startup script that is placed in (~/.config/wm/start_apps.sh), 
###  and updates .xinitrc to include this startup script (~/.xinitrc).
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

############ COLOURED BASH TEXT

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

############################### SETTINGS
USER="$(whoami)"
APP_CONFIG_FILE="app_info.txt"
PATCH_CONFIG_FILE="patches.txt"

################################################################### FILE & FOLDER PATHS
############ FILE & FOLDER PATHS

# Script Locations
FOLDER="$HOME/bash.lazy-dwm"
LOCATION="$FOLDER/files"

# Installation Path
INSTALL_LOCATION="$HOME/.config/wm"
BACKUP_DIR="$INSTALL_LOCATION/backups"

################################################################### FUNCTIONS
############ FUNCTIONS

prerequisites() {
    # Define the file location
    FILE_LOCATION="$LOCATION/packages.txt"

    # Check if packages.txt exists
    if [[ ! -f "$FILE_LOCATION" ]]; then
        echo -e "${RED}packages.txt file not found at $FILE_LOCATION!${NC}"
        exit 1
    fi

    # Function to check if a package is installed
    is_installed() {
        pacman -Qs "$1" &> /dev/null
    }

    # Update package database
    echo -e "${YELLOW}Updating package database...${NC}"
    sudo pacman -Sy

    # Read the packages from packages.txt and install if not already installed
    while read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] && continue

        # Install the package if not already installed
        if ! is_installed "$line"; then
            echo -e "${YELLOW}Installing $line...${NC}"
            sudo pacman -S --noconfirm "$line"
            if is_installed "$line"; then
                echo -e "${GREEN}$line successfully installed.${NC}"
            else
                echo -e "${RED}Failed to install $line.${NC}"
            fi
        else
            echo -e "${GREEN}$line is already installed.${NC}"
        fi
    done < "$FILE_LOCATION"

    echo -e "${GREEN}All packages processed.${NC}"
}



print_message() {
    color=$1
    message=$2
    echo -e "${color}${message}${NC}"
}

backup_APP() {
    local APP=$1
    local DESCRIPTION=$2
    local TO_INSTALL_LOCATION="$INSTALL_LOCATION/$APP"

    SOURCE_FOLDER="$TO_INSTALL_LOCATION"
    DEST_FOLDER="$BACKUP_DIR"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    ZIP_FILENAME="$DEST_FOLDER/$APP-$USER.$TIMESTAMP.zip"

    print_message $PURPLE "Creating a backup of the prior $APP $DESCRIPTION installation..."

    zip -r "$ZIP_FILENAME" "$SOURCE_FOLDER"

    if [ $? -eq 0 ]; then
        print_message $GREEN "Folder '$SOURCE_FOLDER' successfully zipped into '$ZIP_FILENAME'."
        rm -rf "$SOURCE_FOLDER"
        print_message $GREEN "Source folder '$SOURCE_FOLDER' deleted."
    else
        print_message $RED "Error: Failed to zip the folder."
        exit 1
    fi
}

install_APP() {
    local APP=$1
    local DESCRIPTION=$2
    local FROM_HERE=$3
    local TO_INSTALL_LOCATION="$INSTALL_LOCATION/$APP"

    print_message $YELLOW "Creating folder for $APP $DESCRIPTION installation..."
    mkdir -p $INSTALL_LOCATION

    read -p "Do you want to backup prior $APP-$USER install? (y/n): " CHOICE1
    if [ "$CHOICE1" = "y" ] || [ "$CHOICE1" = "Y" ]; then
        backup_APP "$APP" "$DESCRIPTION"
    fi

    print_message $YELLOW "Getting new $APP $DESCRIPTION source files..."
    git clone $FROM_HERE $TO_INSTALL_LOCATION && cd $TO_INSTALL_LOCATION

    print_message $YELLOW "Compiling $APP $DESCRIPTION..."
    sudo make clean install

    print_message $GREEN "$APP installed successfully."
}

configure_APP() {
    local APP=$1
    local DESCRIPTION=$2
    local TO_INSTALL_LOCATION="$INSTALL_LOCATION/$APP"
    local CONFIG="$LOCATION/settings/.config/$APP/config.def.h"

    if [[ -f "$CONFIG" ]]; then
        print_message $PURPLE "Configuring $APP $DESCRIPTION."
        print_message $YELLOW "Making a backup."
        sudo mv $TO_INSTALL_LOCATION/config.def.h $TO_INSTALL_LOCATION/config.def.h.bak
        print_message $YELLOW "Copying a new config.def.h to the directory."
        sudo cp $CONFIG $TO_INSTALL_LOCATION

        cd $TO_INSTALL_LOCATION
        sudo rm config.h
        sudo make clean install

        print_message $GREEN "$APP is now reconfigured."
    else
        print_message $RED "No configuration file found for $APP. Skipping configuration."
    fi
}

patch_APP() {
    local APP=$1
    local DESCRIPTION=$2
    local TO_INSTALL_LOCATION="$INSTALL_LOCATION/$APP"
    local PATCHES_DIR="$TO_INSTALL_LOCATION/patches"

    mkdir -p $PATCHES_DIR
    print_message $CYAN "Created patches directory at $PATCHES_DIR"
    cd $PATCHES_DIR

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        patch_app=$(echo $line | cut -d' ' -f1)
        patch_url=$(echo $line | awk '{print $2}')

        if [[ "$patch_app" == "$APP" ]]; then
            patch_file=$(basename "$patch_url")
            print_message $CYAN "Downloading patch from $patch_url"
            wget "$patch_url" -O "$patch_file"
            if patch -Np1 -i "$patch_file" -d "$TO_INSTALL_LOCATION"; then
                print_message $GREEN "Applied patch $patch_file successfully."
            else
                print_message $RED "Failed to apply patch $patch_file."
                exit 1
            fi
        fi
    done < "$PATCH_CONFIG_FILE"

    cd $TO_INSTALL_LOCATION
    if sudo make clean install; then
        print_message $GREEN "$APP compiled and installed successfully."
    else
        print_message $RED "Failed to compile and install $APP."
        exit 1
    fi
}

create_startup_script() {
    STARTUP_SCRIPT="$HOME/.config/wm/start_apps.sh"
    
    if [[ ! -f $STARTUP_SCRIPT ]]; then
        echo "#!/bin/bash" > $STARTUP_SCRIPT
        echo "exec dwm &" >> $STARTUP_SCRIPT
        echo "dmenu &" >> $STARTUP_SCRIPT
        echo "st &" >> $STARTUP_SCRIPT
        echo "slstatus &" >> $STARTUP_SCRIPT
        echo "dwmblocks &" >> $STARTUP_SCRIPT
        echo "nnn &" >> $STARTUP_SCRIPT
        
        chmod +x $STARTUP_SCRIPT
        print_message $GREEN "Created startup script at $STARTUP_SCRIPT."
    else
        print_message $YELLOW "Startup script already exists at $STARTUP_SCRIPT."
    fi
}

update_xinitrc() {
    XINITRC="$HOME/.xinitrc"
    
    if ! grep -q "start_apps.sh" "$XINITRC"; then
        echo "bash $HOME/.config/wm/start_apps.sh" >> $XINITRC
        print_message $GREEN "Added startup script to $XINITRC."
    else
        print_message $YELLOW "Startup script already present in $XINITRC."
    fi
}

################################################################### MAIN LOGIC
############ MAIN LOGIC

prerequisites


if [[ ! -f "$APP_CONFIG_FILE" ]]; then
    print_message $RED "Error: Application configuration file $APP_CONFIG_FILE not found."
    exit 1
fi

if [[ ! -f "$PATCH_CONFIG_FILE" ]]; then
    print_message $RED "Error: Patch configuration file $PATCH_CONFIG_FILE not found."
    exit 1
fi

while IFS= read -r line || [[ -n "$line" ]]; do
    APP=$(echo $line | cut -d' ' -f1)
    DESCRIPTION=$(echo $line | cut -d' ' -f2- | rev | cut -d' ' -f2- | rev)
    FROM_HERE=$(echo $line | awk '{print $NF}')

    install_APP "$APP" "$DESCRIPTION" "$FROM_HERE"

    read -p "Do you want to configure $APP? (y/n): " CHOICE2
    if [ "$CHOICE2" = "y" ] || [ "$CHOICE2" = "Y" ]; then
        configure_APP "$APP" "$DESCRIPTION"
    fi

    read -p "Do you want to patch $APP? (y/n): " CHOICE3
    if [ "$CHOICE3" = "y" ] || [ "$CHOICE3" = "Y" ]; then
        patch_APP "$APP" "$DESCRIPTION"
    fi

    print_message $GREEN "All tasks for $APP completed."
done < "$APP_CONFIG_FILE"

# Create startup script and update .xinitrc
create_startup_script
update_xinitrc

print_message $GREEN "All tasks completed."
