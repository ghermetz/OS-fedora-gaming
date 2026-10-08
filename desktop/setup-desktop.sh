#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — desktop/setup-desktop.sh
#  Look KDE Plasma + réglages gaming (Fedora KDE).
#
#    • look dark gaming : conserve le thème Fedora s'il est sombre, sinon
#      Breeze Dark ; icônes Papirus-Dark ; accent rouge AMD ; animations
#      accélérées ; clic simple à la Windows
#    • gaming : tearing autorisé en plein écran (KWin)
#    • affiche les réglages à faire à la main (VRR par écran, souris, veille)
# ============================================================================
set -euo pipefail

log()  { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  warn "kwriteconfig6 absent — KDE Plasma non détecté, rien à faire."
  exit 0
fi

kset() { # kset <fichier> <clé> <valeur> [groupe]
  local f="$1" k="$2" v="$3" g="${4:-}"
  if [ -n "$g" ]; then
    kwriteconfig6 --file "$f" --group "$g" --key "$k" "$v"
  else
    kwriteconfig6 --file "$f" --key "$k" "$v"
  fi
}

log "KDE — look dark gaming"
# Thème de couleurs : on garde celui de Fedora KDE s'il est sombre.
cs="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme || true)"
case "$cs" in
  *Light*|"")
    plasma-apply-colorscheme BreezeDark 2>/dev/null \
      || plasma-apply-colorscheme org.kde.breezedark.desktop 2>/dev/null \
      || warn "Active « Breeze Dark » dans Paramètres système → Apparence."
    ;;
  *) echo "    Thème de couleurs conservé : $cs" ;;
esac
if ! rpm -q papirus-icon-theme >/dev/null 2>&1; then
  sudo dnf install -y papirus-icon-theme
fi
kset kdeglobals Theme Papirus-Dark Icons
kset kdeglobals AccentColor "200,25,45" General      # accent rouge AMD
kset kdeglobals UseCustomAccentColor true General
kset kdeglobals SingleClick true KDE                 # ouvrir d'un seul clic (comme Windows)
kset kdeglobals AnimationDurationFactor 0.5 KDE      # animations raccourcies = "smooth"

# Interface en français (applis KDE + formats régionaux)
kset plasma-localerc LANG fr_FR.UTF-8 Formats
kset plasma-localerc LANGUAGE fr Translations

log "KDE — gaming"
kset kwinrc AllowTearing true Compositing            # tearing autorisé (utile avec VRR)
echo "    Barre des tâches : le panneau Plasma par défaut est déjà façon Windows.
    Clic droit sur le panneau pour l'ajuster (taille, centrage, épinglage)."

cat <<'EOT'

  À régler à la main (2 minutes, non scriptable proprement)
  ─────────────────────────────────────────────────────────
  • VRR/FreeSync multi-écrans : Paramètres système → Écran et moniteur →
    écran PRINCIPAL → Adaptive Sync : « Toujours »
    (« Automatique » sur le(s) secondaire(s) pour éviter les soucis).
  • Souris : Paramètres système → Souris → Accélération : « Plate »
    (précision brute en jeu).
  • Alimentation : sur secteur → pas de suspension automatique.
EOT

log "Bureau configuré. Déconnexion/reconnexion pour tout appliquer."
