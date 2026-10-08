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
flat_have() { flatpak info "$1" >/dev/null 2>&1; }
flat_get()  { sudo flatpak install --system --or-update -y flathub "$1"; }
bottles_cli() { flatpak run --command=bottles-cli "$FLAT_BOTTLES" "$@"; }

bottle_dir() {
  echo "$HOME/.var/app/$FLAT_BOTTLES/data/bottles/bottles/$BOTTLE"
}

find_runner() {
  local d="$HOME/.var/app/$FLAT_BOTTLES/data/bottles/runners" r
  for pattern in soda-* caffe-* kronk-*; do
    for r in "$d"/$pattern; do
      if [ -x "$r/bin/wine" ]; then echo "$r/bin/wine"; return 0; fi
    done
  done
  return 1
}

do_ruffle() {
  log "Route 1 — Naruto Online via Ruffle (Flash émulé, natif Linux)"
  if ! flat_have "$FLAT_RUFFLE"; then flat_get "$FLAT_RUFFLE"; fi
  echo "    Note : le bureau Ruffle ne navigue pas sur le web. Pour le jeu en"
  echo "    ligne, utilise l'extension Ruffle de Firefox :"
  echo "      https://addons.mozilla.org/firefox/addon/ruffle_ruffle_provider/"
  echo "    puis ouvre $PORTAL"
  echo "    Ou appuie sur Entrée pour ouvrir Ruffle vide (fichiers .swf locaux)…"
  read -r
  flatpak run "$FLAT_RUFFLE"
}

do_setup() {
  local game_dir="${1:-}"
  if [ -z "$game_dir" ] || [ ! -f "$game_dir/Naruto Online.exe" ]; then
    echo "Usage : ./naruto-online.sh setup <chemin du dossier « Naruto Online »>" >&2
    exit 1
  fi
  log "Route 2 — bouteille Bottles dédiée (rendu logiciel, anti écran noir)"
  if ! flat_have "$FLAT_BOTTLES"; then flat_get "$FLAT_BOTTLES"; fi

  if ! bottles_cli list --bottles 2>/dev/null | grep -q "$BOTTLE"; then
    bottles_cli new --bottle-name "$BOTTLE" --environment application
  fi

  if [ ! -f "$(bottle_dir)/drive_c/windows/system32/mscoree.dll" ]; then
    local runner
    if ! runner="$(find_runner)"; then
      warn "Aucun runner Wine dans Bottles — ouvre l'app Bottles, installe un"
      warn "runner (Soda/Caffe), puis relance : ./naruto-online.sh setup"
      exit 1
    fi
    echo "    Installation de dotnet452 via winetricks (~10 min, Patientez)…"
    if ! WINEPREFIX="$(bottle_dir)" WINE="$runner" winetricks -q dotnet452; then
      warn "dotnet452 a échoué — relance : WINEPREFIX=\"$(bottle_dir)\" WINE=\"$runner\" winetricks -q dotnet452"
      exit 1
    fi
  else
    echo "    dotnet452 déjà présent dans la bouteille."
  fi

  echo "    Ajout du launcher comme programme…"
  bottles_cli add -b "$BOTTLE" -n "Naruto Online" -p "$game_dir/Naruto Online.exe"
  echo "Bouteille prête. Lance le jeu avec : ./naruto-online.sh run"
  echo "Astuce : garde le dossier du jeu hors de tout dossier synchronisé"
  echo "(Nextcloud, etc.) pour éviter verrous et lenteurs pendant le jeu."
}

do_run() {
  log "Lancement de Naruto Online (rendu logiciel forcé — anti écran noir)"
  flatpak run \
    --env=WINEDLLOVERRIDES="d3d11,dxgi=d" \
    --env=LIBGL_ALWAYS_SOFTWARE=1 \
    --command=bottles-cli "$FLAT_BOTTLES" run -b "$BOTTLE" -p "Naruto Online"
}

case "${1:-}" in
  ruffle)       do_ruffle ;;
  setup)        shift; do_setup "$@" ;;
  run)          do_run ;;
  *)
    grep -E '^#  ' "$0" | sed 's/^#  //' ; exit 1 ;;
esac
