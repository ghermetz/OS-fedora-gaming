#!/usr/bin/env bash
# ============================================================================
#  fedora-gaming — doctor.sh
#  Contrôle de santé de l'installation Fedora : drivers, gaming, applications,
#  Waydroid, WinBoat, système. À lancer à tout moment : bash doctor.sh
# ============================================================================
set -uo pipefail

ok()   { printf ' \033[1;32m✔\033[0m %s\n' "$*"; }
bad()  { printf ' \033[1;31m✘\033[0m %s\n' "$*"; }
note() { printf '    · %s\n' "$*"; }

check_rpm() {
  if rpm -q "$1" >/dev/null 2>&1; then ok "$1"; else bad "$1 (manquant)"; fi
}
check_flat() {
  if flatpak info "$1" >/dev/null 2>&1; then ok "$1"; else bad "$1 (manquant)"; fi
}

echo "════════ fedora-gaming doctor ════════"

echo "— Dépôts / Drivers / Vulkan"
check_rpm rpmfusion-free-release
check_rpm rpmfusion-nonfree-release
check_rpm langpacks-fr
check_rpm mesa-dri-drivers
check_rpm mesa-vulkan-drivers
if command -v vulkaninfo >/dev/null 2>&1; then
  if vulkaninfo --summary 2>/dev/null | grep -q 'deviceName'; then
    ok "Vulkan opérationnel :"
    vulkaninfo --summary 2>/dev/null | grep -E 'deviceName|driverName' | sed 's/^/    /'
  else
    bad "Vulkan : aucun périphérique détecté (redémarrer ?)"
  fi
else
  bad "vulkaninfo absent (vulkan-tools)"
fi

if command -v vainfo >/dev/null 2>&1; then
  if vainfo 2>/dev/null | grep -q 'VAProfileH264'; then
    ok "décodage vidéo matériel H.264 (VA-API)"
  else
    bad "pas de décodage matériel H.264 → sudo dnf install mesa-va-drivers-freeworld"
  fi
fi

echo "— Gaming"
for p in steam gamemode mangohud gamescope lact wine winetricks lutris; do
  check_rpm "$p"
done
if systemctl is-enabled --quiet fstrim.timer 2>/dev/null; then
  ok "fstrim.timer activé (SSD)"
else
  bad "fstrim.timer inactif"
fi
if id -nG "$USER" 2>/dev/null | grep -qw gamemode; then
  ok "utilisateur dans le groupe gamemode (CPU en mode performance en jeu)"
else
  bad "pas dans le groupe gamemode → sudo usermod -aG gamemode $USER (puis se reconnecter)"
fi
if systemctl is-active --quiet lactd 2>/dev/null; then
  ok "lactd (daemon LACT) actif"
else
  note "lactd inactif — lance 'lact gui' pour configurer le GPU"
fi

echo "— Applications (rpm)"
for p in microsoft-edge-stable code distrobox retroarch libreoffice-core thunderbird; do
  check_rpm "$p"
done

echo "— Applications (Flatpak)"
for app in dev.vencord.Vesktop org.jellyfin.JellyfinDesktop \
  com.usebottles.bottles com.heroicgameslauncher.hgl net.davidotek.pupgui2; do
  check_flat "$app"
done
if [ -f "$HOME/.local/share/applications/netflix.desktop" ]; then
  ok "raccourci Netflix"
else
  bad "raccourci Netflix absent"
fi

echo "— Waydroid"
if rpm -q waydroid >/dev/null 2>&1; then
  ok "waydroid"
  if systemctl is-active --quiet waydroid-container 2>/dev/null; then
    ok "waydroid-container actif"
  else
    note "waydroid-container inactif (démarre via l'application Waydroid)"
  fi
  if [ -f /var/lib/waydroid/waydroid.cfg ]; then
    ok "image Android présente"
  else
    note "pas d'image Android → sudo waydroid init -s GAPPS -c https://ota.waydro.id/system -v https://ota.waydro.id/vendor"
  fi
else
  bad "waydroid absent"
fi

echo "— WinBoat / Docker"
check_rpm freerdp
if rpm -q docker-ce >/dev/null 2>&1; then
  ok "docker-ce"
else
  bad "docker-ce absent"
fi
if systemctl is-enabled --quiet docker.socket 2>/dev/null; then
  ok "Docker à la demande (docker.socket)"
elif rpm -q docker-ce >/dev/null 2>&1; then
  note "Docker démarre avec le système → sudo systemctl disable docker.service && sudo systemctl enable docker.socket"
fi
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  ok "KVM accessible (/dev/kvm)"
else
  bad "KVM inaccessible : activer SVM / VT-x dans le BIOS"
fi
if rpm -q winboat >/dev/null 2>&1; then
  ok "winboat"
else
  note "winboat absent (--skip-winboat ?)"
fi
if id -nG "$USER" 2>/dev/null | grep -qw docker; then
  ok "utilisateur dans le groupe docker"
else
  note "pas encore dans le groupe docker (déconnexion/reconnexion requise)"
fi

echo "— Bureau"
for f in /usr/share/fedora-gaming/apps/naruto-online.sh \
         /usr/share/fedora-gaming/desktop/firstrun/fedora-gaming-firstrun.sh; do
  [ -e "$f" ] || continue
  if [ -x "$f" ] || grep -q "Exec=bash $f" /usr/share/applications/*.desktop /etc/xdg/autostart/*.desktop 2>/dev/null; then
    ok "$(basename "$f") lançable"
  else
    bad "$(basename "$f") non exécutable → sudo chmod 755 $f"
  fi
done
if failed="$(systemctl --user --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | xargs)" && [ -n "$failed" ]; then
  bad "services utilisateur en échec : $failed"
else
  ok "aucun service utilisateur en échec"
fi
if timedatectl show -p LocalRTC --value 2>/dev/null | grep -q yes; then
  note "horloge matérielle en heure locale (réglage Windows par défaut) — voir README, dual-boot"
fi

echo "— Système"
# shellcheck disable=SC1091
. /etc/os-release
note "OS : ${PRETTY_NAME:-inconnu}"
note "Noyau : $(uname -r)"
if command -v lspci >/dev/null 2>&1; then
  lspci | grep -iE 'vga|3d' | sed 's/^/    /'
fi
free -h | awk '/^Mem:/{printf "    RAM totale : %s\n", $2}'
df -h / | awk 'NR==2{printf "    Disque / : %s utilisés sur %s\n", $3, $2}'

echo "════════ Fin du diagnostic ════════"
