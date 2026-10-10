# Guide de réglage AMD (Radeon RDNA)

## 🎯 Vue d'ensemble

**Exemple utilisé dans ce guide** : une Radeon RDNA 3 (série RX 7000) ; les réglages s'appliquent aux cartes RDNA en général.  
**Architecture** : RDNA3  
**TDP** : 190W stock  
**Drivers** : Mesa RADV (natif Linux)

## 🔧 LACT (Linux AMDGPU Control)

### Installation
```bash
# Déjà installé via install.sh
sudo systemctl enable --now lactd
```

### Interface Web
```bash
lact gui
# Ouvre http://localhost:5000
```

### Métriques disponibles
- Température GPU / Hotspot / Memory
- Fréquence Core / Memory (MHz)
- VRAM utilisée / totale
- Power draw (W) / TDP limit
- Fan speed (RPM / %)
- Voltage

## ⚡ Overclock Safe

### Profil conservateur (+5% perf)
```
Performance → Power Cap: 200W (+10W)
Performance → Core Clock: +50 MHz
Performance → Memory Clock: +100 MHz
Fan → Courbe custom: 40% idle, 70% gaming
```

### Profil agressif (+10% perf)
```
Power Cap: 210W (+20W)
Core Clock: +100 MHz
Memory Clock: +200 MHz
Fan: 45% idle, 80% gaming
```

⚠️ **Test stabilité** : Superposition benchmark 30min, surveiller hotspot < 95°C.

### Courbe fan recommandée
```
Temp (°C)  →  Fan (%)
30         →  30
40         →  35
50         →  45
60         →  55
70         →  70
80         →  85
90         →  100
```

## 🌡️ Températures normales

| Zone | Idle | Gaming | Max sûr |
|------|------|--------|---------|
| GPU | 35-45°C | 65-75°C | 85°C |
| Hotspot | 45-55°C | 80-90°C | 110°C |
| Memory | 40-50°C | 60-70°C | 95°C |

## 🚀 Variables Mesa (RADV)

### .bashrc / .zshrc
```bash
# Optimisations RADV
export RADV_PERFTEST=aco,nggc,sam
export AMD_VULKAN_ICD=RADV
export MESA_VK_WSI_PRESENT_MODE=mailbox

# Shader cache
export MESA_SHADER_CACHE_DIR="$HOME/.cache/mesa_shader_cache"
export MESA_DISK_CACHE_SINGLE_FILE=true
```

### Flags détaillés
```bash
# ACO : compilateur shader rapide
RADV_PERFTEST=aco

# NGGC : geometry culling (RDNA2+)
RADV_PERFTEST=nggc

# SAM : Smart Access Memory (si activé BIOS)
RADV_PERFTEST=sam

# Tout en un
RADV_PERFTEST=aco,nggc,sam,rt

# Force RADV (vs AMDVLK)
AMD_VULKAN_ICD=RADV

# VRR latency
MESA_VK_WSI_PRESENT_MODE=mailbox
```

## 📊 VRR Multi-écrans

### Configuration KDE (critique)
```
Paramètres système → Affichage et moniteur
→ Sélectionner écran GAMING uniquement
→ Adaptive Sync : "Toujours"
```

### Vérifier VRR actif
```bash
# Wayland (KDE)
kscreen-doctor -o | grep -i vrr

# Xorg
xrandr --verbose | grep -i vrr
```

### Profil multi-écrans
1. **Écran 1 (gaming)** : VRR ON, 1440p@144Hz
2. **Écran 2 (productivité)** : VRR OFF, 1080p@60Hz

⚠️ Bug KWin : activer VRR sur les deux écrans cause flickering.

## 🎮 VRAM Monitoring

### MangoHud
```ini
# ~/.config/MangoHud/MangoHud.conf
vram
gpu_mem_clock
```

### CLI
```bash
# VRAM utilisée (MB)
cat /sys/class/drm/card0/device/mem_info_vram_used

# VRAM totale (MB)
cat /sys/class/drm/card0/device/mem_info_vram_total

# Calcul %
echo "scale=2; $(cat /sys/class/drm/card0/device/mem_info_vram_used) * 100 / $(cat /sys/class/drm/card0/device/mem_info_vram_total)" | bc
```

### radeontop
```bash
sudo dnf install -y radeontop
sudo radeontop
```

## ⚙️ Power Profiles

### Modes disponibles
```bash
# Lister profiles
cat /sys/class/drm/card0/device/pp_power_profile_mode

# Force high performance
echo "1" | sudo tee /sys/class/drm/card0/device/pp_power_profile_mode

# Retour auto
echo "0" | sudo tee /sys/class/drm/card0/device/pp_power_profile_mode
```

### Persistent (udev)
```bash
# /etc/udev/rules.d/30-amdgpu-pm.rules
ACTION=="add", SUBSYSTEM=="pci", DRIVER=="amdgpu", ATTR{power_dpm_force_performance_level}="high"
```

## 🔍 Diagnostic

### Infos GPU
```bash
# Modèle et driver
lspci -k | grep -A 3 VGA

# Vulkan capabilities
vulkaninfo --summary

# Mesa version
glxinfo | grep "OpenGL version"

# RADV features
vulkaninfo | grep -i radv
```

### Fréquences actuelles
```bash
# Core clock
cat /sys/class/drm/card0/device/pp_dpm_sclk

# Memory clock
cat /sys/class/drm/card0/device/pp_dpm_mclk

# Power draw
cat /sys/class/drm/card0/device/hwmon/hwmon*/power1_average
```

### Température live
```bash
watch -n 1 'cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input | awk "{print \$1/1000 \" °C\"}"'
```

## 🛠️ Troubleshooting

### GPU non détecté
```bash
sudo modprobe amdgpu
dmesg | grep amdgpu
```

### Performances faibles
```bash
# Force performance mode
echo "performance" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level

# Vérifier throttling
cat /sys/class/drm/card0/device/gpu_busy_percent
```

### LACT ne démarre pas
```bash
sudo systemctl status lactd
sudo journalctl -u lactd -n 50
```

### Ventilateurs bloqués 100%
```bash
# Reset fan control
echo "2" | sudo tee /sys/class/drm/card0/device/hwmon/hwmon*/pwm1_enable
```

## 📈 Benchmarks

### Superposition
```bash
# Flathub
flatpak install flathub com.unigine.Superposition
flatpak run com.unigine.Superposition
```

### glmark2
```bash
sudo dnf install -y glmark2
glmark2 --fullscreen
```

### vkmark
```bash
sudo dnf install -y vkmark
vkmark --fullscreen
```

## 🎯 Profils recommandés

### Gaming (performance max)
```
LACT:
  Power Cap: 200W
  Core: +50 MHz
  Memory: +100 MHz
  Fan: 70% max

Env:
  RADV_PERFTEST=aco,nggc,sam
  AMD_VULKAN_ICD=RADV
```

### Silence (quotidien)
```
LACT:
  Power Cap: 170W (-20W)
  Core: stock
  Memory: stock
  Fan: 40% max

Mode: auto
```

### Extreme (stress test)
```
LACT:
  Power Cap: 220W (+30W)
  Core: +100 MHz
  Memory: +250 MHz
  Fan: 100%

⚠️ Surveiller hotspot < 100°C
```

Bon tuning ! 🚀
