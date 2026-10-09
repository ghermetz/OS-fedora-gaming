#!/usr/bin/env bash
# fedora-gaming — apps/naruto-online-winboat.sh
# Route 3 : Windows 11 VM via WinBoat
set -euo pipefail

CONTAINER="naruto-online-win11"
SHARED="$HOME/Games/NarutoOnline-Shared"

log() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
die() { echo "ERREUR: $*" >&2; exit 1; }

check() {
  command -v winboat >/dev/null || die "WinBoat non installé (lance install.sh)"
  command -v docker >/dev/null || die "Docker non installé"
  docker info >/dev/null 2>&1 || die "Docker non accessible (ajoute-toi au groupe docker)"
}

case "${1:-}" in
  create)
    log "Création conteneur Windows 11"
    check
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$" && \
      die "Conteneur déjà existant. Utilise 'destroy' d'abord."
    mkdir -p "$SHARED"
    echo "Dossier partagé : $SHARED"
    echo ""
    echo "⚠️  Windows 11 téléchargé (~6-8 GB) + installation (~20 min)"
    read -p "Continuer ? [y/N] " -r
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    winboat create "$CONTAINER" \
      --os windows11 \
      --cpu 4 \
      --memory 8192 \
      --disk 60 || die "Échec création"
    echo "✅ Créé ! Lance avec: $0 start"
    ;;

  start)
    log "Démarrage Windows 11 + RDP"
    check
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$" || \
      die "Conteneur inexistant. Crée-le avec: $0 create"
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
      winboat start "$CONTAINER"
      echo "Attente RDP..."
      sleep 10
    fi
    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER" 2>/dev/null || echo "127.0.0.1")
    log "Connexion RDP à $IP"
    echo "Dans Windows: installe le jeu depuis $SHARED (monté sur Z:\)"
    xfreerdp /v:"$IP" /u:WinBoat /p: /cert:ignore \
      /dynamic-resolution /audio-mode:0 \
      /drive:shared,"$SHARED" || echo "FreeRDP fermé"
    ;;

  stop)
    winboat stop "$CONTAINER" 2>/dev/null || docker stop "$CONTAINER"
    echo "✅ Arrêté"
    ;;

  destroy)
    echo "⚠️  Supprimer $CONTAINER ? [y/N]"
    read -r
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    winboat stop "$CONTAINER" 2>/dev/null || true
    winboat remove "$CONTAINER" 2>/dev/null || docker rm -f "$CONTAINER"
    echo "✅ Supprimé"
    ;;

  status)
    check
    echo "État de $CONTAINER:"
    docker ps -a --filter "name=$CONTAINER" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || \
      echo "Conteneur non créé"
    ;;

  *)
    echo "Usage: $0 {create|start|stop|destroy|status}"
    echo "Route 3 — Naruto Online Windows 11 natif (compatibilité 100%)"
    exit 1
    ;;
esac
