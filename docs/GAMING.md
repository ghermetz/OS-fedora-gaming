# Guide Gaming — fedora-gaming

## 🎮 Steam

### Configuration Proton
```bash
Steam → Paramètres → Compatibilité
→ ☑ Activer Steam Play pour tous les titres
→ Sélectionner : Proton Experimental
```

### GE-Proton (communautaire amélioré)
Via **ProtonUp-Qt** :
1. Ouvrir ProtonUp-Qt
2. Add version → GE-Proton (dernière)
3. Redémarrer Steam
4. Jeu → Propriétés → Compatibilité → GE-Proton

### Options de lancement

**Basique** :
```bash
gamemoderun mangohud %command%
```

**Avec Gamescope (upscaling FSR)** :
```bash
gamemoderun gamescope -w 1920 -h 1080 -W 2560 -H 1440 -U -- mangohud %command%
```

**VRR/FreeSync unlock** :
```bash
gamemoderun mangohud DXVK_FRAME_RATE=0 %command%
```

### Variables d'environnement AMD

```bash
# Mesa RADV optimisations
RADV_PERFTEST=aco,nggc
AMD_VULKAN_ICD=RADV
MESA_VK_WSI_PRESENT_MODE=mailbox

# DXVK
DXVK_HUD=fps,gpuload
DXVK_ASYNC=1  # ⚠️ Risque ban anti-cheat

# Proton
PROTON_LOG=1  # Debug logs
```

## 🔥 GameMode

### Activation automatique
Ajoute `gamemoderun` dans Steam launch options :
```bash
gamemoderun %command%
```

### Ce que fait GameMode
- CPU governor → performance
- GPU governor → performance  
- I/O priority élevée
- Nice value réduite

### Vérifier si actif
```bash
gamemoded -s
```

### Config personnalisée
`~/.config/gamemode.ini` :
```ini
[general]
renice=10

[gpu]
apply_gpu_optimisations=accept_responsibility
amd_performance_level=high

[custom]
start=notify-send "GameMode ON"
end=notify-send "GameMode OFF"
```

## 📊 MangoHud

### Raccourcis
- **Toggle HUD** : `Shift Droit + F12`
- **Reposition** : `Shift Droit + F11`

### Configuration
`~/.config/MangoHud/MangoHud.conf` :
```ini
position=top-left
font_size=22
background_alpha=0.4

gpu_stats
gpu_temp
gpu_core_clock
vram
cpu_stats
cpu_temp
ram
fps
frametime
frame_timing

fps_limit=0
vsync=0
```

### Modes inline
```bash
# FPS uniquement
MANGOHUD_CONFIG=fps ./jeu

# Custom
MANGOHUD_CONFIG=fps,gpu_temp,cpu_temp ./jeu
```

## 🖼️ Gamescope

### Upscaling FSR
```bash
# 1080p → 1440p
gamescope -w 1920 -h 1080 -W 2560 -H 1440 -U -f -- ./jeu
```

### Limite FPS
```bash
gamescope -W 2560 -H 1440 -r 144 -f -- ./jeu
```

### VRR unlock
```bash
gamescope -W 2560 -H 1440 -r 165 -o 165 -f -- ./jeu
```

### Flags importants
```
-w/-h    Résolution interne (rendu)
-W/-H    Résolution output (écran)
-r       Refresh rate
-o       Refresh unlocked
-U       FSR upscaling
-f       Fullscreen
-b       Borderless
```

## 🎯 Heroic Games Launcher

### Installation Wine-GE
```
Settings → Wine Manager → Download: Wine-GE-Latest
```

### Config par jeu
```
Game → Settings → Wine Version → Wine-GE
Game → Settings → Advanced → Env variables
```

### Préfixes
Chaque jeu = prefix isolé :
```
~/.var/app/com.heroicgameslauncher.hgl/config/heroic/Prefixes/<jeu>/
```

## 🍷 Lutris

### Installer Wine-GE
```
Runners → Wine → ⬇ → wine-ge-latest
```

### Ajouter jeu manuel
```
+ → Add locally installed game
→ Runner: Wine
→ Executable: /chemin/jeu.exe
```

## 🍾 Bottles

### Créer bouteille
```bash
bottles-cli new --bottle-name "MonJeu" --environment gaming
bottles-cli add -b "MonJeu" -n "Jeu" -p /chemin/jeu.exe
bottles-cli run -b "MonJeu" -p "Jeu"
```

### Dépendances courantes
```
vcredist2019
dotnet48
dxvk
vkd3d
```

## 🎮 VRR / FreeSync

### Configuration KDE
```
Paramètres système → Affichage et moniteur
→ Écran PRINCIPAL uniquement
→ Adaptive Sync : "Toujours"
```

⚠️ Multi-écrans : VRR sur écran gaming UNIQUEMENT.

### Vérifier VRR
```bash
kscreen-doctor -o | grep -i vrr
```

### In-game
- Désactive V-Sync
- Désactive limite FPS
- VRR s'adapte (40-144 Hz)

## 📈 Monitoring

### LACT (GPU AMD)
```bash
sudo systemctl start lactd
lact gui
# Web UI: http://localhost:5000
```

Métriques : temp, fréquence, VRAM, power, fan.

### MangoHud VRAM
```ini
# MangoHud.conf
vram
```

### btop
```bash
btop  # Interface TUI complète
```

## 🔧 Troubleshooting

### Jeu ne démarre pas
```bash
PROTON_LOG=1 %command%
# Logs: /tmp/proton_<user>/
```

### Crashes / freezes
```bash
# Augmenter file descriptors
ulimit -n 524288

# esync limits
echo "DefaultLimitNOFILE=524288" | sudo tee -a /etc/systemd/system.conf
sudo systemctl daemon-reexec
```

### Performances faibles
```bash
# Vérifier CPU governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Force performance AMD GPU
echo "performance" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level
```

### Écran noir
```bash
PROTON_NO_FSYNC=1 PROTON_NO_ESYNC=1 %command%
```

### Audio crackling
```bash
pw-metadata -n settings 0 clock.force-quantum 2048
systemctl --user restart pipewire
```

## 🏆 Jeux testés (Radeon RDNA 3)

| Jeu | Launcher | Statut | Notes |
|-----|----------|--------|-------|
| Cyberpunk 2077 | Steam | ✅ Natif | FSR 2.1, RT OK |
| Elden Ring | Steam | ✅ Proton | EAC supporté |
| GTA V | Steam | ✅ Proton | - |
| CS2 | Steam | ✅ Natif | - |
| Baldur's Gate 3 | Steam | ✅ Natif | Vulkan |
| Forza Horizon 5 | Heroic | ✅ Proton | - |

✅ = Parfait | ⚠️ = Tweaks requis | ❌ = Non fonctionnel
