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
PATCH_CONFIG_FILE="patches.modified.txt"

################################################################### FILE & FOLDER PATHS
############ FILE & FOLDER PATHS

# Script Locations
FOLDER="bash.lazy-dwm"
LOCATION="$HOME/$FOLDER/files"

# Installation Path
INSTALL_LOCATION="$HOME/.config/wm"
BACKUP_DIR="$INSTALL_LOCATION/backups"

################################################################### FUNCTIONS
############ FUNCTIONS

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

apply_patches() {
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
        patch_description=$(echo $line | cut -d' ' -f3-)

        if [[ "$patch_app" == "$APP" ]]; then
            read -p "Do you want to apply patch $patch_description? (y/n): " apply_patch
            if [ "$apply_patch" = "y" ] || [ "$apply_patch" = "Y" ]; then
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

apply_patches() {
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
        patch_description=$(echo $line | cut -d' ' -f3-)

        if [[ "$patch_app" == "$APP" ]]; then
            read -p "Do you want to apply patch $patch_description? (y/n): " apply_patch
            if [ "$apply_patch" = "y" ] || [ "$apply_patch" = "Y" ]; then
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

if [[ ! -f "$APP_CONFIG_FILE" ]]; then
    print_message $RED "Error: Application configuration file $APP_CONFIG_FILE not found."
    exit 1
fi

if [[ ! -f "$PATCH_CONFIG_FILE" ]]; then
    print_message $RED "Error: Patch configuration file $PATCH_CONFIG_FILE not found."
    exit 1
fi

read -p "Do you want to apply patches? (y/n): " apply_all_patches
if [ "$apply_all_patches" = "y" ] || [ "$apply_all_patches" = "Y" ]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        APP=$(echo $line | cut -d' ' -f1)
        DESCRIPTION=$(echo $line | cut -d' ' -f2- | rev | cut -d' ' -f2- | rev)
        FROM_HERE=$(echo $line | awk '{print $NF}')

        install_APP "$APP" "$DESCRIPTION" "$FROM_HERE"

        read -p "Do you want to install patches for $APP $DESCRIPTION? (y/n): " install_patches
        if [ "$install_patches" = "y" ] || [ "$install_patches" = "Y" ]; then
            read -p "Do you want to apply all patches for $APP $DESCRIPTION? (y/n): " apply_all
            if [ "$apply_all" = "y" ] || [ "$apply_all" = "Y" ]; then
                apply_patches "$APP" "$DESCRIPTION"
            else
                while IFS= read -r line || [[ -n "$line" ]]; do
                    patch_app=$(echo $line | cut -d' ' -f1)
                    patch_url=$(echo $line | awk '{print $2}')
                    patch_description=$(echo $line | cut -d' ' -f3-)

                    if [[ "$patch_app" == "$APP" ]]; then
                        read -p "Do you want to apply patch $patch_description? (y/n): " apply_patch
                        if [ "$apply_patch" = "y" ] || [ "$apply_patch" = "Y" ]; then
                            patch_file=$(basename "$patch_url")
                            print_message $CYAN "Downloading patch from $patch_url"
                            wget "$patch_url" -O "$patch_file"
                            if patch -Np1 -i "$patch_file" -d "$INSTALL_LOCATION/$APP"; then
                                print_message $GREEN "Applied patch $patch_file successfully."
                            else
                                print_message $RED "Failed to apply patch $patch_file."
                                exit 1
                            fi
                        fi
                    fi
                done < "$PATCH_CONFIG_FILE"
            fi
        fi
        
        configure_APP "$APP" "$DESCRIPTION"
        
    done < "$APP_CONFIG_FILE"
fi

create_startup_script

# Update .xinitrc
update_xinitrc

# End of script
print_message $GREEN "All tasks completed."
