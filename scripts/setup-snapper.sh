#!/usr/bin/env bash
# fedora-gaming — scripts/setup-snapper.sh
# Configure Snapper pour snapshots Btrfs automatiques
set -euo pipefail

log() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mERREUR: %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && die "Ne lance pas en root"

log "1/6 — Vérification Btrfs"
ROOT_FS="$(findmnt -n -o FSTYPE /)"
[ "$ROOT_FS" != "btrfs" ] && die "/ n'est pas en Btrfs (détecté: $ROOT_FS)"
echo "    Btrfs détecté sur / — OK"

log "2/6 — Installation snapper + grub2-btrfs"
sudo dnf install -y snapper grub2-btrfs python3-dnf-plugin-snapper

log "3/6 — Configuration snapper"
if ! snapper list-configs 2>/dev/null | grep -q "^root "; then
  [ ! -d /.snapshots ] && sudo btrfs subvolume create /.snapshots
  sudo snapper -c root create-config /
  echo "    Config 'root' créée"
else
  echo "    Config 'root' déjà existante"
fi

sudo snapper -c root set-config "TIMELINE_CREATE=yes"
sudo snapper -c root set-config "TIMELINE_CLEANUP=yes"
sudo snapper -c root set-config "TIMELINE_LIMIT_HOURLY=5"
sudo snapper -c root set-config "TIMELINE_LIMIT_DAILY=7"
sudo snapper -c root set-config "TIMELINE_LIMIT_WEEKLY=0"
sudo snapper -c root set-config "TIMELINE_LIMIT_MONTHLY=3"
sudo snapper -c root set-config "TIMELINE_LIMIT_YEARLY=0"

log "4/6 — Activation timers"
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

log "5/6 — Plugin dnf"
CONF="/etc/dnf/plugins/snapper.conf"
[ -f "$CONF" ] && sudo sed -i 's/^enabled *= *0/enabled = 1/' "$CONF"

log "6/6 — Régénération GRUB"
sudo grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || \
  sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

cat <<'DONE'

✅ Snapper configuré avec succès !
─────────────────────────────────
• Snapshots automatiques : activés (quotidiens, avant dnf upgrade)
• Rollback au boot       : menu GRUB → Advanced → choisis un snapshot
• Rollback manuel        : sudo snapper rollback <numéro> && reboot
• Lister les snapshots   : snapper list
• Créer un snapshot      : sudo snapper create --description "avant modif"
• Comparer snapshots     : snapper status <num1>..<num2>
DONE
