#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — install.sh
#  Bootstrap post-installation pour Fedora KDE Plasma Edition (44+)
#
#  Installe et configure :
#    • RPM Fusion (free/nonfree) + ffmpeg + codecs
#    • Stack gaming : Steam, GameMode, MangoHud, Gamescope, LACT, GE-Proton
#    • Wine & launchers : wine, winetricks, Lutris, Heroic, Bottles
#    • Applications : Vesktop, Netflix (Edge en mode appli), Jellyfin
#    • Waydroid (Android) + image GAPPS + traduction ARM libndk (AMD)
#    • Dev & burô : VS Code, Distrobox, RetroArch, LibreOffice, Thunderbird
#    • WinBoat : Docker CE + FreeRDP + rpm officiel
#    • Bureau : look KDE + réglages gaming (desktop/setup-desktop.sh)
#
#  Usage :
#    bash install.sh                  # parcours complet
#    ASSUME_YES=1 bash install.sh     # sans questions
#    bash install.sh --vanilla        # Waydroid sans Google Apps
#    bash install.sh --skip-waydroid  # sans la partie Android
#    bash install.sh --skip-winboat   # sans WinBoat
#    bash install.sh --skip-desktop   # sans la personnalisation du bureau
#    bash install.sh --extras         # + OBS, Kdenlive, GIMP, VLC, qBittorrent
# ============================================================================
set -euo pipefail

ASSUME_YES="${ASSUME_YES:-0}"
WAYDROID_FLAVOR="GAPPS"
SKIP_WAYDROID=0
WITH_EXTRAS=0
SKIP_WINBOAT=0
SKIP_DESKTOP=0
SKIP_TILING=0

for arg in "$@"; do
  case "$arg" in
    --vanilla)       WAYDROID_FLAVOR="VANILLA" ;;
    --skip-waydroid) SKIP_WAYDROID=1 ;;
    --extras)        WITH_EXTRAS=1 ;;
    --skip-winboat)  SKIP_WINBOAT=1 ;;
    --skip-desktop)  SKIP_DESKTOP=1 ;;
    --skip-tiling)   SKIP_TILING=1 ;;
    *) echo "Option inconnue : $arg (voir l'en-tête du script)" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fedora-gaming"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
ask() {
  if [ "$ASSUME_YES" = "1" ]; then return 0; fi
  local r
  read -r -p "$1 [y/N] " r
  [ "${r,,}" = "y" ] || [ "${r,,}" = "oui" ]
}

# ---------------------------------------------------------------- préambule
if [ "$(id -u)" -eq 0 ]; then
  echo "Ne lance pas ce script en root : il utilise sudo au besoin." >&2
  exit 1
fi
# shellcheck disable=SC1091
. /etc/os-release
if [ "${ID:-}" != "fedora" ]; then
  warn "Ce script est prévu pour Fedora (détecté : ${ID:-inconnu})."
  if ! ask "Continuer quand même ?"; then exit 1; fi
fi
log "fedora-gaming — installation sur ${PRETTY_NAME:-Fedora}"
if ! ask "On lance le parcours complet ?"; then exit 0; fi

