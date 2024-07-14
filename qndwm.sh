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
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


############################### SETTINGS

# User Name (Automagic Entry)
USER="$(whoami)"
# Path to the app_info.txt file
APP_CONFIG_FILE="$LOCATION/app_info.txt"
# Path to the patches.txt file
PATCH_CONFIG_FILE="$LOCATION/patches.txt"
# Path to the fonts.txt file
FONT_FILE="$LOCATION/fonts.txt"

# Name of DWM Version
SESSION_NAME="QnDWM"
# Session File Name
SESSION_FILE_NAME="qndwm.session"
# Run Script
QnDWM_FILE="run.qndwm.sh"


################################################################### FILE & FOLDER PATHS

# Script Folder
FOLDER="$HOME/bash.qndwm"
# Script Folder Path
LOCATION="$FOLDER/files"
# Installation Path
INSTALL_LOCATION="$HOME/.config/wm"
# Directory to save backups 
BACKUP_DIR="$INSTALL_LOCATION/backups"
# Critical font
CRITICAL_FONT_NAME="Nerd Fonts Symbols Only"
CRITICAL_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/NerdFontsSymbolsOnly.zip"
# Directory to install fonts
FONT_DIR="$HOME/.local/share/fonts"


######################################################################################################### TERMINAL PROMT FUNCTION (COLOUR MESSAGES)
################################ TERMINAL PROMT FUNCTION (FOR MORE COMPACT COLOUR CODE MESSAGES) (FIX THE DUPLICATE PROBLEM AND COMBINE THEM)

# Function to print messages with color (assuming colors are globally defined)
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NO_COLOR}"
}
print_message() {
    color=$1
    message=$2
    echo -e "${color}${message}${NC}"
}


######################################################################################################### PACMAN INSTALLATION SCRIPT
################################ PACMAN INSTALLATION SCRIPT (INSTALLS FROM PACKAGES.TXT)

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


######################################################################################################### QnDWM BACKUP FUNCTION
################################ QnDWM BACKUP FUNCTION (IN CASE OF REINSTALLATIONS)

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


######################################################################################################### QnD INSTALLATION FUNCTION
################################ QnDWM INSTALLATION FUNCTION

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


######################################################################################################### QnDWM CONFIGURATION FUNCTION
################################ QnDWM CONFIGURATION FUNCTION

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


######################################################################################################### QnDWM PATCH FUNCTION
################################ QnDWM PATCH FUNCTION

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


######################################################################################################### QnDWM MAIN FUNCTION
################################ QnDWM MAIN FUNCTION

install_and_patch_apps() {
    # Check if the application configuration file exists
    if [[ ! -f "$APP_CONFIG_FILE" ]]; then
        print_message $RED "Error: Application configuration file $APP_CONFIG_FILE not found."
        exit 1
    fi

    # Check if the patch configuration file exists
    if [[ ! -f "$PATCH_CONFIG_FILE" ]]; then
        print_message $RED "Error: Patch configuration file $PATCH_CONFIG_FILE not found."
        exit 1
    fi

    # Prompt the user to decide whether to apply patches
    read -p "Do you want to apply patches? (y/n): " apply_all_patches
    if [[ "$apply_all_patches" =~ ^[yY]$ ]]; then
        # Read the application configuration file line by line
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Extract application name, description, and an additional field from each line
            APP=$(echo $line | cut -d' ' -f1)
            DESCRIPTION=$(echo $line | cut -d' ' -f2- | rev | cut -d' ' -f2- | rev)
            FROM_HERE=$(echo $line | awk '{print $NF}')

            # Install the application using the extracted information
            install_APP "$APP" "$DESCRIPTION" "$FROM_HERE"

            # Prompt the user to decide whether to install patches for this application
            read -p "Do you want to install patches for $APP $DESCRIPTION? (y/n): " install_patches
            if [[ "$install_patches" =~ ^[yY]$ ]]; then
                # Ask if the user wants to apply all patches for the application
                read -p "Do you want to apply all patches for $APP $DESCRIPTION? (y/n): " apply_all
                if [[ "$apply_all" =~ ^[yY]$ ]]; then
                    # Apply all patches for the application
                    apply_patches "$APP" "$DESCRIPTION"
                else
                    # Read the patch configuration file line by line
                    while IFS= read -r patch_line || [[ -n "$patch_line" ]]; do
                        # Extract patch information from each line
                        patch_app=$(echo $patch_line | cut -d' ' -f1)
                        patch_url=$(echo $patch_line | awk '{print $2}')
                        patch_description=$(echo $patch_line | cut -d' ' -f3-)

                        # If the patch is for the current application, prompt to apply the patch
                        if [[ "$patch_app" == "$APP" ]]; then
                            read -p "Do you want to apply patch $patch_description? (y/n): " apply_patch
                            if [[ "$apply_patch" =~ ^[yY]$ ]]; then
                                # Download and apply the patch
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

            # Configure the application after processing patches
            configure_APP "$APP" "$DESCRIPTION"

        done < "$APP_CONFIG_FILE"
    fi
}


