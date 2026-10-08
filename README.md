# 🎮 fedora-gaming — Fedora KDE taillée gaming, dev & quotidien

> **Dépôt : <https://github.com/ghermetz/OS-fedora-gaming>** — pour déployer sur une machine :
> ```bash
> git clone https://github.com/ghermetz/OS-fedora-gaming.git
> cd OS-fedora-gaming && bash install.sh
> ```

> Nouveau départ (v2), base choisie ensemble : **Fedora de base**, édition **KDE Plasma**.
> Taillé pour ta machine :
>
> | Composant | Matériel | Ce qu'on en fait |
> |---|---|---|
> | CPU | AMD Ryzen 7 3800X (8c/16t) | Tout est binaire, zéro compilation |
> | GPU | AMD Radeon RX 7600 XT 16 Go (RDNA3) | Mesa + noyau récents à chaque sortie Fedora, LACT (ventilos/OC), VRR multi-écrans |
> | RAM | 32 Go | GameMode, zram (Fedora l'active par défaut) |
> | Stockage | 2,73 To (Windows ~1,46 To) | **Dual-boot** : ~1,2 To libérés pour Fedora |

## 1. Pourquoi Fedora KDE (et pas Bazzite/Arch/Ubuntu/openSUSE)

- **Ton choix assumé** : Fedora de base, pas l'immuable Bazzite.
- **L'édition KDE Plasma** est une édition officielle de Fedora (pas un dérivé) : même socle, mêmes dépôts, mêmes mises à jour que Workstation — juste le bureau Plasma, qui coche tes critères (barre des tâches façon Windows, VRR par écran, tearing, customisation).
- **Ta frayeur des mises à jour** (retour d'expérience CachyOS) : Fedora sort une version tous les **6 mois** (F44 = avril 2026, support jusqu'à juin 2027). Entre deux, tu mets à jour **quand tu veux** (`dnf upgrade`), et la montée de version se fait en une commande, quand TU décides. Tu peux même en sauter une.
- **Secure Boot peut rester activé** : Fedora est signé (contrairement à CachyOS) — un dual-boot Windows encore plus simple.
- **AMD 100 % natif** : le pilote est dans le noyau + Mesa, rien à installer, toujours à jour avec le système.

## 2. Ce que `install.sh` met en place

| Élément | Rôle |
|---|---|
| RPM Fusion (free + nonfree) | Dépôts indispensables : Steam, codecs, ffmpeg |
| Drivers AMD/Vulkan | Présents d'origine — on ajoute juste les outils de diagnostic (vulkan-tools, VAAPI) |
| Steam + GameMode + MangoHud + Gamescope | La base gaming (config MangoHud fournie, toggle Maj droite + F12) |
| LACT (COPR officiel) | Courbes ventilos, OC, limite de puissance de la 7600 XT |
| ProtonUp-Qt (Flatpak) | Installer GE-Proton |
| **Wine (dernière stable WineHQ) + Lutris + Heroic + Bottles** | Jeux Windows hors Steam : Epic/GOG/Amazon (Heroic), installateurs (Lutris), préfixes isolés (Bottles) |
| **Ruffle** | Émulateur Flash moderne — lance les jeux web Flash (Naruto Online) sans Windows |
| **ZCode** | Agent de développement Z.ai (rpm officiel) |
| **WinBoat** (rpm officiel) | Vraies applis Windows (Office…) intégrées au bureau — VM Docker/KVM, voir §6 |
| **Waydroid + GAPPS + libndk** | Android en fenêtre, Play Store, applis ARM |
| Vesktop (Flatpak) | Discord avec partage d'écran et son |
| **Netflix** | Edge (repo Microsoft) + raccourci « mode application » → 1080p max (limite DRM Linux) |
| Jellyfin Media Player (Flatpak) | Client officiel |
| VS Code (repo Microsoft) + Distrobox | Dev |
| RetroArch | Rétrogaming (cœurs à télécharger dans l'app) |

### Naruto Online (ton launcher Windows)

Le dossier `Naruto Online` que tu as fourni est un **launcher .NET 4.5.2 embarquant Chromium 75 + Flash Player** (CEF de 2019) qui charge le jeu depuis `gamebox3.narutowebgame.com`.

> ⚠️ **Le bug connu** : sous Wine, ce type de launcher s'ouvre mais reste **noir** — le processus GPU du Chromium embarqué plante sous Wine, donc rien ne se dessine. Ce n'est pas le jeu qui est cassé, c'est le rendu. Les remèdes sont intégrés au projet.

Trois routes, dans l'ordre — le script `apps/naruto-online.sh` automatise les deux premières :

1. **Ruffle** (`./naruto-online.sh ruffle`) : l'émulateur Flash moderne, rendu **natif Linux** — aucun Wine, donc aucun écran noir possible. À tester en premier.
2. **Bottles** (`./naruto-online.sh setup <dossier>` puis `run`) : bouteille dédiée + `dotnet452` + **rendu logiciel forcé** (`d3d11/dxgi` désactivés, `LIBGL_ALWAYS_SOFTWARE=1`) — l'anti-écran-noir du CEF.
3. **WinBoat** : le launcher dans une vraie VM Windows — la route garantie si les deux premières échouent.

Les routes 1 et 2 se valident dans la VM de test (Flash et .NET n'exigent pas de GPU).
| LibreOffice + Thunderbird | Bureautique |
| Docker CE (repo officiel) | Prérequis WinBoat + dev |

> ⚠️ **pamac n'existe pas sur Fedora** (c'est un outil Manjaro/Arch). L'équivalent ici : **Discover** (déjà intégré à Plasma, gère aussi les Flatpaks) + `dnf` en ligne de commande. Si pamac est rédhibitoire pour toi, dis-le-moi — c'est LE point où Fedora diffère d'Arch.

Options du script :

```bash
bash install.sh                  # parcours complet
ASSUME_YES=1 bash install.sh     # sans aucune question
bash install.sh --vanilla        # Waydroid sans Google Apps
bash install.sh --skip-waydroid  # sans la partie Android
bash install.sh --skip-winboat   # sans WinBoat
bash install.sh --skip-desktop   # sans la personnalisation du bureau
bash install.sh --extras         # + OBS, Kdenlive, GIMP, VLC, qBittorrent
```

## 3. Le rythme des mises à jour (ta vraie question)

- **Au quotidien** : `sudo dnf upgrade` une fois par semaine ou par mois, comme tu veux. Rien n'est imposé, rien ne casse si tu sautes quelques semaines.
- **Tous les 6 mois** : montée de version (F44 → F45) via `dnf system-upgrade` — ~30 min, réversible, et tu peux rester une version de moins sans souci (support ~13 mois).
- **Ton GPU est le seul point qui exige de la fraîcheur** : une RX 7600 XT aime un Mesa/noyau récents. Sur Fedora ils suivent automatiquement (les mises à jour de Mesa arrivent dans le cycle normal), donc un `dnf upgrade` mensuel suffit largement.
- **Roadmap ceinture de sécurité** : Fedora installe en Btrfs — on peut ajouter Snapper + rollback GRUB pour revenir en 1 clic à l'état d'avant une mise à jour (comme openSUSE). À faire ensemble après la première install (§9).

## 4. Installation pas à pas (dual-boot)

0. **Sauvegarde** de tes données.
1. **Côté Windows** : désactive le démarrage rapide (Panneau de config → Options d'alimentation) ; vérifie **BitLocker** (`Manage-bde -status`, note la clé de récupération) ; horloge double-boot en PowerShell admin :
   ```
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
   ```
2. Libère l'espace : Gestion des disques (`diskmgmt.msc`) → C: → **Réduire** d'environ **1 200 000 Mo** (selon ton espace libre réel). Laisse en non alloué.
3. **Recommandé avant la vraie machine** : teste tout dans VirtualBox d'abord (§7).
4. ISO **Fedora KDE Plasma 44** : <https://fedoraproject.org/spins/kde/download> — clé USB avec **Ventoy** (mets aussi le dossier `fedora-gaming` dessus), sinon Rufus/balenaEtcher.
5. Boot UEFI — **Secure Boot peut rester activé**.
6. Installeur Anaconda : partitionnement manuel conseillé :

   | Partition | Taille | FS | Point de montage | Rôle |
   |---|---|---|---|---|
   | ESP Windows existante | — | EFI System | /boot/efi | démarrage du double-boot |
   | Nouvelle | 300 Gio | BTRFS | / | système |
   | Nouvelle | le reste (~900 Gio) | BTRFS | /home | jeux + données |

   (Fedora crée le swap en zram tout seul.)
7. Premier boot — récupère le projet et lance-le :
   ```bash
   git clone https://github.com/ghermetz/OS-fedora-gaming.git
   cd OS-fedora-gaming && bash install.sh
   ```
   (ou depuis la clé USB : `bash /run/media/$USER/*/fedora-gaming/install.sh`)
8. **Redémarre**, puis : `bash doctor.sh`

## 5. Au quotidien

- **Steam** : options de lancement par jeu → `gamemoderun mangohud %command%` ; GE-Proton via ProtonUp-Qt. Compat : <https://www.protondb.com>
- **Jeux hors Steam** : Heroic (Epic/GOG/Amazon), Lutris, Bottles. Rétro : RetroArch.
- **Logiciels** : Discover (GUI) ou `sudo dnf install <paquet>`.
- **FreeSync/VRR multi-écrans** : Paramètres système → Écran et moniteur → Adaptive Sync « Toujours » sur l'écran **principal** uniquement + souris en accélération « Plate ». Le script `desktop/setup-desktop.sh` te l'affiche aussi.
- **Limites connues** : jeux à anti-cheat noyau (Valorant, Fortnite, CoD…) → reste sur Windows (dual-boot). Netflix 1080p max sous Linux (DRM).

## 6. WinBoat — les vraies applis Windows

VM Windows 11 dans Docker/KVM, apps intégrées au bureau via FreeRDP. Prérequis (installés par le script) : Docker CE + plugin compose, FreeRDP, **SVM/KVM actif dans le BIOS**, groupe `docker` (effectif après reconnexion), **licence Windows**, ~32 Go de disque. Bugs Fedora connus et suivis en amont : conflit de fichiers rpm (#284) et création de conteneur sur F44 (#855) — le script installe le dernier rpm et t'avertit proprement si ça coince.

## 7. Test dans VirtualBox AVANT la vraie machine

`vm-test/test-vm.sh` automatise : téléchargement de l'ISO Fedora KDE → création d'une VM (4 vCPU, 8 Go, 60 Go, EFI) → installation sans intervention → exécution de `install.sh` dans la VM via le dossier partagé du projet.

```bash
cd vm-test
./test-vm.sh download   # télécharge l'ISO (~2,5 Go)
./test-vm.sh create     # crée la VM et lance l'install unattendue (15-25 min)
./test-vm.sh status     # état de la VM
./test-vm.sh run        # copie le projet + lance install.sh dans la VM
./test-vm.sh ssh        # main dans la VM (mot de passe : osgaming2026)
./test-vm.sh destroy    # supprime VM + disque
```

**Ce que la VM valide** : dépôts (RPM Fusion, COPR, Docker, Microsoft), noms de paquets, codecs, logique du script, bureau Plasma, services. **Ce qu'elle ne peut pas valider** : les perfs GPU (pas de RX 7600 XT passée dans VirtualBox), VRR et le gaming réel — ça, seul ton matériel le dira.

## 8. Arborescence

```
fedora-gaming/
├── README.md                  ← ce fichier
├── install.sh                 ← bootstrap post-install Fedora
├── doctor.sh                  ← diagnostic de santé
├── config/
│   ├── mangohud/MangoHud.conf
│   └── netflix/netflix.svg
├── desktop/
│   └── setup-desktop.sh       ← look KDE + réglages gaming
└── vm-test/
    └── test-vm.sh             ← banc d'essai VirtualBox
```

## 9. Roadmap (à décider ensemble)

- [ ] Snapper + rollback GRUB (retour arrière post-mise à jour, façon openSUSE)
- [ ] Affiner le profil dev (Distrobox : conteneurs Ubuntu/Debian dans un terminal)
- [ ] Profil d'écran multi-écrans (VRR principal) à valider sur ton vrai matériel
- [ ] ISO personnalisée si tu veux réinstaller « ton OS » en une clé
- [ ] OBS/Kdenlive si tu te mets au stream/montage (`--extras`)

## 10. Sources

- [Fedora 44 (annonce)](https://fedoramagazine.org/announcing-fedora-linux-44) — [téléchargement KDE](https://fedoraproject.org/spins/kde/download)
- [RPM Fusion](https://rpmfusion.org) — [quick-start codecs Fedora](https://rpmfusion.org/Howto/Multimedia)
- [LACT](https://github.com/ilya-zlobintsev/LACT) (COPR `ilyaz/LACT`) — [WinBoat](https://winboat.app) ([rpm releases](https://github.com/winboat-org/winboat/releases))
- [Lutris (dépôts Fedora)](https://lutris.net/downloads) — [Waydroid](https://docs.waydro.id) — [ProtonDB](https://www.protondb.com)
