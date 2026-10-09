#!/usr/bin/env bash
# fedora-gaming — scripts/setup-dev-env.sh
# Environnements de dev avec Distrobox
set -euo pipefail

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

command -v distrobox >/dev/null || { echo "Distrobox non installé" >&2; exit 1; }

log "1/3 — Container Fedora Latest (dev général)"
if ! distrobox list | grep -q "^fedora-dev "; then
  distrobox create --name fedora-dev --image fedora:latest
  distrobox enter fedora-dev -- sudo dnf install -y \
    gcc gcc-c++ make cmake git nodejs python3 python3-pip rust cargo golang
  echo "    fedora-dev créé avec outils de développement"
else
  echo "    fedora-dev déjà existant"
fi

log "2/3 — Container Ubuntu LTS (compatibilité)"
if ! distrobox list | grep -q "^ubuntu-dev "; then
  distrobox create --name ubuntu-dev --image ubuntu:22.04
  distrobox enter ubuntu-dev -- bash -c "sudo apt update && sudo apt install -y \
    build-essential git curl python3 python3-pip nodejs npm"
  echo "    ubuntu-dev créé avec outils de build"
else
  echo "    ubuntu-dev déjà existant"
fi

log "3/3 — Container Arch (AUR)"
if ! distrobox list | grep -q "^arch-dev "; then
  distrobox create --name arch-dev --image archlinux:latest
  distrobox enter arch-dev -- sudo pacman -Syu --noconfirm \
    base-devel git vim neovim python nodejs npm rust
  echo "    arch-dev créé avec base-devel"
else
  echo "    arch-dev déjà existant"
fi

cat <<'DONE'

✅ Environnements dev créés !
─────────────────────────────
• fedora-dev : distrobox enter fedora-dev
• ubuntu-dev : distrobox enter ubuntu-dev
• arch-dev   : distrobox enter arch-dev

Exporter une commande vers l'hôte :
  distrobox enter fedora-dev -- distrobox-export --bin /usr/bin/node

Liste des containers :
  distrobox list
DONE
