#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — vm-test/test-vm.sh
#  Banc d'essai VirtualBox : teste install.sh dans une VM Fedora KDE
#  AVANT de toucher à la vraie machine.
#
#  Usage :
#    ./test-vm.sh download    # télécharge l'ISO Fedora KDE (~2,5 Go)
#    ./test-vm.sh create      # crée la VM + lance l'install unattendue (15-25 min)
#    ./test-vm.sh status      # état de la VM
#    ./test-vm.sh wait-ready  # attend que la VM installée soit joignable en SSH
#    ./test-vm.sh run         # copie le projet + lance install.sh DANS la VM
#    ./test-vm.sh ssh "cmd"   # exécute une commande dans la VM
#    ./test-vm.sh destroy     # supprime la VM, son disque et l'ISO
#
#  Identifiants VM (test uniquement) : guill / osgaming2026
#  Prérequis : VirtualBox 7.x avec VBoxManage dans le PATH
# ============================================================================
set -euo pipefail

VM_NAME="fedora-gaming-test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
# NB : les données VM vivent HORS de Documents (protection dossier bloque
# les écritures du shell dans Documents). Le projet, lui, est seulement lu.
VM_DIR="$HOME/VirtualBox VMs/fedora-gaming-test"
ISO_DIR="$HOME/Downloads/fedora-gaming-iso"
FEDORA_VER="44"
VM_USER="guill"
# Mot de passe de TEST uniquement : VM locale en NAT (jamais exposée au réseau).
# Surchargeable : VM_PW="ton-mot-de-passe" ./test-vm.sh create
VM_PW="${VM_PW:-osgaming2026}"
SSH_PORT=2222

# --- VBoxManage : PATH ou chemin d'installation Windows --------------------
VB="VBoxManage"
if ! command -v "$VB" >/dev/null 2>&1; then
  for cand in "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"; do
    if [ -x "$cand" ]; then VB="$cand"; break; fi
  done
fi
if ! command -v "$VB" >/dev/null 2>&1 && [ ! -x "$VB" ]; then
  echo "VBoxManage introuvable — installe VirtualBox 7.x." >&2
  exit 1
fi

mkdir -p "$VM_DIR" "$ISO_DIR"

# --- SSH sans saisie manuelle (askpass forcé, OpenSSH ≥ 8.4) ----------------
askpass_setup() {
  cat > "$VM_DIR/askpass.sh" <<EOF
#!/bin/sh
echo "$VM_PW"
EOF
  chmod +x "$VM_DIR/askpass.sh"
}

ssh_vm() {
  askpass_setup
  SSH_ASKPASS="$VM_DIR/askpass.sh" SSH_ASKPASS_REQUIRE=force DISPLAY=:0 \
    ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 "$VM_USER@127.0.0.1" "$@"
}

port_open() {
  (exec 3<>"/dev/tcp/127.0.0.1/$SSH_PORT") 2>/dev/null && { exec 3>&- 3<&-; return 0; } || return 1
}

# --- résolution de l'ISO Fedora KDE ----------------------------------------
find_local_iso() {
  ls "$ISO_DIR"/Fedora-KDE-*Live-*.iso 2>/dev/null | head -1 || true
}

resolve_iso_url() {
  local page name
  for base in \
    "https://mirrors.kernel.org/fedora/releases/${FEDORA_VER}/KDE/x86_64/iso/" \
    "https://dl.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_VER}/KDE/x86_64/iso/"; do
    page="$(curl -sL --max-time 30 "$base" || true)"
    name="$(echo "$page" | grep -oE 'Fedora-KDE-[A-Za-z-]*Live-[0-9.-]+\.x86_64\.iso' | sort -u | tail -1 || true)"
    if [ -n "$name" ]; then
      echo "$base$name"
      return 0
    fi
  done
  return 1
}

# --- phases -----------------------------------------------------------------
do_download() {
  local iso; iso="$(find_local_iso || true)"
  if [ -n "$iso" ]; then
    echo "ISO déjà présente : $iso"
    return 0
  fi
  local url
  if ! url="$(resolve_iso_url)"; then
    echo "Impossible de lister les ISO Fedora ${FEDORA_VER} — télécharge manuellement l'ISO KDE :" >&2
    echo "  https://fedoraproject.org/spins/kde/download  →  place-la dans $ISO_DIR/" >&2
    return 1
  fi
  echo "Téléchargement : $url"
  curl -fL -C - --retry 5 -o "$ISO_DIR/$(basename "$url")" "$url"
  echo "ISO téléchargée : $ISO_DIR/$(basename "$url")"
}

