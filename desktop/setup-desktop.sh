#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — desktop/setup-desktop.sh
#  KDE Plasma façon Windows 11, allégé, réglé pour le jeu.
#
#    • allègement : desktop/debloat-plasma.sh (Akonadi/MariaDB, rapporteurs
#      de plantage, notificateur de MAJ… ; Docker à la demande ; sans Baloo)
#    • thème global « Fedora Gaming (Windows 11) » (desktop/plasma/) :
#      barre centrée Démarrer + applis épinglées, sombre, accent rouge,
#      Alt+Tab en vignettes — par défaut pour tout nouvel utilisateur
#    • Naruto Online préconfiguré : icône du menu qui installe au 1er clic
#    • gaming : tearing autorisé en plein écran, souris sans accélération
#
#    bash desktop/setup-desktop.sh            # tout
#    bash desktop/setup-desktop.sh --system   # partie système seule (sans session)
#    FG_IMAGE_BUILD=1 … --system              # construction de l'ISO (sans dnf)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LNF_ID="org.fedoragaming.desktop"
SHARE=/usr/share/fedora-gaming
SYSTEM_ONLY=0
[ "${1:-}" = "--system" ] && SYSTEM_ONLY=1

log()  { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
SUDO=sudo; [ "$(id -u)" -eq 0 ] && SUDO=

if ! command -v plasmashell >/dev/null 2>&1; then
  warn "KDE Plasma non détecté — rien à faire."
  exit 0
fi

# ------------------------------------------------------------ partie système
bash "$SCRIPT_DIR/debloat-plasma.sh"

log "Thème global « Fedora Gaming (Windows 11) »"
[ "${FG_IMAGE_BUILD:-0}" = "1" ] || $SUDO dnf install -y papirus-icon-theme
$SUDO mkdir -p /usr/share/plasma/look-and-feel
$SUDO cp -r "$SCRIPT_DIR/plasma/$LNF_ID" /usr/share/plasma/look-and-feel/
# Par défaut pour tout nouveau compte (et la session live de l'ISO)
$SUDO mkdir -p /etc/xdg
$SUDO tee /etc/xdg/kdeglobals >/dev/null <<EOF
[KDE]
LookAndFeelPackage=$LNF_ID
SingleClick=true
AnimationDurationFactor=0.5

[General]
ColorScheme=BreezeDark
AccentColor=200,25,45

[Icons]
Theme=Papirus-Dark
EOF
# Gaming : tearing autorisé en plein écran (utile avec VRR), souris « plate »
$SUDO tee /etc/xdg/kwinrc >/dev/null <<'EOF'
[Compositing]
AllowTearing=true

[Wayland]
InputMethod=
EOF
$SUDO tee /etc/xdg/kcminputrc >/dev/null <<'EOF'
[Libinput][Defaults][Pointer]
PointerAccelerationProfile=1
EOF

log "Naruto Online préconfiguré (installation au 1er clic sur l'icône)"
# (dans l'ISO le projet est déjà dans $SHARE : pas de copie sur lui-même)
if [ "$(readlink -f "$PROJECT_DIR")" != "$SHARE" ]; then
  $SUDO install -D -m 755 "$PROJECT_DIR/apps/naruto-online.sh" "$SHARE/apps/naruto-online.sh"
fi
$SUDO install -D -m 644 "$PROJECT_DIR/apps/naruto-online.desktop" /usr/share/applications/naruto-online.desktop

[ "$SYSTEM_ONLY" = "1" ] && { log "Partie système configurée."; exit 0; }

# ---------------------------------------------- session de l'utilisateur actuel
log "Application au compte actuel"
if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
  # --resetLayout : remplace la barre actuelle par la disposition Windows 11
  plasma-apply-lookandfeel -a "$LNF_ID" --resetLayout \
    || warn "Applique-le à la main : Paramètres système → Thème global → Fedora Gaming (Windows 11)"
else
  warn "Pas de session graphique : thème appliqué à la prochaine connexion d'un nouveau compte."
  warn "Pour ce compte : Paramètres système → Thème global → Fedora Gaming (Windows 11)"
fi

cat <<'EOT'

  À régler à la main (2 minutes, dépend de tes écrans)
  ────────────────────────────────────────────────────
  • VRR/FreeSync multi-écrans : Paramètres système → Écran et moniteur →
    écran PRINCIPAL → Adaptive Sync : « Toujours »
    (« Automatique » sur le(s) secondaire(s) pour éviter les soucis).
EOT
log "Bureau configuré. Déconnexion/reconnexion pour tout appliquer."
