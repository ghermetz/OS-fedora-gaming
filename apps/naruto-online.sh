#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — apps/naruto-online.sh
#  Faire tourner Naruto Online (launcher .NET + CEF + Flash) sous Fedora.
#
#  Symptôme connu sous Wine : la fenêtre s'ouvre mais reste NOIRE — le
#  processus GPU de Chromium embarqué (CEF) plante sous Wine. Les remèdes
#  appliqués ici : rendu logiciel forcé (d3d11/dxgi désactivés +
#  LIBGL_ALWAYS_SOFTWARE) dans une bouteille dédiée.
#
#  Usage :
#    ./naruto-online.sh ruffle            # Route 1 — jeu web via Ruffle (à essayer d'abord)
#    ./naruto-online.sh setup <dossier>   # Route 2 — prépare la bouteille Bottles
#                                         #   <dossier> = chemin du dossier "Naruto Online"
#    ./naruto-online.sh run               # Route 2 — lance le jeu (rendu logiciel forcé)
# ============================================================================
set -euo pipefail

FLAT_BOTTLES="com.usebottles.bottles"
FLAT_RUFFLE="rs.ruffle.Ruffle"
BOTTLE="Naruto Online"
PORTAL="https://gamebox3.narutowebgame.com"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

bottles_cli() {
  flatpak run --command=bottles-cli "$FLAT_BOTTLES" "$@"
}

do_ruffle() {
  log "Route 1 — Naruto Online via Ruffle (Flash émulé, natif Linux)"
  if ! flatpak info "$FLAT_RUFFLE" >/dev/null 2>&1; then
    sudo flatpak install --system --or-update -y flathub "$FLAT_RUFFLE"
  fi
  echo "    Ruffle s'ouvre sur le portail du jeu : $PORTAL"
  echo "    Connecte-toi ; si un contenu reste vide, essaie la Route 2."
  flatpak run "$FLAT_RUFFLE" "$PORTAL"
}

do_setup() {
  local game_dir="${1:-}"
  if [ -z "$game_dir" ] || [ ! -d "$game_dir" ]; then
    echo "Usage : ./naruto-online.sh setup <chemin du dossier « Naruto Online »>" >&2
    exit 1
  fi
  log "Route 2 — bouteille Bottles dédiée (rendu logiciel, anti écran noir)"
  if ! flatpak info "$FLAT_BOTTLES" >/dev/null 2>&1; then
    sudo flatpak install --system --or-update -y flathub "$FLAT_BOTTLES"
  fi
  if ! bottles_cli list --bottles 2>/dev/null | grep -q "$BOTTLE"; then
    bottles_cli new -b "$BOTTLE" -e application
  fi
  echo "    Installation de dotnet452 (framework .NET du launcher, ~5 min)…"
  bottles_cli tools -b "$BOTTLE" --install dotnet452 || \
    warn "dotnet452 a échoué — retente : bottles-cli tools -b \"$BOTTLE\" --install dotnet452"
  echo "    Ajout du launcher comme programme…"
  bottles_cli add -b "$BOTTLE" --path "$game_dir/Naruto Online.exe" --name "Naruto Online"
  echo "Bouteille prête. Lance le jeu avec : ./naruto-online.sh run"
  echo "Astuce : copie le dossier du jeu hors de tout dossier synchronisé"
  echo "(ex. ~/Games/Naruto Online) pour éviter les verrous pendant le jeu."
}

do_run() {
  log "Lancement de Naruto Online (rendu logiciel forcé — anti écran noir)"
  flatpak run \
    --env=WINEDLLOVERRIDES="d3d11,dxgi=d" \
    --env=LIBGL_ALWAYS_SOFTWARE=1 \
    --command=bottles-cli "$FLAT_BOTTLES" run -b "$BOTTLE" -a "Naruto Online"
}

case "${1:-}" in
  ruffle)       do_ruffle ;;
  setup)        shift; do_setup "$@" ;;
  run)          do_run ;;
  *)
    grep -E '^#  ' "$0" | sed 's/^#  //' ; exit 1 ;;
esac
