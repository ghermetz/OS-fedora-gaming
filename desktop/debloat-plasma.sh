#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — desktop/debloat-plasma.sh
#  Allège Fedora KDE sans rien casser : retire ce qui est inutile sur un PC
#  de jeu / quotidien et passe des services en démarrage à la demande.
#  Testé en VM (F43) : -139 paquets, -395 Mo disque, Akonadi + MariaDB en
#  moins au démarrage. Plasma, Dolphin, Konsole, Discover, LibreOffice intacts.
#  FG_IMAGE_BUILD=1 : mode construction d'ISO (paquets exclus par KIWI,
#  services activés sans les démarrer).
# ============================================================================
set -euo pipefail

log()  { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
SUDO=sudo; [ "$(id -u)" -eq 0 ] && SUDO=
IMG="${FG_IMAGE_BUILD:-0}"
NOW=--now; [ "$IMG" = "1" ] && NOW=

# Paquets retirés (même liste exclue de l'ISO : iso/kiwi/fedora-gaming.xml)
REMOVE=(
  # Suite PIM KDE + Akonadi (embarque un serveur MariaDB) — Thunderbird la remplace
  "kmail*" kontact korganizer kaddressbook akregator "kdepim-*" "akonadi*" "pim-*"
  # Notificateur de mises à jour : on met à jour quand on veut (dnf / Discover)
  plasma-discover-notifier
  # Rapporteurs de plantage et alertes SELinux en barre système
  "abrt*" setroubleshoot
  # Gestionnaire de clés GPG (dépend d'Akonadi)
  kleopatra
  # Pont de partage d'écran X11 (fenêtre noire hors Plasma ; Vesktop est natif Wayland)
  xwaylandvideobridge
  # Petits jeux / applis de niche
  kmahjongg kmines kpat kamoso neochat qrca
  # Serveur de bureau à distance (surface d'attaque inutile)
  krfb
)

if [ "$IMG" != "1" ]; then
  log "Retrait des paquets inutiles…"
  $SUDO dnf remove -y "${REMOVE[@]}" || true
fi

log "Services à la demande…"
# Docker ne démarre que si WinBoat (ou autre) en a besoin
if systemctl list-unit-files docker.socket >/dev/null 2>&1; then
  $SUDO systemctl disable $NOW docker.service 2>/dev/null || true
  $SUDO systemctl enable $NOW docker.socket
fi
# Pas de modem 3G/4G sur un PC fixe
$SUDO systemctl disable $NOW ModemManager.service 2>/dev/null || true

log "Indexation de fichiers (Baloo) et clavier virtuel désactivés…"
# Baloo : indexation permanente du disque, inutile sans recherche plein texte
$SUDO mkdir -p /etc/xdg
$SUDO tee /etc/xdg/baloofilerc >/dev/null <<'EOT'
[Basic Settings]
Indexing-Enabled=false
EOT
if [ "$IMG" != "1" ]; then
  command -v balooctl6 >/dev/null && balooctl6 disable >/dev/null 2>&1 || true
  # Clavier virtuel (écrans tactiles uniquement) — /etc/xdg/kwinrc le couvre pour les nouveaux comptes
  kwriteconfig6 --file kwinrc --group Wayland --key InputMethod "" 2>/dev/null || true
fi

log "Plasma allégé."
