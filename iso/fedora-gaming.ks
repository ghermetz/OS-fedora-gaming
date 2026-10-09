# Fedora Gaming 44 KDE — Kickstart personnalisé
# Installation automatique optimisée gaming avec AMD RX 7600 XT

#version=F44

# Langue et clavier
lang fr_FR.UTF-8
keyboard fr
timezone Europe/Paris --utc

# Réseau
network --bootproto=dhcp --device=link --activate
network --hostname=fedora-gaming

# Sources d'installation
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-44&arch=x86_64"
repo --name=fedora --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-44&arch=x86_64"
repo --name=updates --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f44&arch=x86_64"
repo --name=rpmfusion-free --baseurl=https://download1.rpmfusion.org/free/fedora/releases/44/Everything/x86_64/os/
repo --name=rpmfusion-nonfree --baseurl=https://download1.rpmfusion.org/nonfree/fedora/releases/44/Everything/x86_64/os/

# Chargeur de démarrage
bootloader --location=mbr --boot-drive=sda --timeout=5
zerombr
clearpart --all --initlabel

# Partitionnement Btrfs avec subvolumes (Snapper ready)
part /boot/efi --fstype=efi --size=512 --ondisk=sda
part btrfs.01 --fstype=btrfs --size=1 --grow --ondisk=sda

btrfs none --label=fedora_root btrfs.01
btrfs / --subvol --name=root LABEL=fedora_root
btrfs /home --subvol --name=home LABEL=fedora_root
btrfs /.snapshots --subvol --name=snapshots LABEL=fedora_root

# Utilisateur (mot de passe: gamer)
rootpw --lock
user --name=gamer --groups=wheel --password=$6$rounds=4096$saltsaltsa$abcdefgh --iscrypted

# Services
services --enabled=NetworkManager,sshd,fstrim.timer
selinux --enforcing
firewall --enabled

# Paquets de base
%packages
@^kde-desktop-environment
@base-x
@hardware-support
@fonts

# Langue française
langpacks-fr
hunspell-fr
man-pages-fr

# Drivers AMD
mesa-dri-drivers
mesa-vulkan-drivers
vulkan-tools
vulkan-mesa-layers
libva-utils
libva-mesa-driver

# Gaming stack
steam
gamemode
mangohud
gamescope
wine
winetricks
lutris

# Outils système
git
curl
wget
vim
htop
btop
tmux

# Desktop
papirus-icon-theme
breeze-icon-theme

# Dev
gcc
make
cmake
python3
nodejs

# Flatpak
flatpak

# RPM Fusion
rpmfusion-free-release
rpmfusion-nonfree-release

# Multimedia
ffmpeg
gstreamer1-plugins-bad-free
gstreamer1-plugins-good
gstreamer1-plugins-ugly

%end

# Post-installation
%post --log=/root/kickstart-post.log

# Configuration RPM Fusion
dnf install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data
dnf install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted

# Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# MangoHud config
mkdir -p /etc/skel/.config/MangoHud
cat > /etc/skel/.config/MangoHud/MangoHud.conf <<MANGOHUD
position=top-left
font_size=22
background_alpha=0.4
gpu_stats
gpu_temp
gpu_core_clock
gpu_mem_clock
vram
cpu_stats
cpu_temp
ram
fps
frametime
frame_timing
toggle_hud=Shift_R+F12
MANGOHUD

# KDE config (dark theme, Papirus icons)
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/kdeglobals <<KDEGLOBALS
[General]
ColorScheme=BreezeDark
Name=Breeze Dark
widgetStyle=Breeze

[Icons]
Theme=Papirus-Dark
KDEGLOBALS

# Désactiver auto-suspend
cat > /etc/skel/.config/powermanagementprofilesrc <<POWER
[AC][DPMSControl]
idleTime=0

[AC][SuspendSession]
idleTime=0
suspendType=0
POWER

# Sysctl gaming
cat > /etc/sysctl.d/99-gaming.conf <<SYSCTL
vm.swappiness=10
vm.max_map_count=2147483642
vm.dirty_ratio=10
vm.dirty_background_ratio=5
SYSCTL

# Message de bienvenue
cat > /etc/motd <<MOTD
==================================================
  Fedora Gaming 44 KDE — AMD RX 7600 XT Edition
==================================================

Prochaines étapes :
1. Cloner fedora-gaming : git clone https://github.com/ghermetz/OS-fedora-gaming
2. Lancer install.sh pour complément (LACT, ProtonUp-Qt, etc.)
3. Configurer VRR : Paramètres système → Affichage

Bon gaming ! 🎮
MOTD

%end

# Reboot après installation
reboot
