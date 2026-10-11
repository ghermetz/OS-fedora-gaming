#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — desktop/setup-tiling.sh
#  Session bonus Niri, légère et réglée pour être simple, façon Windows :
#  barre des tâches waybar (Démarrer, vue des tâches, fenêtres ouvertes,
#  zone de notification, volume, aide, extinction, heure), Alt+Tab avec
#  aperçus, fenêtres ouvertes en grand, raccourcis Windows, aide en français.
#  FG_IMAGE_BUILD=1 : construction de l'ISO — paquets fournis par KIWI, et
#  HOME=/etc/skel pour que chaque nouveau compte reçoive les configurations.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TILING_DIR="$SCRIPT_DIR/tiling"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

if [ "${FG_IMAGE_BUILD:-0}" != "1" ]; then
  log "Installation des composants (Niri, waybar, outils)…"
  sudo dnf install -y niri waybar fuzzel mako wlogout \
    swaybg swaylock swayidle grim slurp wl-clipboard \
    xwayland-satellite network-manager-applet pavucontrol kdialog \
    xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
    polkit-kde qt6-qtwayland qt5-qtwayland fontawesome-6-free-fonts \
    google-noto-emoji-fonts
fi

log "Déploiement des configurations…"
mkdir -p "$HOME/.config/niri" "$HOME/.config/waybar" "$HOME/.config/wlogout" \
  "$HOME/.config/fuzzel" "$HOME/.config/fedora-gaming" "$HOME/Images/Captures"
cp "$TILING_DIR/niri-config.kdl" "$HOME/.config/niri/config.kdl"   # niri lit config.kdl
cp "$TILING_DIR/waybar.jsonc"    "$HOME/.config/waybar/config.jsonc"
cp "$TILING_DIR/waybar.css"      "$HOME/.config/waybar/style.css"
cp "$TILING_DIR/wlogout-layout"  "$HOME/.config/wlogout/layout"
cp "$TILING_DIR/wlogout.css"     "$HOME/.config/wlogout/style.css"
cp "$TILING_DIR/fuzzel.ini"      "$HOME/.config/fuzzel/fuzzel.ini"
install -m 755 "$TILING_DIR/aide-tiling.sh" "$HOME/.config/fedora-gaming/aide-tiling.sh"
# Restes d'anciennes versions (session Sway retirée, mauvais nom de config niri)
rm -f "$HOME/.config/niri/config.kcl" "$HOME/.config/fedora-gaming/aide-sway.txt"

# Niri lance les programmes de démarrage automatique du système : on y masque
# les outils propres à KDE/au bureau complet, inutiles ou gênants hors Plasma
# (fenêtre noire du pont XWayland, alertes de plantage, IBus…).
# Copie utilisateur + NotShowIn=niri : Plasma n'est pas affecté.
log "Démarrage automatique de Niri allégé…"
mkdir -p "$HOME/.config/autostart"
for app in org.kde.xwaylandvideobridge org.kde.kalendarac org.kde.kdeconnect.daemon \
           org.mageia.dnfdragora-updater org.kde.discover.notifier geoclue-demo-agent \
           org.freedesktop.problems.applet sealertauto imsettings-start; do
  src="/etc/xdg/autostart/$app.desktop"
  dst="$HOME/.config/autostart/$app.desktop"
  [ -f "$src" ] || continue
  grep -q '^NotShowIn=.*niri' "$dst" 2>/dev/null && continue
  cp "$src" "$dst"
  if grep -q '^NotShowIn=' "$dst"; then
    sed -i 's/^NotShowIn=\(.*\)$/NotShowIn=\1;niri;/; s/;;/;/g' "$dst"
  else
    echo 'NotShowIn=niri;' >> "$dst"
  fi
done

cat <<'EOT'

  Session « Niri » disponible à l'écran de connexion (en bas à gauche).
  Comme sous Windows (Super = touche Windows) :
    Bouton ⊞ Démarrer ou Super+Espace : applications
    Bouton ⧉ ou Super+Tab : vue des tâches (toutes les fenêtres, bureaux)
    Alt+Tab : passer d'une fenêtre à l'autre (avec aperçus)
    Alt+F4 fermer · Super+E fichiers · Super+I paramètres · Super+L verrouiller
    Super+↑ agrandir · Super+↓ moitié d'écran · Ctrl+Super+←/→ bureaux
    Super+Maj+S capture · Ctrl+Alt+Suppr éteindre · Super+F1 ou « ? » : aide
EOT
log "Session Niri configurée."
