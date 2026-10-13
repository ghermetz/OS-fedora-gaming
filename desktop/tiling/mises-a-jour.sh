#!/bin/bash
# fedora-gaming — nombre de mises à jour disponibles (système + Flatpak).
# Invisible quand tout est à jour. Clic : Discover, onglet Mises à jour.
rpm=$(pkcon get-updates -p 2>/dev/null | grep -cE '^(Amélioration|Disponible|Sécurité|Correctif|Normal|Important|Enhancement|Bug fix|Security|Available)')
fp=$(flatpak remote-ls --updates --columns=application 2>/dev/null | grep -c .)
n=$((rpm+fp))
if [ "$n" -gt 0 ]; then
    printf '{"text":"\\uf021 %s","tooltip":"%s mises à jour disponibles\\n(système : %s · Flatpak : %s)\\n\\nClic : ouvrir les mises à jour"}\n' "$n" "$n" "$rpm" "$fp"
else
    echo '{"text":""}'
fi