do_create() {
  local iso; iso="$(find_local_iso || true)"
  if [ -z "$iso" ]; then
    echo "Pas d'ISO — lance d'abord : ./test-vm.sh download" >&2
    return 1
  fi
  if "$VB" showvminfo "$VM_NAME" >/dev/null 2>&1; then
    echo "La VM '$VM_NAME' existe déjà — ./test-vm.sh destroy pour repartir de zéro." >&2
    return 1
  fi

  echo "Création de la VM ($VM_NAME) : 4 vCPU, 8 Go RAM, 60 Go, EFI…"
  "$VB" createvm --name "$VM_NAME" --ostype Fedora_64 --register --basefolder "$VM_DIR"
  "$VB" modifyvm "$VM_NAME" \
    --memory 8192 --cpus 4 --vram 128 \
    --firmware efi \
    --graphics-controller vmsvga \
    --audio-driver none \
    --nic1 nat \
    --nat-pf1 "ssh,tcp,,${SSH_PORT},,22" \
    --boot1 dvd --boot2 disk --boot3 none --boot4 none
  "$VB" createmedium disk --filename "$VM_DIR/$VM_NAME.vdi" --size 61440 --variant standard
  "$VB" storagectl "$VM_NAME" --name SATA --add sata --controller IntelAHCI --bootable on
  "$VB" storageattach "$VM_NAME" --storagectl SATA --port 0 --device 0 --type hdd --medium "$VM_DIR/$VM_NAME.vdi"
  "$VB" storageattach "$VM_NAME" --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$iso"

  printf '%s' "$VM_PW" > "$VM_DIR/vm-password.txt"
  echo "Lancement de l'installation sans intervention (~15-25 min)…"
  "$VB" unattended install "$VM_NAME" \
    --iso="$iso" \
    --user="$VM_USER" \
    --full-user-name="Fedora Gaming Test" \
    --password-file="$VM_DIR/vm-password.txt" \
    --hostname=fedora-test \
    --time-zone=Europe/Paris \
    --locale=fr_FR.UTF-8 \
    --start-vm=headless
  echo "Install unattendue lancée (VM headless)."
  echo "Ensuite : ./test-vm.sh wait-ready   puis   ./test-vm.sh run"
}

do_status() {
  if ! "$VB" showvminfo "$VM_NAME" >/dev/null 2>&1; then
    echo "VM '$VM_NAME' : inexistante"
    return 0
  fi
  local state
  state="$("$VB" showvminfo "$VM_NAME" --machinereadable | awk -F= '/^VMState=/{gsub("\"",""); print $2}')"
  echo "VM '$VM_NAME' : $state"
  if port_open; then echo "SSH (port $SSH_PORT) : joignable"; else echo "SSH (port $SSH_PORT) : non joignable"; fi
}

do_wait_ready() {
  echo "En attente du SSH de la VM (installation complète) — jusqu'à 45 min…"
  for _ in $(seq 1 90); do
    if port_open; then
      echo "SSH joignable — VM prête."
      echo "Prochaine étape : ./test-vm.sh run"
      return 0
    fi
    sleep 30
  done
  echo "Toujours pas de SSH après 45 min — vérifie : ./test-vm.sh status" >&2
  return 1
}

do_run() {
  if ! port_open; then
    echo "SSH non joignable — attends la fin de l'install : ./test-vm.sh wait-ready" >&2
    return 1
  fi
  echo "Préparation : sudo sans mot de passe (uniquement dans la VM de test)…"
  ssh_vm "echo '$VM_PW' | sudo -S sh -c 'echo \"%wheel ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/99-vmtest && chmod 440 /etc/sudoers.d/99-vmtest'" >/dev/null
  echo "Copie du projet dans la VM…"
  tar cf - -C "$PROJECT_DIR" . | ssh_vm "mkdir -p ~/fedora-gaming && tar xf - -C ~/fedora-gaming"
  echo "Lancement de install.sh dans la VM (long — plusieurs minutes)…"
  ssh_vm "cd ~/fedora-gaming && ASSUME_YES=1 bash install.sh"
  echo "Terminé — vérifie avec : ./test-vm.sh ssh \"bash ~/fedora-gaming/doctor.sh\""
}

do_ssh() {
  exec ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$VM_USER@127.0.0.1" "$@"
}

do_destroy() {
  "$VB" controlvm "$VM_NAME" poweroff 2>/dev/null || true
  sleep 3
  "$VB" unregistervm "$VM_NAME" --delete 2>/dev/null || true
  rm -rf "$VM_DIR/vm-password.txt" "$VM_DIR/askpass.sh"
  echo "VM supprimée. ISO conservée dans $ISO_DIR (rm -rf pour la retirer)."
}

case "${1:-}" in
  download)   do_download ;;
  create)     do_create ;;
  status)     do_status ;;
  wait-ready) do_wait_ready ;;
  run)        do_run ;;
  ssh)        shift; do_ssh "$@" ;;
  destroy)    do_destroy ;;
  *)
    grep -E '^#' "$0" | grep -E 'test-vm.sh ' | sed 's/^#* *//' ; exit 1 ;;
esac
