#!/usr/bin/env bash
# fedora-gaming — iso/build-iso.sh
# Construction de l'ISO custom Fedora Gaming 44 KDE
set -euo pipefail

ISO_NAME="Fedora-Gaming-44-KDE-x86_64.iso"
KS_FILE="$(dirname "$0")/fedora-gaming.ks"
FEDORA_ISO_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/44/Spins/x86_64/iso/Fedora-KDE-Live-x86_64-44.iso"
FEDORA_ISO="Fedora-KDE-Live-x86_64-44.iso"
WORK_DIR="$(dirname "$0")/work"
OUTPUT_DIR="$(dirname "$0")/output"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { echo "ERREUR: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && die "Ne lance pas en root (utilisera sudo au besoin)"

log "1/5 — Vérification des outils"
if command -v mkksiso >/dev/null 2>&1; then
  METHOD="mkksiso"
  log "Méthode : mkksiso (modification ISO existant)"
elif command -v livecd-creator >/dev/null 2>&1; then
  METHOD="livecd-creator"
  log "Méthode : livecd-creator (build complet)"
elif command -v livemedia-creator >/dev/null 2>&1; then
  METHOD="livemedia-creator"
  log "Méthode : livemedia-creator (Lorax)"
else
  die "Aucun outil de build ISO trouvé. Installe : sudo dnf install -y lorax livecd-tools"
fi

log "2/5 — Téléchargement ISO Fedora KDE base"
mkdir -p "$WORK_DIR" "$OUTPUT_DIR"
cd "$WORK_DIR"

if [ ! -f "$FEDORA_ISO" ]; then
  echo "Téléchargement $FEDORA_ISO (~2.5 GB)..."
  wget -c "$FEDORA_ISO_URL" -O "$FEDORA_ISO" || \
    curl -C - -L -o "$FEDORA_ISO" "$FEDORA_ISO_URL"
else
  echo "ISO base déjà téléchargée : $FEDORA_ISO"
fi

log "3/5 — Vérification checksum (optionnel)"
# Optionnel : wget checksum et vérifier
echo "Skipping checksum verification (optionnel)"

log "4/5 — Construction de l'ISO custom"

case "$METHOD" in
  mkksiso)
    log "Utilisation de mkksiso (rapide, recommandé)"
    sudo mkksiso \
      --ks "$KS_FILE" \
      --volid "Fedora-Gaming-44" \
      "$FEDORA_ISO" \
      "$OUTPUT_DIR/$ISO_NAME"
    ;;

  livecd-creator)
    log "Utilisation de livecd-creator (build complet)"
    sudo livecd-creator \
      --config="$KS_FILE" \
      --fslabel="Fedora-Gaming-44" \
      --product="Fedora Gaming" \
      --releasever=44 \
      --cache="$WORK_DIR/cache" \
      --tmpdir="$WORK_DIR/tmp"
    sudo mv *.iso "$OUTPUT_DIR/$ISO_NAME" 2>/dev/null || true
    ;;

  livemedia-creator)
    log "Utilisation de livemedia-creator (Lorax, lent)"
    sudo livemedia-creator \
      --make-iso \
      --ks="$KS_FILE" \
      --iso-name="$ISO_NAME" \
      --releasever=44 \
      --resultdir="$OUTPUT_DIR" \
      --tmp="$WORK_DIR/tmp"
    ;;

  *)
    die "Méthode inconnue : $METHOD"
    ;;
esac

log "5/5 — Vérification de l'ISO créée"
if [ -f "$OUTPUT_DIR/$ISO_NAME" ]; then
  SIZE=$(du -h "$OUTPUT_DIR/$ISO_NAME" | cut -f1)
  echo ""
  echo "✅ ISO créée avec succès !"
  echo "   Fichier : $OUTPUT_DIR/$ISO_NAME"
  echo "   Taille  : $SIZE"
  echo ""
  echo "Prochaines étapes :"
  echo "1. Tester l'ISO en VM : VirtualBox / virt-manager"
  echo "2. Écrire sur USB     : sudo dd if=$OUTPUT_DIR/$ISO_NAME of=/dev/sdX bs=4M"
  echo "3. Distribuer         : Upload sur GitHub releases"
else
  die "Échec de la création de l'ISO"
fi

log "Nettoyage (optionnel)"
echo "Pour nettoyer le dossier work/ : rm -rf $WORK_DIR"
