# Guide d'installation — fedora-gaming

## 📋 Prérequis

### Matériel minimum
- **CPU** : AMD Ryzen (SVM) ou Intel (VT-x)
- **GPU** : AMD RDNA2+ recommandé (RX 6000/7000)
- **RAM** : 16 GB minimum, 32 GB recommandé
- **Stockage** : 256 GB SSD minimum (512 GB+ recommandé)

### Configuration BIOS
Avant installation, configure le BIOS :

1. **SVM/AMD-V** : ✅ Activé (virtualisation KVM)
2. **Secure Boot** : ✅ ou ❌ (Fedora supporte les deux)
3. **Boot Order** : USB/DVD en premier
4. **CSM/Legacy** : ❌ Désactivé (UEFI pur)
5. **Resizable BAR** : ✅ Activé si disponible

## 💿 Installation Fedora 44 KDE

### 1. Téléchargement ISO
```bash
# Fedora 44 KDE Spin (~2.5 GB)
wget https://download.fedoraproject.org/pub/fedora/linux/releases/44/Spins/x86_64/iso/Fedora-KDE-Live-x86_64-44.iso
```

### 2. Création clé USB

**Windows (Rufus)** :
- Mode : DD Image
- Partition : GPT
- Système : UEFI

**Linux** :
```bash
sudo dd if=Fedora-KDE-Live-x86_64-44.iso of=/dev/sdX bs=4M status=progress
sync
```

### 3. Partitionnement dual-boot

Si Windows existe déjà :
1. Windows → Gestion des disques → Réduire C: de 250 GB minimum
2. Laisser espace non alloué (Fedora utilisera)

**Schéma recommandé** :
```
/dev/nvme0n1p1    512 MB     EFI System (partagé Windows/Linux)
/dev/nvme0n1p2    XXX GB     Windows (NTFS)
/dev/nvme0n1p3    250+ GB    Fedora (Btrfs)
```

### 4. Installation Fedora

1. Boot USB → "Start Fedora-KDE-Live"
2. Double-clic "Install to Hard Drive"
3. **Langue** : Français
4. **Partitionnement personnalisé** :
   - Réutiliser `/dev/nvme0n1p1` comme `/boot/efi` (⚠️ NE PAS FORMATER)
   - Créer `/dev/nvme0n1p3` en **Btrfs**, point de montage `/`
   - **Pas de swap** (inutile avec 32 GB RAM)
5. **Utilisateur** : ton nom (ex: guill)
6. **Mot de passe** : choisis un mot de passe fort
7. Installer → Redémarrer

## 🚀 Post-installation : fedora-gaming

### 1. Cloner le projet
```bash
cd ~/Documents
git clone https://github.com/ghermetz/OS-fedora-gaming fedora-gaming
cd fedora-gaming
```

### 2. Lancer install.sh

**Installation complète (recommandé)** :
```bash
bash install.sh
```

**Mode automatique (sans questions)** :
```bash
ASSUME_YES=1 bash install.sh
```

**Options disponibles** :
```bash
bash install.sh --skip-waydroid   # Sans Android
bash install.sh --skip-winboat    # Sans Windows VM
bash install.sh --skip-desktop    # Sans config KDE
bash install.sh --skip-tiling     # Sans Sway/Niri
bash install.sh --extras          # + OBS, Kdenlive, GIMP
bash install.sh --vanilla         # Waydroid sans Google Apps
```

### 3. Ce qui est installé

| Catégorie | Paquets |
|-----------|---------|
| **Gaming** | Steam, GameMode, MangoHud, Gamescope, LACT |
| **Proton** | ProtonUp-Qt (GE-Proton) |
| **Wine** | Wine 11, Lutris, Heroic, Bottles, Ruffle |
| **Apps** | Vesktop, Edge (Netflix), Jellyfin |
| **Android** | Waydroid + Google Apps + libndk (ARM) |
| **Dev** | VS Code, Distrobox, ZCode, Git |
| **VM** | WinBoat (Docker + Windows 11) |
| **Bureau** | KDE Plasma optimisé gaming |
| **Tiling** | Sway (floating mode) + Niri |

### 4. Configurations manuelles

#### VRR/FreeSync (multi-écrans)
```
Paramètres système → Affichage et moniteur
→ Sélectionner écran PRINCIPAL uniquement
→ Adaptive Sync : "Toujours"
```

⚠️ **Important** : Active VRR UNIQUEMENT sur l'écran de jeu (bug multi-écrans KWin).

#### Souris (accélération plate)
```
Paramètres système → Souris
→ Profil d'accélération : "Aucun (Plat)"
```

#### Gestion énergie
```
Paramètres système → Gestion de l'énergie
→ Profil : "Performance"
```

### 5. Optimisations optionnelles

#### Snapper (snapshots Btrfs)
```bash
bash scripts/setup-snapper.sh
# Rollback système comme openSUSE
```

#### Performance système
```bash
bash scripts/performance-tweaks.sh
# CPU governor, I/O scheduler, VM tuning
```

#### Environnements dev
```bash
bash scripts/setup-dev-env.sh
# Distrobox: Fedora, Ubuntu, Arch
```

### 6. Vérification
```bash
bash doctor.sh
```

Vérifie tous les paquets, services et configurations.

### 7. Premier redémarrage
```bash
sudo reboot
```

Active : groupe docker, drivers AMD, services systemd.

## 🔧 Troubleshooting

### GRUB ne voit pas Windows
```bash
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

### Pas de son
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Steam ne démarre pas
```bash
flatpak run com.valvesoftware.Steam
```

### Waydroid bloqué
```bash
sudo systemctl restart waydroid-container
waydroid session stop && waydroid session start
```

### Drivers AMD non chargés
```bash
sudo modprobe amdgpu
lspci -k | grep -A 3 VGA
```

### NetworkManager inactif
```bash
sudo systemctl enable --now NetworkManager
```

## 📚 Guides complémentaires

- **[GAMING.md](GAMING.md)** — Optimisations jeux (Steam, Proton, MangoHud)
- **[AMD-TUNING.md](AMD-TUNING.md)** — Tuning RX 7600 XT (LACT, overclock)
- **[naruto-online-*.md](naruto-online-bottles.md)** — Naruto Online (3 routes)

## 🎯 Prochaines étapes

1. ✅ Redémarrer
2. ✅ Lancer Steam → installer Proton
3. ✅ Configurer VRR sur écran gaming
4. ✅ Tester un jeu → vérifier MangoHud (Shift droite + F12)
5. ✅ Installer extensions VS Code
6. ✅ Créer snapshots Btrfs réguliers

Bon gaming ! 🎮
