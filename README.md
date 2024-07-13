# bash.lazy-dwm
This is a lazy install script. 

## That installs (look at the list) in (~/.config/vm/$app).
  - (git) dwm ---------- (Suckless - Dynamic Window Manager)
  - (git) st ------------- (Suckless - Terminal)
  - (git) slstats --------- (Suckless - Status Bar)
  - (git) dmenu -------- (Suckless - Dynamic Menu)
  - (git) dwmblocks ---- (Dynamic Window Manager - Status Bar)
  - (git) nnn ---------- (Terminal File Manager)
  - (pacman) rofi --------- (Application Launcher)
  - (pacman) feh ---------- (Commandline Wallpaper Handler)
  - (pacman) scrot -------- (Commandline Screenshot Utility)
    
## Changes 
  - The .xinitrc file.
  - Creates a bash autorun script. (~/.config/vm/autorun.sh)
  - Creates a session file. (/usr/share/xsessions/dwm-q.desktop)
  - The .bashrc file. (Makes a backup and copies over a new one)

## Is able to 
  - Patch the applications
  - Individually (Asks about every single patch though.)
  - Backup the whole $app folder (before a reinstall & after a sucesssful patch)

# Prerequsites that are installed if not already (Arch (Pacman) Specific) 
  - xorg
  - xorg-xinit
  - xorg-server
  - xorg-xsetroot
  - terminus-font
  - base-devel
  - libx11
  - libxft
  - imlib2
  - libbsd
  - libxcomposite
  - libxext
  - libxfixes
  - libxinerama
  - autoconf-archive

### Info
If there are more then one user on the computer and you want everyone to be able to use the same dwm change the install directory to (/usr/src)