# Installe les paquets manquants uniquement (rpm -q = test d' présence)
dnf_install() {
  local missing=() p
  for p in "$@"; do
    rpm -q "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if [ "${#missing[@]}" -eq 0 ]; then return 0; fi
  sudo dnf install -y "${missing[@]}"
}

flat_install() {
  local app
  for app in "$@"; do
    if ! flatpak info "$app" >/dev/null 2>&1; then
      sudo flatpak install --system --or-update -y flathub "$app"
    fi
  done
}

mkdir -p "$SRC_DIR"

# ------------------------------------------------------------ 1. socle
log "1/8 — Mise à jour et dépôts"
sudo dnf upgrade -y --refresh

if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
  sudo dnf install -y --nogpgcheck \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
fi
if ! rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
  sudo dnf install -y --nogpgcheck \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
fi
echo "    RPM Fusion activé."
# Métadonnées d'apps (RPM Fusion visible dans Discover) + sous-dépôts tainted
# (codecs et bibliothèques complémentaires) — méthode Linuxtricks/RPM Fusion.
dnf_install rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data
dnf_install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted

if ! rpm -q ffmpeg >/dev/null 2>&1; then
  sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
fi
sudo dnf group install -y multimedia 2>/dev/null || sudo dnf group install -y "Multimedia" 2>/dev/null || \
  warn "Groupe multimédia non installé (non bloquant : ffmpeg est là)."

dnf_install flatpak git curl wget unzip tar cabextract
# Francisation : langpacks applicatifs (Firefox/Thunderbird embarquent déjà
# toutes les langues ; LibreOffice a un paquet dédié)
dnf_install langpacks-fr hunspell-fr man-pages-fr libreoffice-langpack-fr
sudo flatpak remote-add --system --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now bluetooth 2>/dev/null || true

# ---------------------------------------------------------- 2. drivers AMD
log "2/8 — Drivers AMD / Vulkan (RX 7600 XT — inclus au noyau, on vérifie)"
# F44 : les pilotes VA-API sont fusionnés dans mesa-dri-drivers (plus de mesa-va-drivers)
if ! sudo dnf install -y mesa-dri-drivers mesa-vulkan-drivers vulkan-tools vulkan-mesa-layers libva-utils 2>/dev/null; then
  warn "Certains paquets drivers introuvables — Fedora renomme parfois ; vérifie avec dnf search mesa"
fi
if have vulkaninfo; then
  echo "Périphérique Vulkan détecté :"
  vulkaninfo --summary 2>/dev/null | grep -E 'deviceName|driverName' | sed 's/^/   /' || true
fi

# ---------------------------------------------------------- 3. stack gaming
log "3/8 — Stack gaming"
dnf_install steam gamemode mangohud gamescope
if ! rpm -q lact >/dev/null 2>&1; then
  sudo dnf copr enable -y ilyaz/LACT
  sudo dnf install -y lact
fi
sudo systemctl enable --now lactd 2>/dev/null || true
flat_install net.davidotek.pupgui2
mkdir -p "$HOME/.config/MangoHud"
cp "$SCRIPT_DIR/config/mangohud/MangoHud.conf" "$HOME/.config/MangoHud/MangoHud.conf"

# ---------------------------------------------------------- 4. wine & launchers
log "4/8 — Wine 11 (dépôts Fedora), Lutris, Heroic, Bottles"
# Fedora 44+ livre Wine 11.0 directement — inutile de passer par le dépôt
# WineHQ, dont les paquets entrent en conflit avec winetricks (wine-common).
dnf_install wine winetricks cabextract lutris
if rpm -q wine >/dev/null 2>&1; then
  echo "    Wine : $(rpm -q --qf '%{NAME} %{VERSION}' wine)"
fi
flat_install com.heroicgameslauncher.hgl
flat_install com.usebottles.bottles
flat_install rs.ruffle.Ruffle   # Flash moderne (Naruto Online et jeux web flash)

# ---------------------------------------------------------- 5. applications
log "5/8 — Applications du quotidien"
flat_install dev.vencord.Vesktop

if ! rpm -q microsoft-edge-stable >/dev/null 2>&1; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  printf '[microsoft-edge]\nname=microsoft-edge\nbaseurl=https://packages.microsoft.com/yumrepos/edge\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
    | sudo tee /etc/yum.repos.d/microsoft-edge.repo >/dev/null
  sudo dnf install -y microsoft-edge-stable
fi

flat_install org.jellyfin.JellyfinDesktop   # Jellyfin Media Player (id Flathub actuel)

# Raccourci « Netflix » en mode application
ICON_DIR="$HOME/.local/share/icons"
APPS_DIR="$HOME/.local/share/applications"
mkdir -p "$ICON_DIR" "$APPS_DIR"
cp "$SCRIPT_DIR/config/netflix/netflix.svg" "$ICON_DIR/netflix.svg"
cat > "$APPS_DIR/netflix.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Netflix
GenericName=Client de streaming
Comment=Netflix en mode application (Edge, Widevine — 1080p max sur Linux)
Exec=/usr/bin/microsoft-edge-stable --no-first-run --profile-directory=Default --app=https://www.netflix.com
Icon=$ICON_DIR/netflix.svg
Terminal=false
Categories=Network;AudioVideo;Video;
StartupNotify=true
EOF
echo "Raccourci Netflix créé : $APPS_DIR/netflix.desktop"

# ---------------------------------------------------------- 6. Waydroid
log "6/8 — Waydroid (Android)"
if [ "$SKIP_WAYDROID" = "1" ]; then
  warn "Waydroid sauté (--skip-waydroid)"
else
  # Waydroid est dans les dépôts officiels Fedora depuis F44 — pas de script externe
  # (l'ancien repo.waydro.id ne gère plus que Debian/Ubuntu).
  dnf_install waydroid
  sudo systemctl enable --now waydroid-container

  if [ ! -d /var/lib/waydroid ]; then
    if ask "Télécharger l'image Android ($WAYDROID_FLAVOR, ≈1 Go) maintenant ?"; then
      sudo waydroid init -s "$WAYDROID_FLAVOR"
    else
      warn "Image non téléchargée : lance plus tard → sudo waydroid init -s $WAYDROID_FLAVOR"
    fi
  fi

  if ask "Installer la traduction ARM libndk (recommandée sur CPU AMD) ?"; then
    sudo systemctl stop waydroid-container 2>/dev/null || true
    if [ ! -d "$SRC_DIR/waydroid_script" ]; then
      git clone --depth=1 https://github.com/casualsnek/waydroid_script "$SRC_DIR/waydroid_script"
    fi
    (
      cd "$SRC_DIR/waydroid_script"
      if [ ! -d venv ]; then python3 -m venv venv; fi
      ./venv/bin/pip install -q -r requirements.txt
      sudo ./venv/bin/python main.py install libndk
    ) || warn "waydroid_script a échoué — réessaie plus tard (README §5)."
    sudo systemctl start waydroid-container 2>/dev/null || true
  fi
fi

# ---------------------------------------------------------- 7. dev & burô & rétro
log "7/8 — Bureautique, dev & rétrogaming"
dnf_install distrobox retroarch libreoffice thunderbird

if ! rpm -q code >/dev/null 2>&1; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  printf '[vscode]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
    | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
  sudo dnf install -y code
fi

# ZCode (agent de dev Z.ai) — rpm officiel, version résolue depuis la page d'install
if ! rpm -q zcode >/dev/null 2>&1; then
  zver="$(curl -sL --max-time 20 https://zcode.z.ai/en/docs/install \
    | grep -oE 'ZCode-[0-9]+\.[0-9]+\.[0-9]+-linux-x64' | head -1 \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)"
  if [ -n "${zver:-}" ]; then
    zurl="https://cdn-zcode.z.ai/zcode/electron/releases/${zver}/linux-x64/ZCode-${zver}-linux-x64.rpm"
    if curl -fsIL --max-time 15 "$zurl" >/dev/null 2>&1; then
      curl -sL -o "$SRC_DIR/zcode-${zver}.rpm" "$zurl" \
        && sudo dnf install -y "$SRC_DIR/zcode-${zver}.rpm" \
        || warn "Installation du rpm ZCode échouée — vois https://zcode.z.ai/en/docs/install"
    else
      warn "rpm ZCode v${zver} introuvable sur le CDN — vois https://zcode.z.ai/en/docs/install"
    fi
  else
    warn "Version ZCode introuvable — installe-le depuis https://zcode.z.ai/en/docs/install"
  fi
fi

if [ "$WITH_EXTRAS" = "1" ]; then
  echo "    + extras médias (--extras)"
  dnf_install obs-studio kdenlive gimp vlc qbittorrent
fi

# ---------------------------------------------------------- 8. WinBoat
if [ "$SKIP_WINBOAT" = "1" ]; then
  log "8/8 — WinBoat : sauté (--skip-winboat)"
else
  log "8/8 — WinBoat (vraies applis Windows : Docker + KVM + FreeRDP)"
  if ! lsmod 2>/dev/null | grep -q 'kvm_amd\|kvm'; then
    warn "KVM semble inactif : active SVM (virtualisation) dans le BIOS pour WinBoat."
  fi
  dnf_install freerdp
  if ! rpm -q docker-ce >/dev/null 2>&1; then
    dnf_install dnf-plugins-core
    # dnf5 (F41+) : verbe « addrepo » — repli sur l'ancienne syntaxe dnf4
    if ! sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null; then
      sudo dnf config-manager --add-repo=https://download.docker.com/linux/fedora/docker-ce.repo
    fi
    sudo dnf install -y docker-ce docker-ce-cli containerd docker-buildx-plugin docker-compose-plugin
  fi
  sudo systemctl enable --now docker.service
  if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    warn "Ajouté au groupe docker — effectif après déconnexion/reconnexion."
  fi

  if ! rpm -q winboat >/dev/null 2>&1; then
    rpm_url="$(curl -s https://api.github.com/repos/winboat-org/winboat/releases/latest \
      | grep -oE '"browser_download_url": *"[^"]*\.rpm"' | head -1 | cut -d'"' -f4)"
    if [ -n "${rpm_url:-}" ]; then
      curl -L -o "$SRC_DIR/winboat.rpm" "$rpm_url"
      sudo dnf install -y "$SRC_DIR/winboat.rpm" \
        || warn "Installation du rpm WinBoat échouée (bug connu #284) — vois README §6."
    else
      warn "rpm WinBoat introuvable via l'API GitHub — télécharge-le depuis github.com/winboat-org/winboat/releases"
    fi
  fi
fi

# ---------------------------------------------------------- bureau + récap
if [ "$SKIP_DESKTOP" = "0" ]; then
  log "Bureau — look KDE + réglages gaming"
  if ! bash "$SCRIPT_DIR/desktop/setup-desktop.sh"; then
    warn "Setup bureau en échec — relance plus tard : bash desktop/setup-desktop.sh"
  fi
else
  log "Bureau : sauté (--skip-desktop)"
fi

# ---------------------------------------------------------- sessions tiling
if [ "$SKIP_TILING" = "0" ]; then
  log "Sessions tiling bonus — Sway (mode Windows) + Niri (tiling défilant)"
  if ! bash "$SCRIPT_DIR/desktop/setup-tiling.sh"; then
    warn "Setup tiling en échec — relance plus tard : bash desktop/setup-tiling.sh"
  fi
else
  log "Sessions tiling : sautées (--skip-tiling)"
fi

cat <<'EOT'

  Prochaines étapes manuelles
  ───────────────────────────
  1. Redémarre le PC (groupe docker + drivers pleinement actifs).
  2. Steam : Options de lancement par jeu → gamemoderun mangohud %command%
     (HUD MangoHud : Maj droite + F12)
  3. FreeSync/VRR multi-écrans + souris « plate » : suis les notes du setup
     bureau (Paramètres système → Écran et moniteur → Adaptive Sync
     « Toujours » sur l'écran PRINCIPAL uniquement).
  4. Netflix / Jellyfin / Vesktop : connecte-toi à la première ouverture
     (Netflix : 1080p max sous Linux).
  5. Waydroid : lance « Waydroid », configure Android (applis ARM après libndk).
  6. Jeux hors Steam : Heroic (Epic/GOG), Lutris, Bottles. Rétro : RetroArch.
  7. WinBoat : assistant au premier lancement — licence Windows requise,
     conteneur à télécharger (~25 Go), SVM/KVM actif dans le BIOS.
  8. Rythme des mises à jour : sudo dnf upgrade une fois par semaine ou par
     mois — c'est toi qui décides. Montée de version tous les 6 mois max.
  9. Diagnostic complet à tout moment : bash doctor.sh
EOT

bash "$SCRIPT_DIR/doctor.sh" || true
