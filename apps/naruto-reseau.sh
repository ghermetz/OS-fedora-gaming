#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — apps/naruto-reseau.sh
#  Contournement du blocage du chargement à 14 % (IO_ERROR dans debug.log).
#
#  Au chargement, le jeu peut interroger le service DNS de Tencent (DNSPod
#  HTTPDNS) à l'adresse 182.254.116.117. Toute requête qui porte ce nom est
#  coupée en route, quelle que soit l'adresse visée, alors que le même service
#  répond sous ses autres adresses (119.29.29.29, 182.254.116.116…) : rediriger
#  l'adresse ne suffit donc pas, le nom reste dans la requête.
#
#  Ce script installe un petit relais local (naruto-httpdns.py, service
#  utilisateur « naruto-httpdns », 127.0.0.1:8117) qui transmet ces requêtes
#  au même service avec un nom correct, et une règle firewalld permanente qui
#  envoie vers lui les requêtes du jeu pour 182.254.116.117. Rien d'autre
#  n'est touché.
#
#  Validé le 13/10/2026 : deux comptes en jeu en même temps (serveurs 38 et
#  388). Si le blocage persiste, le serveur de jeu lui-même (port 6001) peut
#  être indisponible : réessayer plus tard.
#
#  Usage (sans sudo : le mot de passe est demandé pour la règle du pare-feu) :
#    bash apps/naruto-reseau.sh activer      # relais + règle du pare-feu
#    bash apps/naruto-reseau.sh desactiver   # retire tout
#    bash apps/naruto-reseau.sh etat         # vérifie que tout répond
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELAIS_SRC="$SCRIPT_DIR/naruto-httpdns.py"
RELAIS="$HOME/.local/share/naruto-online/naruto-httpdns.py"
SERVICE="$HOME/.config/systemd/user/naruto-httpdns.service"
REGLE=(ipv4 nat OUTPUT 0 -d 182.254.116.117/32 -p tcp --dport 80 -j REDIRECT --to-ports 8117)
# Première version (redirection directe vers .116), insuffisante : retirée
ANCIENNE=(ipv4 nat OUTPUT 0 -d 182.254.116.117/32 -p tcp --dport 80 -j DNAT --to-destination 182.254.116.116:80)

ok()  { printf '\033[1;32m ✔ %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m[✘] %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "Lance ce script sans sudo : le relais s'installe pour ton compte (le mot de passe sera demandé pour le pare-feu)."
command -v firewall-cmd >/dev/null || die "firewalld est nécessaire (installé par défaut sur Fedora)."

pare_feu() { sudo firewall-cmd "$@"; }

installer_relais() {
  [ -f "$RELAIS_SRC" ] || die "naruto-httpdns.py introuvable à côté de ce script"
  install -D -m 755 "$RELAIS_SRC" "$RELAIS"
  mkdir -p "$(dirname "$SERVICE")"
  cat > "$SERVICE" <<EOF
[Unit]
Description=Relais local pour le chargement de Naruto Online (DNS de Tencent)

[Service]
ExecStart=/usr/bin/python3 $RELAIS
Restart=on-failure

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now naruto-httpdns.service >/dev/null 2>&1
  systemctl --user restart naruto-httpdns.service
  ok "relais local actif (127.0.0.1:8117, service utilisateur naruto-httpdns)"
}

case "${1:-activer}" in
  activer)
    installer_relais
    pare_feu --permanent --direct --remove-rule "${ANCIENNE[@]}" >/dev/null 2>&1 || true
    pare_feu --permanent --direct --query-rule "${REGLE[@]}" >/dev/null 2>&1 \
      || pare_feu --permanent --direct --add-rule "${REGLE[@]}" >/dev/null
    pare_feu --reload >/dev/null
    ok "règle du pare-feu active (182.254.116.117 → relais local)"
    ;;
  desactiver)
    pare_feu --permanent --direct --remove-rule "${REGLE[@]}" >/dev/null 2>&1 || true
    pare_feu --permanent --direct --remove-rule "${ANCIENNE[@]}" >/dev/null 2>&1 || true
    pare_feu --reload >/dev/null
    systemctl --user disable --now naruto-httpdns.service >/dev/null 2>&1 || true
    rm -f "$SERVICE" "$RELAIS"
    systemctl --user daemon-reload
    ok "contournement retiré"
    ;;
  etat)
    systemctl --user is-active --quiet naruto-httpdns.service && ok "relais actif" || echo "relais arrêté"
    firewall-cmd --direct --query-rule "${REGLE[@]}" >/dev/null 2>&1 && ok "règle du pare-feu active" || echo "règle du pare-feu absente"
    if curl -s -m 8 -o /dev/null "http://182.254.116.117/d?dn=res.huoying.qq.com"; then
      ok "le service DNS de Tencent répond via 182.254.116.117"
    else
      echo "182.254.116.117 ne répond pas (contournement inactif ?)"
    fi
    ;;
  *) grep -E '^#    bash' "$0" | sed 's/^#  //'; exit 1 ;;
esac
