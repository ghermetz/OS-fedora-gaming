# Naruto Online — Route 2 : Bottles + Wine (Software Rendering)

## 📖 Vue d'ensemble

**Méthode** : Wine + Bottles + rendu logiciel forcé  
**Compatibilité** : ⭐⭐⭐⭐ Bonne (fix écran noir CEF)  
**Performances** : ⭐⭐⭐ Correctes (software rendering)  
**Difficulté** : ⭐⭐ Moyenne

## 🐛 Problème connu : Écran noir CEF

**Symptôme** : La fenêtre du launcher s'ouvre mais reste NOIRE.  
**Cause** : Le processus GPU de Chromium Embedded Framework (CEF) plante sous Wine.  
**Solution** : Forcer le rendu logiciel (désactiver D3D11/DXGI + LIBGL_ALWAYS_SOFTWARE).

## ✅ Avantages
- ✅ Fonctionne bien après config
- ✅ Performances acceptables
- ✅ Pas besoin de VM lourde
- ✅ Préfix Wine isolé

## ❌ Inconvénients
- ❌ Setup initial complexe
- ❌ dotnet452 long à installer (~10 min)
- ❌ Rendu logiciel = performances réduites

## 🚀 Installation

### Prérequis
```bash
# Déjà installé via install.sh
flatpak info com.usebottles.bottles
rpm -q wine winetricks
```

### Manuel
```bash
sudo flatpak install -y flathub com.usebottles.bottles
sudo dnf install -y wine winetricks
```

## 📦 Setup automatique

### Étape 1 : Préparer la bouteille
```bash
cd ~/Documents/fedora-gaming
./apps/naruto-online.sh setup /chemin/vers/dossier_jeu
```

**Dossier jeu** : Le dossier contenant `Naruto Online.exe` (launcher).

### Ce que fait le script
1. Crée une bouteille "Naruto Online" (environnement application)
2. Télécharge un Wine runner (Soda/Caffe/Kronk)
3. Installe `dotnet452` via winetricks (~10 min)
4. Enregistre le launcher comme programme

### Étape 2 : Lancer le jeu
```bash
./apps/naruto-online.sh run
```

## 🛠️ Setup manuel (si script échoue)

### 1. Créer la bouteille
```bash
bottles-cli new --bottle-name "Naruto Online" --environment application
```

### 2. Installer Wine runner
```
Bottles → Préférences → Runners
→ Télécharger: Soda-8.x ou Caffe-8.x
```

### 3. Installer dotnet452
```bash
WINEPREFIX="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/Naruto Online" \
WINE="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-8.0-3/bin/wine" \
winetricks -q dotnet452
```

### 4. Ajouter le launcher
```bash
bottles-cli add -b "Naruto Online" \
  -n "Naruto Online" \
  -p "/chemin/vers/Naruto Online.exe"
```

### 5. Lancer avec fix écran noir
```bash
flatpak run \
  --env=WINEDLLOVERRIDES="d3d11,dxgi=d" \
  --env=LIBGL_ALWAYS_SOFTWARE=1 \
  --command=bottles-cli com.usebottles.bottles \
  run -b "Naruto Online" -p "Naruto Online"
```

## 🔧 Variables d'environnement critiques

### WINEDLLOVERRIDES="d3d11,dxgi=d"
Désactive D3D11 et DXGI (= désactive GPU pour CEF).

### LIBGL_ALWAYS_SOFTWARE=1
Force Mesa à utiliser le rendu logiciel (llvmpipe) au lieu du GPU.

**Résultat** : CEF tourne en software, pas de crash GPU, jeu fonctionne.

## 📝 Vérification

### Bouteille créée ?
```bash
bottles-cli list --bottles | grep "Naruto Online"
```

### dotnet452 installé ?
```bash
ls -la "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/Naruto Online/drive_c/windows/system32/mscoree.dll"
```

### Logs Wine
```bash
WINEDEBUG=+all flatpak run --command=bottles-cli com.usebottles.bottles \
  run -b "Naruto Online" -p "Naruto Online" 2>&1 | tee wine.log
```

## 🔍 Troubleshooting

### dotnet452 échoue
```bash
# Réessayer avec winetricks interactif
WINEPREFIX="..." WINE="..." winetricks dotnet452
```

### Écran noir persiste
```bash
# Vérifier override
flatpak run --env=WINEDEBUG=+d3d11,+dxgi --env=WINEDLLOVERRIDES="d3d11,dxgi=d" ...
```

### Performance trop faible
Passe à **Route 3 (WinBoat)** pour performance native.

### Launcher ne trouve pas .NET
```bash
# Réinstaller .NET Framework
winetricks dotnet40 dotnet452
```

## 🎮 Performances attendues

| Aspect | Note |
|--------|------|
| FPS | 30-60 (software rendering) |
| Latency | Faible |
| Stabilité | ⭐⭐⭐⭐ |
| Qualité | ⭐⭐⭐ (software) |

## 💡 Astuces

### Garder le dossier jeu hors cloud
```
~/Games/NarutoOnline/  ✅
~/Nextcloud/Games/     ❌ (verrouillage fichiers)
```

### Sauvegardes
Les sauvegardes sont serveur-side (pas de backup local nécessaire).

## 🔄 Alternatives

- **Route 1** : [Ruffle](naruto-online-ruffle.md) (plus simple, moins fiable)
- **Route 3** : [WinBoat](naruto-online-winboat.md) (performances natives, lourd)

## 📊 Verdict

**Recommandé pour** : Compromis performance/complexité  
**Éviter si** : Tu veux perf max ou setup simple  
**Note** : ⭐⭐⭐⭐ / 5
