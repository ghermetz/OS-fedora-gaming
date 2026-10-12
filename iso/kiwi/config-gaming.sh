#!/bin/bash
# ============================================================================
#  fedora-gaming — iso/kiwi/config-gaming.sh
#  Ajouté à la fin du config.sh officiel de KIWI (exécuté dans l'image, en
#  chroot, sans réseau) : pose les réglages fedora-gaming à partir du projet
#  copié dans /usr/share/fedora-gaming par build-iso.sh.
# ============================================================================
if [[ "$kiwi_profiles" == *"Gaming"* ]]; then
	echo "fedora-gaming : configuration de l'image…"
	export FG_IMAGE_BUILD=1
	FG=/usr/share/fedora-gaming
	# Les scripts peuvent perdre le bit exécutable (dépôt cloné sous Windows) :
	# l'icône Naruto Online et l'assistant de 1re connexion les lancent directement.
	find "$FG" -name '*.sh' -exec chmod 755 {} +

	# Plasma façon Windows 11, allégé, Naruto Online préconfiguré
	bash "$FG/desktop/setup-desktop.sh" --system

	# Session Niri façon Windows : configurations dans /etc/skel (chaque nouveau compte)
	HOME=/etc/skel bash "$FG/desktop/setup-tiling.sh"

	# Première connexion : proposer de terminer la configuration (install.sh)
	install -D -m 644 "$FG/desktop/firstrun/fedora-gaming-firstrun.desktop" /etc/xdg/autostart/fedora-gaming-firstrun.desktop
	install -D -m 644 "$FG/desktop/firstrun/fedora-gaming-finish.desktop" /usr/share/applications/fedora-gaming-finish.desktop

	# Français + clavier AZERTY + heure de Paris (session live et système installé)
	echo 'LANG=fr_FR.UTF-8' > /etc/locale.conf
	printf 'KEYMAP=fr\nFONT=eurlatgr\n' > /etc/vconsole.conf
	mkdir -p /etc/X11/xorg.conf.d
	cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<'XKB'
Section "InputClass"
	Identifier "system-keyboard"
	MatchIsKeyboard "on"
	Option "XkbLayout" "fr"
EndSection
XKB
	ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

	# Réglages jeu (sysctl) — repris de l'ancienne ISO
	cat > /etc/sysctl.d/99-gaming.conf <<'SYSCTL'
vm.max_map_count=2147483642
SYSCTL
	systemctl enable fstrim.timer 2>/dev/null || true

	# GRUB : la construction (KIWI en conteneur) laisse dans grubenv un « blsdir »
	# pointant vers le dossier de build. Copié tel quel par l'installeur, il rend
	# le système installé non démarrable (GRUB ne voit aucune entrée Fedora et
	# n'affiche que « UEFI Firmware Settings »). On le supprime.
	if [ -f /boot/grub2/grubenv ]; then
		grub2-editenv /boot/grub2/grubenv unset blsdir 2>/dev/null || sed -i '/^blsdir=/d' /boot/grub2/grubenv
	fi
fi
