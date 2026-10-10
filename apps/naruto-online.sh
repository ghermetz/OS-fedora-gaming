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
#    ./naruto-online.sh launch           # icône du menu : installe au 1er clic, puis joue
#    ./naruto-online.sh setup [source]   # installe (~30 min, une fois). [source] =
#                                        #   dossier contenant « Naruto Online.exe »,
#                                        #   installeur officiel .exe, ou son archive .zip
#    ./naruto-online.sh run              # lance le jeu
#    ./naruto-online.sh clear-cache      # vide le cache du navigateur intégré (chargement bloqué)
#    ./naruto-online.sh uninstall        # supprime préfixe, jeu et raccourci
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

is_ready() { [ -f "$GAME_DIR/$EXE" ] && [ -f "$WINEPREFIX/.naruto-deps-ok" ]; }

need_tools() {
  local missing=()
  command -v wine >/dev/null       || missing+=(wine)
  command -v winetricks >/dev/null || missing+=(winetricks)
  command -v unzip >/dev/null      || missing+=(unzip)
  [ ${#missing[@]} -eq 0 ] && return 0
  log "Installation de : ${missing[*]}"
  sudo dnf install -y "${missing[@]}"
}

# Cherche une source tout seul : jeu déjà installé sous Windows (partition
# montée), dossier copié, ou installeur officiel dans les Téléchargements.
find_source() {
  local c
  for c in "$GAME_DIR" \
           /run/media/"$USER"/*/"Program Files (x86)/Naruto Online" \
           /mnt/*/"Program Files (x86)/Naruto Online" \
           "$HOME/Téléchargements/Naruto Online" "$HOME/Downloads/Naruto Online"; do
    if [ -f "$c/$EXE" ]; then echo "$c"; return 0; fi
  done
  for c in "$HOME"/Téléchargements/Naruto\ Online*.zip "$HOME"/Téléchargements/Naruto\ Online*.exe \
           "$HOME"/Downloads/Naruto\ Online*.zip "$HOME"/Downloads/Naruto\ Online*.exe; do
    if [ -f "$c" ]; then echo "$c"; return 0; fi
  done
  return 1
}

# Pas de source trouvée : on la demande graphiquement (icône du menu)
ask_source() {
  command -v kdialog >/dev/null || return 1
  kdialog --title "Naruto Online" --msgbox "Installeur ou jeu Naruto Online introuvable.

Choisis l'installeur officiel (Naruto Online_fr_….zip ou .exe, téléchargé
sur le site du jeu) ou le dossier « Naruto Online » de ton Windows." || true
  kdialog --title "Naruto Online — installeur ou Naruto Online.exe" \
    --getopenfilename "$HOME" "Naruto Online (*.zip *.exe)"
}

do_setup() {
  local src="${1:-}"
  if [ -z "$src" ]; then
    src="$(find_source)" || die "Jeu introuvable — indique la source : ./naruto-online.sh setup \"/chemin/Naruto Online_fr_….zip\""
  fi
  # « Naruto Online.exe » choisi directement → son dossier
  [ -f "$src" ] && [ "$(basename "$src")" = "$EXE" ] && src="$(dirname "$src")"
  need_tools

  log "1/4 — Préfixe Wine dédié ($WINEPREFIX)"
  mkdir -p "$(dirname "$WINEPREFIX")"
  WINEDEBUG=-all wineboot -i >/dev/null 2>&1
  ok "préfixe créé"

  log "2/4 — .NET Framework 4.8 + polices (~20-30 min la première fois, patience)"
  if [ -f "$WINEPREFIX/.naruto-deps-ok" ]; then
    ok "déjà installés"
  else
    WINEDEBUG=-all winetricks -q --unattended dotnet48 corefonts \
      || die "winetricks a échoué — relance : ./naruto-online.sh setup"
    touch "$WINEPREFIX/.naruto-deps-ok"
    ok ".NET 4.8 + corefonts installés"
  fi

  log "3/4 — Jeu dans $GAME_DIR"
  mkdir -p "$GAME_DIR"
  if [ -d "$src" ]; then
    # Copie locale : lancer depuis une partition NTFS Windows ou un dossier
    # synchronisé provoque verrous et lenteurs.
    [ -f "$src/$EXE" ] || die "« $EXE » absent de : $src"
    if [ "$(readlink -f "$src")" != "$(readlink -f "$GAME_DIR")" ]; then
      cp -a "$src/." "$GAME_DIR/"
    fi
  else
    local installer="$src" tmp=""
    case "$src" in
      *.zip|*.ZIP)
        tmp="$(mktemp -d)"
        unzip -q -o "$src" -d "$tmp"
        installer="$(find "$tmp" -maxdepth 2 -iname '*.exe' | head -1)"
        [ -n "$installer" ] || die "Aucun installeur .exe dans l'archive : $src"
        ;;
      *.exe|*.EXE) ;;
      *) die "Source non reconnue (dossier, .exe ou .zip attendu) : $src" ;;
    esac
    echo "    Installation silencieuse de l'installeur officiel…"
    # Installeur NSIS : /S = silencieux, /D= dossier cible (dernier argument, sans guillemets)
    WINEDEBUG=-all wine "$installer" /S "/D=Z:${GAME_DIR//\//\\}" || true
    [ -n "$tmp" ] && rm -rf "$tmp"
    # L'installeur crée des raccourcis Wine en double dans le menu : on les retire
    rm -rf "$HOME/.local/share/applications/wine/Programs/Naruto Online" \
           "$HOME/Desktop/Naruto Online.desktop" "$HOME/Bureau/Naruto Online.desktop" 2>/dev/null || true
    [ -f "$GAME_DIR/$EXE" ] || die "L'installeur n'a pas créé « $EXE » dans $GAME_DIR"
  fi
  rm -rf "$GAME_DIR/swiftshader/GPUCache" "$GAME_DIR/debug.log"
  ok "jeu en place"

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

# Icône du menu livrée avec l'OS : 1er clic = installation guidée, ensuite = jeu
do_launch() {
  if is_ready; then do_run; fi
  local src
  src="$(find_source)" || src="$(ask_source)" || exit 0
  [ -n "$src" ] || exit 0
  # Installation visible dans un terminal (longue : .NET 4.8), puis lancement
  exec konsole --hold -p tabtitle="Installation de Naruto Online" -e bash -c \
    "bash \"$SELF\" setup \"$src\" && { echo; echo 'Lancement du jeu…'; setsid bash \"$SELF\" run >/dev/null 2>&1 & sleep 3; exit 0; }"
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
  ok "Naruto Online désinstallé (préfixe, jeu, raccourci)"
}

case "${1:-}" in
  launch)      do_launch ;;
  setup)       shift; do_setup "$@" ;;
  run)         do_run ;;
  clear-cache) do_clear_cache ;;
  uninstall)   do_uninstall ;;
  *) grep -E '^#  ' "$0" | sed 's/^#  //'; exit 1 ;;
esac
