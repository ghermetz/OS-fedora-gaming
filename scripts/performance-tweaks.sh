#!/usr/bin/env bash
# fedora-gaming — scripts/performance-tweaks.sh
# Optimisations système pour gaming (CPU, I/O, VM)
set -euo pipefail

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

[ "$(id -u)" -eq 0 ] && { echo "Ne lance pas en root" >&2; exit 1; }

log "1/5 — CPU Governor → performance"
sudo dnf install -y kernel-tools
echo 'GOVERNOR="performance"' | sudo tee /etc/sysconfig/cpupower
sudo systemctl enable --now cpupower
echo "    CPU governor: performance (pleine puissance)"

log "2/5 — I/O Scheduler → mq-deadline (SSD/NVMe)"
cat | sudo tee /etc/udev/rules.d/60-ioschedulers.rules <<'UDEV'
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
UDEV
sudo udevadm control --reload-rules
sudo udevadm trigger
echo "    I/O scheduler: mq-deadline pour SSD"

log "3/5 — VM tuning (swappiness + max_map_count)"
cat | sudo tee /etc/sysctl.d/99-gaming.conf <<'SYSCTL'
# Swappiness réduite (32GB RAM)
vm.swappiness=10

# Map count pour jeux Windows
vm.max_map_count=2147483642

# Dirty ratio optimisé
vm.dirty_ratio=10
vm.dirty_background_ratio=5
SYSCTL
sudo sysctl -p /etc/sysctl.d/99-gaming.conf
echo "    vm.swappiness=10, vm.max_map_count=2147483642"

log "4/5 — Transparent Huge Pages → madvise"
cat | sudo tee /etc/tmpfiles.d/thp.conf <<'THP'
w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise
w /sys/kernel/mm/transparent_hugepage/defrag - - - - madvise
THP
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
echo "    THP: madvise"

log "5/5 — PCI latency (GPU AMD)"
cat | sudo tee /etc/udev/rules.d/60-pci-latency.rules <<'PCI'
ACTION=="add", SUBSYSTEM=="pci", DRIVER=="amdgpu", ATTR{latency_timer}="0"
PCI
sudo udevadm control --reload-rules
echo "    PCI latency optimisée"

cat <<'DONE'

✅ Optimisations gaming appliquées !
────────────────────────────────────
• CPU Governor      : performance
• I/O Scheduler     : mq-deadline
• VM Swappiness     : 10
• VM max_map_count  : 2147483642
• THP               : madvise
• PCI Latency       : optimisée GPU

⚠️  Redémarre pour activer complètement.

Vérification post-reboot :
  cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  cat /sys/block/nvme0n1/queue/scheduler
  sysctl vm.swappiness vm.max_map_count
DONE