######################################################################################################### QnDWM RUN SCRIPT CREATION
################################ QnDWM RUN SCRIPT CREATION

create_startup_script() {
    STARTUP_SCRIPT="$INSTALL_LOCATION/$QnDWM_FILE"
    
    if [[ ! -f $STARTUP_SCRIPT ]]; then
        echo "#!/bin/bash" > $STARTUP_SCRIPT
        echo "/usr/bin/pipewire &" >> $STARTUP_SCRIPT
        echo "/usr/bin/pipewire-pulse &" >> $STARTUP_SCRIPT
        echo "/usr/bin/pipewire-media-session &" >> $STARTUP_SCRIPT
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


######################################################################################################### XINITRC CONFIGURATION
################################ XINITRC CONFIGURATION

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


######################################################################################################### FONT INSTALLATION ('UN-DETAILED')
################################ FONT INSTALLATION ('UN-DETAILED')

# Function to handle all operations
install_fonts() {
  read -p "${CYAN}Do you want to download fonts? (y/n) ${NC}" download_fonts
  if [[ $download_fonts =~ ^[nN]$ ]]; then
    echo -e "${PURPLE}Installing critical font: $CRITICAL_FONT_NAME${NC}"
    wget -q "$CRITICAL_FONT_URL" -O /tmp/font.zip
    mkdir -p "$FONT_DIR"
    unzip -qo /tmp/font.zip -d "$FONT_DIR"
    fc-cache -f -v
    exit 0
  fi

  read -p "${CYAN}Do you want to download all fonts? (y/n) ${NC}" download_all
  while IFS= read -r line; do
    [[ $line =~ ^#.*$ ]] && continue
    # This part handles the spaces between the name and the link. 
    # This is restricted to only one space between name and link sections in the fonts.txt file.
    #name=$(echo $line | cut -d '"' -f2)
    #url=$(echo $line | cut -d '"' -f4)
    # This is not restricted to how big the space is between the section name and link is in the fonts.txt.
    name=$(echo $line | awk '{for(i=1;i<NF;i++) printf $i " "; print $NF}')
    url=$(echo $line | awk '{print $NF}')

    if [[ $download_all =~ ^[yY]$ ]] || { read -p "${PURPLE}Install $name? (y/n) ${NC}" answer && [[ $answer =~ ^[yY]$ ]]; }; then
      echo -e "${GREEN}Installing $name...${NC}"
      wget -q "$url" -O /tmp/font.zip
      mkdir -p "$FONT_DIR"
      unzip -qo /tmp/font.zip -d "$FONT_DIR"
      fc-cache -f -v
      echo -e "${GREEN}$name installed.${NC}"
    else
      echo -e "${RED}Skipping $name.${NC}"
    fi
  done < "$FONT_FILE"

  # Ensure the critical font is installed
  echo -e "${PURPLE}Ensuring the critical font is installed: $CRITICAL_FONT_NAME${NC}"
  wget -q "$CRITICAL_FONT_URL" -O /tmp/font.zip
  unzip -qo /tmp/font.zip -d "$FONT_DIR"
  fc-cache -f -v
}


######################################################################################################### FONT INSTALLATION (DETAILED)
################################ FONT INSTALLATION (DETAILED)

# Count the number of font packages
font_count=$(grep -v '^#' "$FONT_FILE" | wc -l)

# Function to handle all operations
install_fonts_detailed() {
  read -p "${CYAN}Do you want to install fonts to your system? (y/n) ${NC}" install_fonts
  if [[ $install_fonts =~ ^[nN]$ ]]; then
    echo -e "${PURPLE}Installing critical font: $CRITICAL_FONT_NAME${NC}"
    wget -q "$CRITICAL_FONT_URL" -O /tmp/font.zip
    mkdir -p "$FONT_DIR"
    unzip -qo /tmp/font.zip -d "$FONT_DIR"
    echo -e "Extracted files:"
    unzip -l /tmp/font.zip | awk '{print $2}' | tail -n +4 | head -n -2
    fc-cache -f -v
    exit 0
  fi

  read -p "${CYAN}Do you want to install all $font_count font packages? (y/n) ${NC}" download_all
  if [[ $download_all =~ ^[yY]$ ]]; then
    while IFS= read -r line; do
      [[ $line =~ ^#.*$ ]] && continue
      name=$(echo $line | awk '{for(i=1;i<NF;i++) printf $i " "; print $NF}')
      url=$(echo $line | awk '{print $NF}')

      echo -e "${CYAN}Installing $name...${NC}"
      wget -q "$url" -O /tmp/font.zip
      mkdir -p "$FONT_DIR"
      unzip -qo /tmp/font.zip -d "$FONT_DIR"
      echo -e "Extracted files:"
      unzip -l /tmp/font.zip | awk '{print $2}' | tail -n +4 | head -n -2
      fc-cache -f -v
      echo -e "${GREEN}$name installed.${NC}"
    done < "$FONT_FILE"
  else
    while IFS= read -r line; do
      [[ $line =~ ^#.*$ ]] && continue
      name=$(echo $line | awk '{for(i=1;i<NF;i++) printf $i " "; print $NF}')
      url=$(echo $line | awk '{print $NF}')

      read -p "${PURPLE}Do you want to install the $name font? (y/n) ${NC}" answer
      if [[ $answer =~ ^[yY]$ ]]; then
        echo -e "${CYAN}Installing $name...${NC}"
        wget -q "$url" -O /tmp/font.zip
        mkdir -p "$FONT_DIR"
        unzip -qo /tmp/font.zip -d "$FONT_DIR"
        echo -e "Extracted files:"
        unzip -l /tmp/font.zip | awk '{print $2}' | tail -n +4 | head -n -2
        fc-cache -f -v
        echo -e "${GREEN}$name installed.${NC}"
      else
        echo -e "${RED}Skipping $name.${NC}"
      fi
    done < "$FONT_FILE"
  fi

  # Ensure the critical font is installed
  echo -e "${PURPLE}Ensuring the critical font is installed: $CRITICAL_FONT_NAME${NC}"
  wget -q "$CRITICAL_FONT_URL" -O /tmp/font.zip
  unzip -qo /tmp/font.zip -d "$FONT_DIR"
  echo -e "Extracted files:"
  unzip -l /tmp/font.zip | awk '{print $2}' | tail -n +4 | head -n -2
  fc-cache -f -v
}


######################################################################################################### BASHRC CONFIGURATIONS
################################ BASHRC CONFIGURATIONS

fix_bashrc() {
    # Define colors
    PURPLE='\033[0;35m'
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color

    echo -e "${PURPLE} LETS BE FIXING THE BASH! ${NC}"
    echo "First lets get the NerdFonts! All of them? ALL OF THEM!"

    install_fonts
    #install_fonts_detailed

    echo -e "${GREEN} All Nerd Fonts installed successfully! ${NC}"

    # Starship.rc changes the commandline look in Bash
    echo -e "${PURPLE} NOW LETS SPRUCE THE BASH UP! STARSHIP! HERE I COME ${NC}"
    curl -sS https://starship.rs/install.sh | sh

    echo -e "${PURPLE} NOW ACTIVATE! . . . WELL! A REBOOT IS IN NEED HERE, LETS FIX THE REST FIRST! ${NC}"

    # Create .bashrc file in the home directory with specific content
    echo "Creating .bashrc file in the home directory..."

    mv ~/.bashrc ~/.bashrc.bak
    cp $BASHRC_FILE ~/

    echo -e "${GREEN} .bashrc file created successfully. ${NC}"
}


######################################################################################################### GRUB THEME INSTALL (NOT DONE - FIX THIS)
################################ GRUB THEME INSTALL (NOT DONE - NO THEME IS BEING INSTALLED)

theme_grub() {
    # Define GRUB configuration and theme paths
    GRUB_CONFIG="/etc/default/grub"
    GRUB_THEME_FOLDER="/boot/grub/themes/"
    INSTALL_GRUB_THEME="$GRUB_THEME_FOLDER/$GRUB_THEME"
    GRUB_THEME_TXT="$GRUB_THEME/theme.txt"
    GRUB_THEME="arch"
    
    # Backup existing GRUB config
    sudo cp $GRUB_CONFIG ${GRUB_CONFIG}.bak
    print_message $PURPLE "Backup of $GRUB_CONFIG created."

    # Update GRUB configuration for the theme
    echo "GRUB_THEME=\"${INSTALL_GRUB_THEME}\"" | sudo tee -a $GRUB_CONFIG

    # Update GRUB
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    print_message $GREEN "GRUB configured and updated."
}


######################################################################################################### CREATE SESSION FILE
################################ CREATE SESSION FILE

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


######################################################################################################### MAIN LOGIC
################################ MAIN LOGIC

# UPDATE SYSTEM (YOU NEVER KNOW)
sudo pacman -Syyu -y

# INSTALLS WHAT'S ADDED TO - ../packages.txt
prerequisites

# INSTALLS PACKAGES FROM - ../app_info.txt & PATCHES THEM FROM - ../patches.txt
install_and_patch_apps

# Create startup script and update .xinitrc
create_startup_script
update_xinitrc

# Configure SLiM
configure_slim

# Theme GRUB
theme_grub

# Create session file for display manager 
# (Even though SLiM does not use this, it's good to have if SDDM or some other login manager is present.)
create_session_file

print_message $GREEN "All tasks completed."
