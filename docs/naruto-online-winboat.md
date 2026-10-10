# Naruto Online — Route 3 : WinBoat (Windows 11 VM)

## 📖 Vue d'ensemble

**Méthode** : VM Windows 11 native via Docker + KVM + FreeRDP  
**Compatibilité** : ⭐⭐⭐⭐⭐ Parfaite (100%)  
**Performances** : ⭐⭐⭐⭐⭐ Natives (KVM)  
**Difficulté** : ⭐⭐⭐ Avancée

## ✅ Avantages
- ✅ Compatibilité garantie 100%
- ✅ Performances natives (KVM passthrough)
- ✅ Pas de bugs Wine/Proton
- ✅ Vrai Windows, vrais drivers
- ✅ Partage de fichiers facile

## ❌ Inconvénients
- ❌ Lourd (~8 GB téléchargement Windows)
- ❌ Disque 60 GB minimum
- ❌ RAM 8 GB dédiée
- ❌ Licence Windows requise (long terme)
- ❌ Setup initial complexe

## 🚀 Installation

### Prérequis
```bash
# Déjà installé via install.sh
rpm -q winboat docker-ce freerdp
systemctl status docker
```

### Vérifier KVM actif
```bash
lsmod | grep kvm
# Doit montrer: kvm_amd ou kvm_intel

# Si absent → activer SVM dans BIOS
```

## 📦 Créer le conteneur Windows 11

### Méthode automatique (script)
```bash
cd ~/Documents/fedora-gaming
./apps/naruto-online-winboat.sh create
```

**Ce qui se passe** :
1. Téléchargement Windows 11 ISO (~6-8 GB)
2. Installation automatique (~20 min)
3. Configuration RDP
4. Dossier partagé : `~/Games/NarutoOnline-Shared`

### Méthode manuelle
```bash
# Créer conteneur
winboat create naruto-online-win11 \
  --os windows11 \
  --cpu 4 \
  --memory 8192 \
  --disk 60

# Vérifier
docker ps -a | grep naruto-online-win11
```

## 🎮 Utilisation

### Démarrer Windows + RDP
```bash
./apps/naruto-online-winboat.sh start
```

Une fenêtre FreeRDP s'ouvre avec Windows 11.

### Installer le jeu dans Windows
1. Dans Windows : ouvrir `Z:\` (dossier partagé)
2. Copier le dossier "Naruto Online" depuis Linux vers Windows
3. Installer launcher : double-clic `Naruto Online.exe`
4. Jouer normalement

### Arrêter Windows
```bash
./apps/naruto-online-winboat.sh stop
```

### Supprimer le conteneur
```bash
./apps/naruto-online-winboat.sh destroy
```

## 🔧 Configuration optimale

### Allocation ressources
```
CPU    : 4 cœurs (environ la moitié d'un processeur 8 cœurs)
RAM    : 8 GB (25% des 32 GB)
Disque : 60 GB (Windows + jeu)
GPU    : Software (ou passthrough si configuré)
```

### Dossier partagé
```bash
# Linux → Windows
~/Games/NarutoOnline-Shared  →  Z:\

# Place tes fichiers jeu dans ce dossier
cp -r "/chemin/Naruto Online" ~/Games/NarutoOnline-Shared/
```

## 🌐 Accès réseau

### RDP (Remote Desktop)
```bash
# IP conteneur
docker inspect naruto-online-win11 | grep IPAddress

# Connexion manuelle
xfreerdp /v:<IP> /u:WinBoat /cert:ignore /dynamic-resolution
```

### Partage dossier via RDP
```bash
xfreerdp /v:<IP> /u:WinBoat /cert:ignore \
  /drive:shared,~/Games/NarutoOnline-Shared
```

## 📊 Performances

| Aspect | Note |
|--------|------|
| FPS | 60+ (natif Windows) |
| Latency | Minimale |
| Stabilité | ⭐⭐⭐⭐⭐ |
| Qualité | ⭐⭐⭐⭐⭐ (natif) |

## 🔍 Troubleshooting

### KVM non disponible
```bash
# Vérifier BIOS
sudo dmesg | grep -i kvm

# Activer module
sudo modprobe kvm_amd  # ou kvm_intel
```

### Docker non accessible
```bash
# Ajouter user au groupe docker
sudo usermod -aG docker $USER

# Relancer session
sudo reboot
```

### WinBoat ne démarre pas
```bash
# Logs
sudo journalctl -u docker -n 50

# Restart Docker
sudo systemctl restart docker
```

### RDP écran noir
```bash
# Attendre 30s après start
sleep 30

# Vérifier conteneur running
docker ps | grep naruto-online-win11
```

### Performance faible
```bash
# Augmenter CPU/RAM
winboat modify naruto-online-win11 --cpu 6 --memory 12288
```

## 💾 Gestion des données

### Sauvegardes
```bash
# Snapshot conteneur
docker commit naruto-online-win11 naruto-backup:latest

# Restaurer
docker run -d --name naruto-online-win11-restored naruto-backup:latest
```

### Espace disque
```bash
# Taille conteneur
docker ps -s | grep naruto

# Nettoyer images inutilisées
docker system prune -a
```

## 🎯 Workflow recommandé

### 1. Installation initiale
```bash
# Une seule fois
./apps/naruto-online-winboat.sh create
```

### 2. Session de jeu
```bash
# Démarrer
./apps/naruto-online-winboat.sh start

# Jouer dans Windows
# ...

# Arrêter proprement
./apps/naruto-online-winboat.sh stop
```

### 3. Maintenance
```bash
# Vérifier état
./apps/naruto-online-winboat.sh status

# Backup (optionnel)
docker commit naruto-online-win11 naruto-backup:$(date +%Y%m%d)
```

## 📜 Licence Windows

### Activation
Windows 11 nécessite une licence après 30 jours d'essai.

**Options** :
1. Clé Windows 11 Home/Pro (achat)
2. Réutiliser clé Windows 10 (upgrade gratuit)
3. Mode évaluation (reset périodique)

### Sans licence
Le système fonctionne mais avec :
- Watermark "Activate Windows"
- Personnalisation limitée
- Rappels d'activation

## 🔄 Alternatives

- **Route principale** : [launcher officiel sous Wine](naruto-online.md) (validée en VM)

## 📊 Verdict

**Recommandé pour** : Garantie 100% compatibilité  
**Éviter si** : Peu d'espace disque/RAM  
**Note** : ⭐⭐⭐⭐⭐ / 5 (meilleure compatibilité)

## 💡 Bonus : GPU Passthrough

Pour performances GPU natives, configure VFIO passthrough (avancé).
Guide : https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
