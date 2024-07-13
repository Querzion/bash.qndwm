#!/bin/bash

###
###  This script downloads and installs multiple applications specified from a txt file (../files/app_info.txt),
###  applies patches that are added and uncommented in a txt file (../files/patches.txt), 
###  creates a startup script that is placed in (~/.config/wm/$QnDWM_FILE), 
###  and updates .xinitrc to include this startup script (~/.xinitrc).
###

############ COLOURED BASH TEXT
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
SESSION_NAME="QnDWM"
SESSION_FILE_NAME="qndwm.session"
QnDWM_FILE="run.qndwm.sh"

################################################################### FILE & FOLDER PATHS
FOLDER="$HOME/bash.qndwm"
LOCATION="$FOLDER/files"
INSTALL_LOCATION="$HOME/.config/wm"
BACKUP_DIR="$INSTALL_LOCATION/backups"

################################################################### FUNCTIONS

prerequisites() {
    FILE_LOCATION="$LOCATION/packages.txt"

    if [[ ! -f "$FILE_LOCATION" ]]; then
        echo -e "${RED}packages.txt file not found at $FILE_LOCATION!${NC}"
        exit 1
    fi

    is_installed() {
        pacman -Qs "$1" &> /dev/null
    }

    echo -e "${YELLOW}Updating package database...${NC}"
    sudo pacman -Sy

    while read -r line; do
        [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] && continue

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
    STARTUP_SCRIPT="$INSTALL_LOCATION/$QnDWM_FILE"
    
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
    
    # Backup current .xinitrc if it exists
    if [[ ! -f "$XINITRC" ]]; then
        echo "#!/bin/bash" > "$XINITRC"
    fi

    # Ensure dwm is the default session
    if ! grep -q "DEFAULT_SESSION=$SESSION_NAME" "$XINITRC"; then
        echo "DEFAULT_SESSION=$SESSION_NAME" >> "$XINITRC"
        echo "case \$1 in" >> "$XINITRC"
        echo "  qndwm)" >> "$XINITRC"
        echo "    exec $INSTALL_LOCATION/$QnDWM_FILE" >> "$XINITRC"
        echo "    ;;" >> "$XINITRC"
        echo "  anotherdesktop)" >> "$XINITRC"
        echo "    exec startanotherdesktop" >> "$XINITRC"
        echo "    ;;" >> "$XINITRC"
        echo "  *)" >> "$XINITRC"
        echo "    exec \$DEFAULT_SESSION" >> "$XINITRC"
        echo "    ;;" >> "$XINITRC"
        echo "esac" >> "$XINITRC"
    fi

    # Check if startup script is already referenced
    if ! grep -q "$QnDWM_FILE" "$XINITRC"; then
        echo "bash $INSTALL_LOCATION/$QnDWM_FILE" >> "$XINITRC"
        print_message $GREEN "Added startup script to $XINITRC."
    else
        print_message $YELLOW "Startup script is present in $XINITRC."
    fi

    # Make .xinitrc executable
    chmod +x "$XINITRC"
    print_message $GREEN "Configured and set .xinitrc as executable."
}

configure_slim() {

    # Enable SLiM to start at boot
    sudo systemctl enable slim
    print_message $GREEN "Enabled SLiM to start at boot."
}

theme_grub() {
    # Define GRUB configuration and theme paths
    GRUB_CONFIG="/etc/default/grub"
    GRUB_THEME="/boot/grub/themes/arch/theme.txt"

    # Backup existing GRUB config
    sudo cp $GRUB_CONFIG ${GRUB_CONFIG}.bak
    print_message $PURPLE "Backup of $GRUB_CONFIG created."

    # Update GRUB configuration for the theme
    echo "GRUB_THEME=\"${GRUB_THEME}\"" | sudo tee -a $GRUB_CONFIG

    # Update GRUB
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    print_message $GREEN "GRUB configured and updated."
}

create_session_file() {
    SESSION_FILE="/usr/share/xsessions/$SESSION_FILE_NAME"
    
    if [[ ! -f $SESSION_FILE ]]; then
        echo "[Desktop Entry]" > $SESSION_FILE
        echo "Name=$SESSION_NAME" >> $SESSION_FILE
        echo "Comment=Dynamic Window Manager" >> $SESSION_FILE
        echo "Exec=$INSTALL_LOCATION/$QnDWM_FILE" >> $SESSION_FILE
        echo "Type=Application" >> $SESSION_FILE
        echo "X-LightDM-DesktopName=$SESSION_NAME" >> $SESSION_FILE
        echo "DesktopNames=$SESSION_NAME" >> $SESSION_FILE
        echo "X-Ubuntu-Gettext-Domain=lightdm" >> $SESSION_FILE
        
        print_message $GREEN "Created session file at $SESSION_FILE."
    else
        print_message $YELLOW "Session file already exists at $SESSION_FILE."
    fi
}

################################################################### MAIN LOGIC

# UPDATE SYSTEM (YOU NEVER KNOW)
sudo pacman -Syyu -y

# INSTALLS WHAT'S ADDED TO - packages.txt
prerequisites

#    FILE EXISTENCE CHECK - ~/bash.qndwm/files/app_info.txt
if [[ ! -f "$APP_CONFIG_FILE" ]]; then
    print_message $RED "Error: Application configuration file $APP_CONFIG_FILE not found."
    exit 1
fi

#    FILE EXISTENCE CHECK - ~/bash.qndwm/files/patches.txt
if [[ ! -f "$PATCH_CONFIG_FILE" ]]; then
    print_message $RED "Error: Patch configuration file $PATCH_CONFIG_FILE not found."
    exit 1
fi

#    TOOL SCRIPT
while IFS= read -r line || [[ -n "$line" ]]; do
    APP=$(echo $line | cut -d' ' -f1)
    DESCRIPTION=$(echo $line | cut -d' ' -f2- | rev | cut -d' ' -f2- | rev)
    FROM_HERE=$(echo $line | awk '{print $NF}')
    #     INSTALLS APPLICATION - ~/bash.qndwm/files/app_info.txt
    install_APP "$APP" "$DESCRIPTION" "$FROM_HERE"

    read -p "Do you want to configure $APP? (y/n): " CHOICE2
    if [ "$CHOICE2" = "y" ] || [ "$CHOICE2" = "Y" ]; then
        #    COPIES CONFIG FILES - ~/bash.qndwm/files/configurations
        configure_APP "$APP" "$DESCRIPTION"
    fi

    read -p "Do you want to patch $APP? (y/n): " CHOICE3
    if [ "$CHOICE3" = "y" ] || [ "$CHOICE3" = "Y" ]; then
        #    APPLY PATCHES - ~/bash.qndwm/files/patches.txt
        patch_APP "$APP" "$DESCRIPTION"
    fi

    print_message $GREEN "All tasks for $APP completed."
done < "$APP_CONFIG_FILE"

# Create startup script and update .xinitrc
create_startup_script
update_xinitrc

# Configure SLiM
configure_slim

# Theme GRUB
theme_grub

# Create session file for display manager
create_session_file

print_message $GREEN "All tasks completed."
