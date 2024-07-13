################################################################### CHANGE .BASHRC
############ .BASHRC

echo -e "${PURPLE} LETS BE FIXING THE BASH! ${NC}"
echo "First lets get the NerdFonts! All of them? ALL OF THEM!"

# Define the font directory
FONT_DIR="$HOME/.local/share/fonts/NerdFonts"

# Create the font directory if it doesn't exist
mkdir -p "$FONT_DIR"

# Define the Nerd Fonts download URL
BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

# Array of all Nerd Fonts
FONTS=(
    "3270.zip"
    "Agave.zip"
    "AnonymousPro.zip"
    "Arimo.zip"
    "AurulentSansMono.zip"
    "BigBlueTerminal.zip"
    "BitstreamVeraSansMono.zip"
    "CascadiaCode.zip"
    "CodeNewRoman.zip"
    "Cousine.zip"
    "DaddyTimeMono.zip"
    "DejaVuSansMono.zip"
    "DroidSansMono.zip"
    "FantasqueSansMono.zip"
    "FiraCode.zip"
    "FiraMono.zip"
    "Go-Mono.zip"
    "Gohu.zip"
    "Hack.zip"
    "Hasklig.zip"
    "HeavyData.zip"
    "Hermit.zip"
    "iA-Writer.zip"
    "IBMPlexMono.zip"
    "Inconsolata.zip"
    "InconsolataGo.zip"
    "InconsolataLGC.zip"
    "Iosevka.zip"
    "JetBrainsMono.zip"
    "Lekton.zip"
    "LiberationMono.zip"
    "Meslo.zip"
    "Monofur.zip"
    "Monoid.zip"
    "Mononoki.zip"
    "MPlus.zip"
    "Noto.zip"
    "OpenDyslexic.zip"
    "Overpass.zip"
    "ProFont.zip"
    "ProggyClean.zip"
    "RobotoMono.zip"
    "ShareTechMono.zip"
    "SourceCodePro.zip"
    "SpaceMono.zip"
    "Terminus.zip"
    "Tinos.zip"
    "Ubuntu.zip"
    "UbuntuMono.zip"
    "VictorMono.zip"
)

# Download, unzip, and install each font
for FONT in "${FONTS[@]}"; do
    echo "Downloading and installing $FONT..."
    wget -q "$BASE_URL/$FONT" -O "/tmp/$FONT"
    unzip -o "/tmp/$FONT" -d "$FONT_DIR"
    rm "/tmp/$FONT"
done

# Download 0xProto fonts
echo "Downloading and installing 0xProto fonts..."
PROTO_URL="https://github.com/0xType/0xProto/archive/refs/heads/main.zip"
wget -q "$PROTO_URL" -O "/tmp/0xProto.zip"
unzip -o "/tmp/0xProto.zip" -d "/tmp"
mv "/tmp/0xProto-main/fonts/"* "$FONT_DIR"
rm -rf "/tmp/0xProto.zip" "/tmp/0xProto-main"

# Refresh the font cache
fc-cache -fv

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
