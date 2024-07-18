################################################################### CHANGE .BASHRC
############ .BASHRC

echo -e "${PURPLE} LETS BE FIXING THE BASH! ${NC}"
echo "First lets get the NerdFonts! All of them? ALL OF THEM!"

# My NerdFont+ Font Installer Script Repo
git clone https://github.com/Querzion/bash.fonts.git $HOME
chmod +x -r $HOME/bash.fonts
sh $HOME/bash.fonts/installer.sh

# Starship.rc changes the commandline look in Bash
echo -e "${PURPLE} NOW LETS SPRUCE THE BASH UP! STARSHIP! HERE I COME ${NC}"
curl -sS https://starship.rs/install.sh | sh

echo -e "${PURPLE} NOW ACTIVATE! . . . WELL! A REBOOT IS IN NEED HERE, LETS FIX THE REST FIRST! ${NC}"

# Create .bashrc file in the home directory with specific content
echo "Creating .bashrc file in the home directory..."

mv ~/.bashrc ~/.bashrc.bak
cp $BASHRC_FILE ~/

echo -e "${GREEN} .bashrc file created successfully. ${NC}"
