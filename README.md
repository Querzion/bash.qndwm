# bash.qndwm Naaah! It's QnDWM. 
"QnD Gamesquad" (Quest n Defend|Defeat) is the Discord I have.

  - This is a lazy install script.
That is intended to be post-installed on Arch, after the alternatively use of the "archinstall" script. 
  - There are two old versions of qndwm.sh. 
The one without the *.old is the combined and up to date script.

## That installs (look at the list) in (~/.config/vm/$app).
  - (git) dwm ------------- (Suckless - Dynamic Window Manager)
  - (git) st -------------- (Suckless - Terminal)
  - (git) slstats --------- (Suckless - Status Bar)
  - (git) dmenu ----------- (Suckless - Dynamic Menu)
  - (git) dwmblocks ------- (Dynamic Window Manager - Status Bar)
  - (git) nnn ------------- (Terminal File Manager)
  - (pacman) rofi --------- (Application Launcher)
  - (pacman) feh ---------- (Commandline Wallpaper Handler)
  - (pacman) scrot -------- (Commandline Screenshot Utility)
  - (pacman) slim --------- (Login Manager)
  - (git) nlogout --------- (Logout Applet)

A more detailed list is the actual (~/bash.qndwm/files/packages.txt)
    
## Changes 
  - The .xinitrc file.
  - Creates a bash autorun script. (~/.config/vm/autorun.sh)
  - Creates a session file. (/usr/share/xsessions/dwm-q.desktop) !(SLiM doesn't need it.)
  - The .bashrc file. (Makes a backup and copies over a new one)

## Is able to 
  - Patch the applications
  - Individually (Asks about every single patch though.)
  - Backup the whole $app folder (before a reinstall & after a sucesssful patch)

# Installation (Is simple, thus lazy.)
  - Get yourself an Arch Linux ISO >> https://archlinux.org/download/
  - Get a USB Memory.
  - Get Ventoy >> https://www.ventoy.net/en/download.html
  - Insert your USB Stick.
  - Start Ventoy and Install it on the USB Stick.
  - Two Partitions are now created.
  - One is for GRUB. (Do not touch that partition.)
  - The Second is Empty. Put your Arch Linux ISO in there.
  - Get Yourself a VM Hypervisor >> https://www.qemu.org/ <3 | Guide for QEMU/KVM install (Scroll Down).
  - Create a VM >> https://www.youtube.com/watch?v=jLRmVNWOrgo
  - Boot the Virtual Machine with the ISO... WHY DID I INSTALL VENTOY THEN? (Use the stick on Bare Metal.)
  - The Arch Linux is on the command line now? Write "archinstall". https://averagelinuxuser.com/arch-linux-install-automatically/
  - Choose Grub. . . ;D Cause that will be themed, and skip installing a DE.
  - Set it up as you like it, but in "Additional Packages" write "git". (It's needed!)
    
![image](https://github.com/user-attachments/assets/c4c49299-8520-4bc4-b6d2-94762f309896)
  - I assume you pressed install and you can now login. . . Login.

## Prerequsites 
(That will be installed with the script if they are not already) 
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

A more detailed list is the actual (~/bash.qndwm/files/packages.txt)

### Info
If there are more then one user on the computer and you want everyone to be able to use the same dwm change the install directory to (/usr/src)

# LazyDWM Installation Process
  - Clone the repository. . .
```bash
git clone https://github.com/querzion/bash.qndwm.git
```
  - Chmod the folder. Candy beats teeth otherwise.
```bash
chmod +x -R ~/bash.qndwm/*
```
  - Start the script. . .
OR? Actually, you should read the files, all of them. There's actually two install scripts. . .
  - VERSION ONE (Not Modified Patch Functionality)
```bash
./bash.qndwm/qndwm.sh
```
  - VERSION TWO (Modified Patch Functionality)
```bash
./bash.qndwm/qndwm.modified.sh
```
Everything should now be ready to be used. Reboot your computer or virtual machine. Which ever floats your boat.

_____________________________________________________________________________________________________________________________________

#                                (OPTIONAL)  VIRTUAL MACHINCE - QEMU-KVM
_____________________________________________________________________________________________________________________________________

(https://computingforgeeks.com/install-kvm-qemu-virt-manager-arch-manjar/)
(https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/)
(https://www.youtube.com/watch?v=BUSrdUoedTo)
(https://www.youtube.com/watch?v=3yhwJxWSqXI)


## QEMU/KVM Hypervisor Installation Process 
This part is for the people who are too lazy to install on bare metal. 
- (OPTIONAL STEPS) THIS ONE IS FOR HARDWARE PASSTHROUGH CAPABILITES

The next three are for those that have in mind to pass-through hardware.
```bash
sudo nano /etc/default/grub
```
  - In that case do this in the grub file
```bash
# In GRUB_CMDLIN_LINUX_DEFAULT after quiet add
    iommu=1 amd_iommu=on    # Or intel_iommu=on
```
  - Don't remember what this does, #Important. . ? >> https://www.redhat.com/sysadmin/linux-tools-dmidecode
```bash
sudo pacman -S dmidecode
sudo pacman -Syy
```
  - IF YOU DID THE OPTIONAL STEPS.
```bash
reboot
```
  - Something that QEMU can't abstain from. "/ 
```bash
sudo pacman -S archlinux-keyring
```
  - THE QEMU/KVM INSTALLATION TAKES OFF!

These files are the actual application, and in order to use it later on, just search for virt-manager. ;D
```bash
sudo pacman -S -y qemu libvirt virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat libguestfs edk2-ovmf vfio
```
  - Needed for Network something. . . 
```bash
sudo pacman -S -y ebtables iptables
```
  - Time to start the QEMU services.
```bash
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
sudo systemctl enable virtlogd.socket
sudo systemctl start virtlogd.socket
sudo virsh net-autostart default
sudo virsh net-start default
```
  - Open Sesame. ^^ 
```bash
sudo nano /etc/libvirt/libvirtd.conf
```
  - Uncomment these two in the libvirtd.conf file
```bash
# Set the UNIX domain socket group ownership to libvirt, (around line 85)
    unix_sock_group = "libvirt"
# Set the UNIX socket permissions for the R/W socket (around line 102)
    unix_sock_rw_perms = "0770"
```
  - Almost done. Create the Libvirt group, and become a member of it. 

I wrote this guide for myself, since there were always a file or package missing in others guides or something not working at the end.
```bash
sudo usermod -a -G libvirt $(whoami)
newgrp libvirt
```
  - Restart libvirtd service for changes to take place. 
```bash
sudo systemctl restart libvirtd.service
```
  - Preload vfio
```bash
sudo nano /etc/mkinitcpio.conf
```
  - Add or Change this segment in mkinitcpio.conf.
```bash
MODULES=(vfio_pci vfio vfio_iommu_type1 vfio_virqfd)
```
  - DONE! Restart the Computer. A reboot changes a lot! 
```bash
reboot
```
_____________________________________________________________________________________________________________________________________
###
##                            (OPTIONAL) CPU PINNING (https://youtu.be/WYrTajuYhCk?t=725)
_____________________________________________________________________________________________________________________________________

lscpu -e    # See the CPU cores


PASSTHROUGH GPU - (https://www.youtube.com/watch?v=BUSrdUoedTo | https://www.youtube.com/watch?v=WYrTajuYhCk | https://www.youtube.com/watch?v=3yhwJxWSqXI)
sudo pacman -S tree


https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/
https://github.com/joeknock90/Single-GPU-Passthrough
https://www.reddit.com/r/VFIO/

PATCHED BIOS
https://www.techpowerup.com/vgabios/192500/asus-rx580-8192-170328



_____________________________________________________________________________________________________________________________________
###
#                               (OPTIONAL) VIRTUAL MACHINE MANAGER - VIRTUALBOX (INSTEAD OF QEMU/KVM)
_____________________________________________________________________________________________________________________________________

## Virtual Box Installation. . . I'm not going to put any energy into this. . . 

(https://linuxhint.com/install-virtualbox-arch-linux/)

sudo pacman -Syu
sudo pacman -S virtualbox
choose 2 and enter
sudo modprobe vboxdrv
virtualbox  Start and Exit
sudo nano /etc/modules-load.d/virtualbox.conf - Create the file!
    vboxdrv # Save & Exit
sudo usermod -aG vboxusers querzion
sudo lsmod | grep vboxdrv

 - VirtualBox 6.1.28 Oracle VM VirtualBox Extension Pack (https://www.virtualbox.org/wiki/Downloads)
    All supported platforms # Download to your ~/ folder
virtualbox
  - Open VirtualBox >> Preferences & Extensions >> Choose the Extension file and install it.
