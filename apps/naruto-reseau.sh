#!/bin/bash
# fedora-gaming — apps/naruto-reseau.sh — contournement du blocage à 14 % de Naruto Online.
#
# Au chargement, le jeu demande l'adresse de ses serveurs au service DNS de
# Tencent (DNSPod HTTPDNS) à l'adresse 182.254.116.117. Depuis notre connexion,
# cette adresse coupe toutes les connexions (IO_ERROR dans debug.log, chargement
# bloqué à 14 %), alors que les autres adresses du même service répondent.
# On redirige donc 182.254.116.117 → 182.254.116.116 (même service, même réponse).
# Règle firewalld permanente, ne touche à rien d'autre.
#
# Usage : sudo bash apps/naruto-reseau.sh activer | desactiver | etat
set -e
REGLE=(ipv4 nat OUTPUT 0 -d 182.254.116.117/32 -p tcp --dport 80 -j DNAT --to-destination 182.254.116.116:80)
case "${1:-activer}" in
    activer)
        firewall-cmd --permanent --direct --query-rule "${REGLE[@]}" >/dev/null 2>&1 \
            || firewall-cmd --permanent --direct --add-rule "${REGLE[@]}"
        firewall-cmd --reload >/dev/null
        echo "Contournement activé (182.254.116.117 → 182.254.116.116)." ;;
    desactiver)
        firewall-cmd --permanent --direct --remove-rule "${REGLE[@]}" || true
        firewall-cmd --reload >/dev/null
        echo "Contournement désactivé." ;;
    etat)
        firewall-cmd --direct --query-rule "${REGLE[@]}" && echo "actif" || echo "inactif" ;;
    *) echo "Usage : sudo $0 activer | desactiver | etat"; exit 1 ;;
esac
