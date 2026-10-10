#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — desktop/setup-tiling.sh
#  Sessions tiling bonus, rendues simples à utiliser :
#    • Sway « mode Windows » : tout flottant, ancrage Super+flèches, Alt+Tab
#    • Niri « tiling défilant » : la bande horizontale nouvelle génération
#  Communs : barre waybar avec bouton Démarrer (fuzzel), fenêtres ouvertes,
#  systray (réseau), son, aide « ? » (Super+F1) et menu d'extinction (wlogout).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TILING_DIR="$SCRIPT_DIR/tiling"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

log "Installation des composants (Sway, Niri, waybar, outils)…"
sudo dnf install -y niri sway waybar fuzzel mako wlogout \
  swaybg swaylock swayidle grim slurp wl-clipboard \
  xwayland-satellite network-manager-applet pavucontrol kdialog \
  xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
  polkit-kde qt6-qtwayland qt5-qtwayland fontawesome-6-free-fonts \
  google-noto-emoji-fonts

log "Déploiement des configurations…"
mkdir -p "$HOME/.config/sway" "$HOME/.config/niri" "$HOME/.config/waybar" \
  "$HOME/.config/wlogout" "$HOME/.config/fuzzel" "$HOME/.config/fedora-gaming" "$HOME/Images/Captures"
cp "$TILING_DIR/sway-config"     "$HOME/.config/sway/config"
cp "$TILING_DIR/niri-config.kdl" "$HOME/.config/niri/config.kdl"   # niri lit config.kdl
cp "$TILING_DIR/waybar.jsonc"    "$HOME/.config/waybar/config.jsonc"
cp "$TILING_DIR/waybar.css"      "$HOME/.config/waybar/style.css"
cp "$TILING_DIR/wlogout-layout"  "$HOME/.config/wlogout/layout"
cp "$TILING_DIR/wlogout.css"     "$HOME/.config/wlogout/style.css"
cp "$TILING_DIR/fuzzel.ini"      "$HOME/.config/fuzzel/fuzzel.ini"
cp "$TILING_DIR/aide-sway.txt"   "$HOME/.config/fedora-gaming/aide-sway.txt"
install -m 755 "$TILING_DIR/aide-tiling.sh" "$HOME/.config/fedora-gaming/aide-tiling.sh"
rm -f "$HOME/.config/niri/config.kcl"   # ancien nom erroné (jamais lu par niri)


# Niri lance les programmes de démarrage automatique du système (Sway non) :
# on y masque les outils propres à KDE/au bureau complet, inutiles ou gênants
# hors Plasma (fenêtre noire du pont XWayland, alertes de plantage, IBus…).
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

  Sessions « Sway » et « Niri » disponibles à l'écran de connexion
  (en bas à gauche : « Session de bureau »).
  Repères communs (Super = touche Windows) :
    Bouton ⊞ Démarrer ou Super+Espace : applications
    Bouton ? ou Super+F1 : aide-mémoire des raccourcis
    Bouton ⏻ ou Ctrl+Alt+Suppr : verrouiller / déconnexion / éteindre
    Alt+F4 fermer · Alt+Tab changer de fenêtre · Super+E fichiers · Super+L verrouiller
  Sway = mode Windows (Super+←/→ moitié d'écran, Super+↑ agrandir).
  Niri = bande défilante (Super+←/→ naviguer, Super+Tab vue d'ensemble).
EOT
log "Sessions tiling configurées."
