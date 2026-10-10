#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — iso/build-iso.sh
#  Construit l'ISO Live « Fedora Gaming 44 » avec KIWI, l'outil officiel de
#  Fedora : l'ISO Fedora KDE officielle + nos ajouts (iso/kiwi/).
#
#  Contenu : Plasma façon Windows 11 allégé, sessions Sway et Niri prêtes à
#  l'emploi, Steam/Wine/Lutris/GameMode/MangoHud, Naruto Online préconfiguré
#  (installation au 1er clic), français/AZERTY. Au 1er démarrage du système
#  installé, un assistant propose install.sh pour le reste (Flatpaks, LACT…).
#
#  Installation depuis la session live : partitionnement MANUEL dans
#  l'installeur → le dual-boot Windows est préservé (rien n'est effacé d'office).
#
#  Prérequis : un Fedora (la VM de test convient), ~25 Go libres, Internet.
#  Hôte plus ancien que Fedora 44 → construction automatique dans un
#  conteneur Fedora 44 (podman ou docker) : le rpm de l'hôte doit être au
#  moins aussi récent que celui de l'image.
#    bash iso/build-iso.sh            # → iso/output/Fedora-Gaming-44-x86_64.iso
# ============================================================================
set -euo pipefail

RELEASE=44
PROFILE="KDE-Desktop-Live-Gaming"
ISO_NAME="Fedora-Gaming-${RELEASE}-x86_64.iso"
ISO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$ISO_DIR")"
WORK="${FG_ISO_WORK:-/var/tmp/fedora-gaming-iso}"   # hors du projet (gros volumes, root)
OUT="$ISO_DIR/output"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m[✘] %s\033[0m\n' "$*" >&2; exit 1; }

[ -f /etc/fedora-release ] || die "Construction prévue sur Fedora (la VM de test convient)."

if [ "${FG_IN_CONTAINER:-0}" != "1" ]; then
  [ "$(id -u)" -eq 0 ] && die "Lance-le en utilisateur normal (sudo sera demandé)."
  HOST_VER="$(rpm -E %fedora)"
  if [ "$HOST_VER" -lt "$RELEASE" ]; then
    CT="$(command -v podman || command -v docker || true)"
    [ -n "$CT" ] || die "Fedora $HOST_VER < $RELEASE : installe podman (sudo dnf install podman)."
    log "Hôte Fedora $HOST_VER → construction dans un conteneur Fedora $RELEASE ($(basename "$CT"))"
    sudo mkdir -p "$WORK"
    mkdir -p "$OUT"
    # /var/tmp de l'hôte : KIWI y prépare l'EFI avec des étiquettes SELinux que
    # le système de fichiers interne du conteneur refuse.
    exec sudo "$CT" run --rm --privileged --net=host -v /dev:/dev \
      -v "$PROJECT_DIR:$PROJECT_DIR:ro" -v /var/tmp:/var/tmp -v "$OUT:$OUT" \
      -e FG_IN_CONTAINER=1 -e FG_ISO_WORK="$WORK" -e FG_OWNER="$(id -u):$(id -g)" \
      "registry.fedoraproject.org/fedora:$RELEASE" bash "$ISO_DIR/build-iso.sh"
  fi
fi

# Dans le conteneur on est root (pas de sudo) ; sur l'hôte on passe par sudo
SUDO=sudo; [ "$(id -u)" -eq 0 ] && SUDO=
OWNER="${FG_OWNER:-$(id -u):$(id -g)}"

log "1/5 — Outils KIWI"
$SUDO dnf install -y kiwi-cli kiwi-systemdeps distribution-gpg-keys git rsync
[ -f "/usr/share/distribution-gpg-keys/fedora/RPM-GPG-KEY-fedora-${RELEASE}-primary" ] \
  || die "Clés Fedora ${RELEASE} absentes : dnf upgrade distribution-gpg-keys"

log "2/5 — Descriptions officielles Fedora ${RELEASE} (fedora-kiwi-descriptions)"
$SUDO rm -rf "$WORK/desc" "$WORK/out" "$WORK/out-build"
$SUDO mkdir -p "$WORK"
$SUDO git clone -q --depth 1 -b "f${RELEASE}" \
  https://forge.fedoraproject.org/releng/fedora-kiwi-descriptions.git "$WORK/desc"
cd "$WORK/desc"

log "3/5 — Ajout du profil fedora-gaming"
$SUDO cp "$ISO_DIR/kiwi/fedora-gaming.xml" components/fedora-gaming.xml
# Fedora.kiwi → FedoraGaming.kiwi : français, AZERTY, Paris, + notre profil
sed -e 's|<locale>en_US</locale>|<locale>fr_FR</locale>|' \
    -e 's|<keytable>us</keytable>|<keytable>fr</keytable>|' \
    -e 's|<timezone>UTC</timezone>|<timezone>Europe/Paris</timezone>|' \
    -e 's|\(\s*\)<include from="this://./teams/kde.xml"/>|&\n\1<include from="this://./components/fedora-gaming.xml"/>|' \
    Fedora.kiwi | $SUDO tee FedoraGaming.kiwi >/dev/null
grep -q 'components/fedora-gaming.xml' FedoraGaming.kiwi || die "Inclusion du profil impossible (Fedora.kiwi a changé ?)"
# Nos réglages à la fin du config.sh officiel — AVANT son « exit 0 » final
$SUDO sed -i '$ {/^exit 0$/d}' config.sh
{ cat "$ISO_DIR/kiwi/config-gaming.sh"; echo; echo "exit 0"; } | $SUDO tee -a config.sh >/dev/null
grep -q "fedora-gaming : configuration" config.sh || die "Ajout de la configuration impossible"
# Le projet entier dans l'image : /usr/share/fedora-gaming (overlay root/)
$SUDO mkdir -p root/usr/share/fedora-gaming
$SUDO rsync -a --exclude .git --exclude 'iso/output' --exclude 'vm-test' --exclude NUL \
  "$PROJECT_DIR/" root/usr/share/fedora-gaming/
$SUDO chown -R root:root root/usr/share/fedora-gaming

log "4/5 — Construction (30-60 min selon la connexion)"
$SUDO ./kiwi-build --kiwi-file=FedoraGaming.kiwi --image-type=iso \
  --image-profile="$PROFILE" --output-dir "$WORK/out"

log "5/5 — Résultat"
iso="$($SUDO find "$WORK/out-build" -maxdepth 1 -name '*.iso' | head -1)"
[ -n "$iso" ] || die "Pas d'ISO produite — voir $WORK/out-build/build/image-root.log"
mkdir -p "$OUT"
$SUDO cp "$iso" "$OUT/$ISO_NAME"
( cd "$OUT" && sha256sum "$ISO_NAME" | $SUDO tee "$ISO_NAME.sha256" >/dev/null )
$SUDO chown "$OWNER" "$OUT" "$OUT/$ISO_NAME" "$OUT/$ISO_NAME.sha256"
echo
echo "✅ $OUT/$ISO_NAME ($(du -h "$OUT/$ISO_NAME" | cut -f1))"
echo "   Clé USB : Fedora Media Writer, ou  sudo dd if=$ISO_NAME of=/dev/sdX bs=4M status=progress oflag=sync"
echo "   Nettoyage : sudo rm -rf $WORK"
