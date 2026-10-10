#!/bin/sh
# fedora-gaming — aide-mémoire des raccourcis (bouton « ? » de waybar, Super+F1)
# Niri a son propre panneau d'aide ; Sway affiche le texte ci-dessous.
if [ -n "$NIRI_SOCKET" ]; then
  exec niri msg action show-hotkey-overlay
fi
exec kdialog --title "Raccourcis — session Sway (mode Windows)" \
  --geometry 640x620 --textbox "$HOME/.config/fedora-gaming/aide-sway.txt"
