#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — apps/naruto-online.sh
#  Naruto Online sous Fedora : le launcher Windows officiel (.NET + CefSharp /
#  Chromium 75 + Flash PPAPI embarqué) dans un préfixe Wine dédié.
#
#  Recette VALIDÉE en VM (Fedora 43, Wine 11 Staging) : connexion, chargement
#  du jeu Flash et écran de jeu interactif — sans aucun réglage de rendu.
#  /!\ Ne PAS désactiver d3d11/dxgi (ancien « anti écran noir ») : libcef.dll
#      en dépend, le launcher plante au démarrage (CefSharp.Core introuvable).
#
#  Usage :
#    ./naruto-online.sh setup [dossier]  # copie le jeu + prépare Wine (~30 min, une fois)
#                                        #   [dossier] = dossier contenant « Naruto Online.exe »
#    ./naruto-online.sh run              # lance le jeu (aussi via le menu : « Naruto Online »)
#    ./naruto-online.sh clear-cache      # vide le cache du navigateur intégré (chargement bloqué)
#    ./naruto-online.sh uninstall        # supprime préfixe, jeu copié et raccourci
# ============================================================================
set -euo pipefail

GAME_DIR="${NARUTO_GAME_DIR:-$HOME/Games/Naruto Online}"
export WINEPREFIX="${NARUTO_PREFIX:-$HOME/.local/share/wineprefixes/naruto-online}"
EXE="Naruto Online.exe"
DESKTOP_FILE="$HOME/.local/share/applications/naruto-online.desktop"
SELF="$(readlink -f "$0")"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m ✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m[✘] %s\033[0m\n' "$*" >&2; exit 1; }

need_tools() {
  local missing=()
  command -v wine >/dev/null       || missing+=(wine)
  command -v winetricks >/dev/null || missing+=(winetricks)
  [ ${#missing[@]} -eq 0 ] && return 0
  log "Installation de : ${missing[*]}"
  sudo dnf install -y "${missing[@]}"
}

# Dossiers où chercher le jeu si aucun chemin n'est donné (partition Windows montée…)
find_source() {
  local c
  for c in "$GAME_DIR" \
           /run/media/"$USER"/*/"Program Files (x86)/Naruto Online" \
           /mnt/*/"Program Files (x86)/Naruto Online" \
           "$HOME/Téléchargements/Naruto Online" "$HOME/Downloads/Naruto Online"; do
    if [ -f "$c/$EXE" ]; then echo "$c"; return 0; fi
  done
  return 1
}

do_setup() {
  local src="${1:-}"
  if [ -z "$src" ]; then
    src="$(find_source)" || die "Jeu introuvable — indique le dossier : ./naruto-online.sh setup \"/chemin/Naruto Online\""
  fi
  [ -f "$src/$EXE" ] || die "« $EXE » absent de : $src"
  need_tools

  log "1/4 — Copie du jeu dans $GAME_DIR"
  # Copie locale : lancer depuis une partition NTFS Windows ou un dossier
  # synchronisé provoque verrous et lenteurs.
  if [ "$(readlink -f "$src")" != "$(readlink -f "$GAME_DIR" 2>/dev/null || true)" ]; then
    mkdir -p "$GAME_DIR"
    cp -a "$src/." "$GAME_DIR/"
    rm -rf "$GAME_DIR/swiftshader/GPUCache" "$GAME_DIR/debug.log"
  fi
  ok "jeu en place"

  log "2/4 — Préfixe Wine dédié ($WINEPREFIX)"
  mkdir -p "$(dirname "$WINEPREFIX")"
  WINEDEBUG=-all wineboot -i >/dev/null 2>&1
  ok "préfixe créé"

  log "3/4 — .NET Framework 4.8 + polices (~20-30 min la première fois, patience)"
  if [ -f "$WINEPREFIX/.naruto-deps-ok" ]; then
    ok "déjà installés"
  else
    WINEDEBUG=-all winetricks -q --unattended dotnet48 corefonts \
      || die "winetricks a échoué — relance : ./naruto-online.sh setup"
    touch "$WINEPREFIX/.naruto-deps-ok"
    ok ".NET 4.8 + corefonts installés"
  fi

  log "4/4 — Raccourci dans le menu des applications"
  mkdir -p "$(dirname "$DESKTOP_FILE")"
  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Naruto Online
Comment=Launcher officiel Naruto Online (Wine)
Exec=bash "$SELF" run
Icon=$GAME_DIR/logo.ico
Categories=Game;
StartupWMClass=naruto online.exe
EOF
  update-desktop-database "$(dirname "$DESKTOP_FILE")" 2>/dev/null || true
  ok "« Naruto Online » ajouté au menu"
  echo
  echo "Prêt ! Lance le jeu depuis le menu, ou : ./naruto-online.sh run"
  echo "Le 1er chargement du jeu est long (le launcher le signale) — c'est normal."
}

do_run() {
  [ -f "$GAME_DIR/$EXE" ] || die "Jeu non installé — lance d'abord : ./naruto-online.sh setup"
  [ -f "$WINEPREFIX/.naruto-deps-ok" ] || die "Préfixe incomplet — relance : ./naruto-online.sh setup"
  cd "$GAME_DIR"
  WINEDEBUG="${WINEDEBUG:--all}" exec wine "$EXE"
}

do_clear_cache() {
  local cache="$WINEPREFIX/drive_c/users/$USER/AppData/Roaming/Naruto Online/Browers/Cache"
  wineserver -k 2>/dev/null || true
  rm -rf "$cache" "$GAME_DIR/swiftshader/GPUCache"
  ok "cache vidé (tu devras te reconnecter dans le launcher)"
}

do_uninstall() {
  wineserver -k 2>/dev/null || true
  rm -rf "$WINEPREFIX" "$GAME_DIR" "$DESKTOP_FILE"
  ok "Naruto Online désinstallé (préfixe, jeu copié, raccourci)"
}

case "${1:-}" in
  setup)       shift; do_setup "$@" ;;
  run)         do_run ;;
  clear-cache) do_clear_cache ;;
  uninstall)   do_uninstall ;;
  *) grep -E '^#  ' "$0" | sed 's/^#  //'; exit 1 ;;
esac
