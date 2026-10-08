#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — desktop/setup-tiling.sh
#  Sessions tiling bonus, configurées à la Windows :
#    • Sway « mode Windows » : tout flottant + barre des tâches waybar
#    • Niri « tiling défilant » : la bande horizontale nouvelle génération
#  Les deux partagent la même barre waybar (tâches, horloge, systray, stats).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TILING_DIR="$SCRIPT_DIR/tiling"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

log "Installation des composants (Sway, Niri, waybar, outils)…"
sudo dnf install -y niri sway waybar wofi mako grim slurp \
  xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
  polkit-kde qt6-qtwayland qt5-qtwayland fontawesome-6-free-fonts

log "Déploiement des configurations…"
mkdir -p "$HOME/.config/sway" "$HOME/.config/niri" "$HOME/.config/waybar" \
  "$HOME/Pictures/Screenshots"
cp "$TILING_DIR/sway-config"     "$HOME/.config/sway/config"
cp "$TILING_DIR/niri-config.kcl" "$HOME/.config/niri/config.kcl"
cp "$TILING_DIR/waybar.jsonc"    "$HOME/.config/waybar/config.jsonc"
cp "$TILING_DIR/waybar.css"      "$HOME/.config/waybar/style.css"

cat <<'EOT'

  Sessions « Sway » et « Niri » disponibles à l'écran de connexion.
  Raccourcis communs (Super = touche Windows) :
    Super+Entrée terminal · Super+D menu d'applications · Super+E fichiers
    Super+G Steam · Impr. écran capture (zone) · Super+Q fermer fenêtre
  Sway = mode Windows (tout flottant, barre des tâches en bas).
  Niri = tiling défilant (Super+Shift+S affiche l'aide-mémoire des raccourcis).
EOT
log "Sessions tiling configurées."
