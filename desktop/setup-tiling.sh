#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — desktop/setup-tiling.sh
#  Session bonus Niri, légère et réglée pour être simple, façon Windows /
#  Zorin OS : barre des tâches waybar (menu Démarrer façon Mint/Zorin, vue des
#  tâches, applis épinglées, fenêtres ouvertes, perfs, GameMode, mises à jour,
#  zone de notification, volume, heure et calendrier, notifications, « Afficher
#  le bureau »), centre de notifications, Alt+Tab avec aperçus, fenêtres
#  ouvertes en grand, raccourcis Windows (Super+D, Super+V, Super+X…), aide en
#  français, accent bleu et fond d'écran façon Zorin OS.
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
    google-noto-emoji-fonts SwayNotificationCenter cliphist wlsunset \
    rsms-inter-fonts papirus-icon-theme jq playerctl gamemode \
    gtk-layer-shell python3-gobject xrandr
fi

SUDO=sudo; [ "$(id -u)" -eq 0 ] && SUDO=
log "Fond d'écran façon Zorin OS…"
$SUDO install -D -m 644 "$TILING_DIR/fond-zorin-bleu.jpg" \
  /usr/share/backgrounds/fedora-gaming/fond-zorin-bleu.jpg

log "Déploiement des configurations…"
mkdir -p "$HOME/.config/niri" "$HOME/.config/waybar" "$HOME/.config/wlogout" \
  "$HOME/.config/fuzzel" "$HOME/.config/fedora-gaming" "$HOME/Images/Captures" \
  "$HOME/.config/mako" "$HOME/.config/swaync" "$HOME/.config/swaylock"
cp "$TILING_DIR/niri-config.kdl" "$HOME/.config/niri/config.kdl"   # niri lit config.kdl
cp "$TILING_DIR/waybar.jsonc"    "$HOME/.config/waybar/config.jsonc"
cp "$TILING_DIR/waybar-modules.jsonc" "$HOME/.config/waybar/modules.jsonc"
cp "$TILING_DIR/waybar.css"      "$HOME/.config/waybar/style.css"
cp "$TILING_DIR/mako.conf"       "$HOME/.config/mako/config"
cp "$TILING_DIR/swaync-config.json" "$HOME/.config/swaync/config.json"
cp "$TILING_DIR/swaync.css"      "$HOME/.config/swaync/style.css"
cp "$TILING_DIR/swaylock.conf"   "$HOME/.config/swaylock/config"
cp "$TILING_DIR/wlogout-layout"  "$HOME/.config/wlogout/layout"
cp "$TILING_DIR/wlogout.css"     "$HOME/.config/wlogout/style.css"
cp "$TILING_DIR/fuzzel.ini"      "$HOME/.config/fuzzel/fuzzel.ini"
install -m 755 "$TILING_DIR/aide-tiling.sh" "$HOME/.config/fedora-gaming/aide-tiling.sh"
# Scripts de la barre et des raccourcis (menu Démarrer, Afficher le bureau,
# volume, presse-papiers, perfs, écran principal des jeux…)
for f in bureau volume menu-windows presse-papiers lancer perf mises-a-jour \
         gamemode nuit ecran-principal ecran-principal-veille; do
  install -m 755 "$TILING_DIR/$f.sh" "$HOME/.config/fedora-gaming/$f.sh"
done
install -m 755 "$TILING_DIR/menu-demarrer.py" "$HOME/.config/fedora-gaming/menu-demarrer.py"
# mako est aussi un service D-Bus de notifications : à l'ouverture de Plasma,
# il peut être lancé avant celui de KDE et échouer (unité « failed »), voire
# prendre la place des notifications Plasma. On le réserve aux sessions hors KDE.
mkdir -p "$HOME/.config/systemd/user/mako.service.d"
printf '[Unit]\nConditionEnvironment=!XDG_CURRENT_DESKTOP=KDE\n' \
  > "$HOME/.config/systemd/user/mako.service.d/hors-plasma.conf"
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
    Bouton Démarrer ou Super+Espace : menu (clic droit / Super+X : menu rapide)
    Bouton ⊞ ou Super+Tab : vue des tâches (toutes les fenêtres, bureaux)
    Alt+Tab : passer d'une fenêtre à l'autre (avec aperçus)
    Alt+F4 fermer · Super+E fichiers · Super+I paramètres · Super+L verrouiller
    Super+D bureau · Super+V presse-papiers · Super+N notifications
    Super+↑ agrandir · Super+↓ moitié d'écran · Ctrl+Super+←/→ bureaux
    Super+Maj+S capture · Ctrl+Alt+Suppr éteindre · Super+F1 : aide
EOT
log "Session Niri configurée."
