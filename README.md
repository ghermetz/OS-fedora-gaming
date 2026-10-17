# 🎮 fedora-gaming

**Fedora KDE Plasma prête pour le jeu, le développement et le quotidien, avec un bureau qui ressemble à Windows 11.**

Un script (ou une ISO) transforme une Fedora KDE fraîchement installée en système de jeu complet : Steam, Proton, Wine, Lutris, Heroic, codecs, outils AMD, Android (Waydroid), applis Windows (WinBoat)… le tout sur un Plasma allégé, réglé pour le jeu, et pensé pour quelqu'un qui vient de Windows.

> 🇫🇷 **Résumé** — Transforme une Fedora KDE fraîchement installée en système complet pour le jeu, le développement et le quotidien : Plasma allégé façon Windows 11, session légère Niri façon Windows en option, Naruto Online préconfiguré. Lancez `bash install.sh` sur Fedora KDE, ou construisez une ISO prête à installer avec `bash iso/build-iso.sh`.
>
> 🇬🇧 **Summary** — Turns a fresh Fedora KDE install into a complete gaming, development and daily-driver system: a debloated, Windows-11-like Plasma desktop, an optional lightweight, Windows-like Niri session, and a pre-configured Naruto Online launcher. Run `bash install.sh` on Fedora KDE, or build a ready-to-install live ISO with `bash iso/build-iso.sh`. The rest of the documentation is in French.

---

## Sommaire

1. [Ce que vous obtenez](#1-ce-que-vous-obtenez)
2. [Pour qui ?](#2-pour-qui-)
3. [Installation](#3-installation)
4. [Le bureau](#4-le-bureau)
5. [Logiciels installés](#5-logiciels-installés)
6. [Naruto Online](#6-naruto-online)
7. [Au quotidien et mises à jour](#7-au-quotidien-et-mises-à-jour)
8. [Tester dans une machine virtuelle](#8-tester-dans-une-machine-virtuelle)
9. [État des tests et limites](#9-état-des-tests-et-limites)
10. [Structure du projet](#10-structure-du-projet)
11. [Contribuer, feuille de route, sources](#11-contribuer-feuille-de-route-sources)

---

## Matériel de référence

Basé sur une installation actuelle sur un Ryzen 7 3800X avec RX 7600 XT :

| Composant | Modèle | Performances actuelles |
|-----------|--------|----------------------|
| CPU | AMD Ryzen 7 3800X (8c/16t) | 4559 MHz boost, 20% charge |
| RAM | 32 Go DDR4 | 23 Go disponibles |
| GPU | AMD RX 7600 XT | 45°C, 21W PPT |
| Stockage | 929 Go SSD | 854 Go disponibles |
| Kernel | 7.2.11-200.fc44.x86_64 | Uptime 29 minutes |

![Bureau Niri](https://github.com/ghermetz/OS-fedora-gaming/raw/main/screenshots/niri-bureau.png)

![Performances Niri](https://github.com/ghermetz/OS-fedora-gaming/raw/main/screenshots/niri-sysmonitor.png)

![Bureau Plasma](https://github.com/ghermetz/OS-fedora-gaming/raw/main/screenshots/plasma-sysmonitor.png)

---

## 1. Ce que vous obtenez

- **Plasma façon Windows 11** : barre des tâches centrée avec menu Démarrer et applis épinglées, thème sombre, Alt+Tab en vignettes, ouverture en un clic.
- **Un système allégé** : sans la suite de messagerie KDE ni son serveur de base de données (Akonadi + MariaDB), sans rapporteurs de plantage, sans indexation permanente des fichiers. Docker ne démarre que quand on en a besoin.
- **Le jeu prêt à l'emploi** : Steam, GameMode, MangoHud, Gamescope, Wine, Lutris, Heroic, Bottles, ProtonUp-Qt, LACT pour les cartes AMD (ventilateurs, overclocking).
- **Une session légère en bonus**, Niri, réglée pour ressembler à Windows et s'utiliser sans rien apprendre (menu Démarrer façon Mint/Zorin, barre des tâches façon Zorin OS, vue des tâches, Alt+Tab, raccourcis Windows, aide intégrée).
- **Naruto Online préconfiguré** : une icône dans le menu installe le launcher officiel au premier clic.
- **Le reste du quotidien** : Discord (Vesktop), Netflix, Jellyfin, LibreOffice, Thunderbird, VS Code, Android avec Waydroid, applis Windows avec WinBoat.

## 2. Pour qui ?

- Les joueurs qui quittent Windows et veulent un bureau familier.
- Celles et ceux qui veulent une **Fedora standard** (pas une distribution dérivée) : mêmes dépôts et mêmes mises à jour que Fedora, et Secure Boot qui reste activé.
- **Carte graphique** : les cartes AMD et Intel fonctionnent avec les pilotes intégrés à Fedora. Pour une carte **NVIDIA**, il faut en plus installer le pilote propriétaire (`akmod-nvidia` depuis RPM Fusion), que ce projet ne gère pas.

### Configuration requise

| | Minimum | Recommandé |
|---|---|---|
| Processeur | 64 bits (x86_64), 4 cœurs | 6 cœurs ou plus |
| Mémoire | 8 Go | 16 Go ou plus |
| Disque | 60 Go (plus la place des jeux) | SSD, 200 Go ou plus |
| Carte graphique | compatible Vulkan (AMD GCN ou plus récente, Intel Xe, NVIDIA avec pilote propriétaire) | AMD RDNA 2 ou plus récente |
| Démarrage | UEFI (Secure Boot peut rester activé) | |
| Réseau | connexion Internet pendant l'installation | |

Pour WinBoat (applis Windows) : virtualisation (AMD-V/SVM ou Intel VT-x) activée dans le BIOS, 16 Go de mémoire conseillés et une licence Windows.

**Pourquoi Fedora KDE ?** Une version tous les 6 mois, environ 13 mois de support, des mises à jour qu'on applique quand on veut, et un noyau et des pilotes graphiques (Mesa) récents, ce dont les cartes graphiques modernes ont besoin. KDE Plasma est une édition officielle de Fedora et le bureau Linux le plus facile à rapprocher de Windows.

## 3. Installation

Deux possibilités.

### A. Sur une Fedora KDE déjà installée (recommandé)

Installez [Fedora KDE Plasma 44](https://fedoraproject.org/kde/download), puis :

```bash
git clone https://github.com/ghermetz/OS-fedora-gaming.git
cd OS-fedora-gaming
bash install.sh
```

Comptez 30 à 60 minutes selon la connexion. Redémarrez, puis vérifiez avec `bash doctor.sh`.

Options :

```bash
ASSUME_YES=1 bash install.sh     # sans aucune question
bash install.sh --vanilla        # Waydroid sans les services Google
bash install.sh --skip-waydroid  # sans Android
bash install.sh --skip-winboat   # sans WinBoat
bash install.sh --skip-desktop   # garder son bureau Plasma tel quel
bash install.sh --skip-tiling    # sans la session Niri
bash install.sh --extras         # + OBS, Kdenlive, GIMP, VLC, qBittorrent
```

> ⚠️ `--skip-desktop` mis à part, le script **remplace la disposition de la barre Plasma** par la disposition Windows 11 et **désinstalle** la suite de messagerie KDE (KMail, KOrganizer, Akonadi…). Voir [desktop/debloat-plasma.sh](desktop/debloat-plasma.sh) pour la liste complète.

### B. Avec l'ISO fedora-gaming

> ✅ Construction, session live et installation sur disque testées en VM (ISO de 5,4 Go) : voir [l'état des tests](#9-état-des-tests-et-limites).

L'ISO est une Fedora KDE 44 Live officielle, à laquelle s'ajoutent le bureau Windows 11, la session Niri, Steam, Wine, Lutris et l'icône Naruto Online, en français avec clavier AZERTY. On la construit soi-même sur une Fedora (une machine virtuelle convient), avec l'outil officiel de Fedora, [KIWI](https://osinside.github.io/kiwi/) :

```bash
bash iso/build-iso.sh     # ~25 Go libres, environ 1 h 30 → iso/output/Fedora-Gaming-44-x86_64.iso (5,4 Go)
```

La construction se fait dans un conteneur Fedora 44 (podman ou docker) : directement sur l'hôte, elle échoue au démarrage de KIWI. Gravez ensuite l'ISO avec Fedora Media Writer, Ventoy ou `dd`.

#### Télécharger l'ISO déjà construite

Si vous ne voulez pas la construire vous-même, l'ISO est disponible ici :

- **Lien** : <https://kdrive.infomaniak.com/app/share/577121/d800b233-788f-4e53-9f52-422e7e0eeb91> (`Fedora-Gaming-44-x86_64.iso`, 5,4 Go, construite le 12 octobre 2026)
- **SHA256** : `79890e25c5a31543bdabc6c0b0ecabd5292cccf512a8a6fe02d7e629a4d700a2` ([fichier .sha256](https://kdrive.infomaniak.com/app/share/577121/4a82a069-3e0a-438d-a7b5-c19bfd5d2da5))

Avant de graver l'ISO, vérifiez que le fichier n'est pas abîmé, en comparant le résultat avec la somme ci-dessus :

```bash
sha256sum Fedora-Gaming-44-x86_64.iso                     # Linux
certutil -hashfile Fedora-Gaming-44-x86_64.iso SHA256     # Windows
```

Depuis la session live, l'installeur propose un **partitionnement manuel** : rien n'est effacé d'office, et un Windows existant est préservé. Au premier démarrage du système installé, un assistant propose de terminer la configuration (codecs, Flatpaks, LACT, VS Code, Edge, WinBoat, Waydroid), car ces éléments viennent de dépôts tiers qui ne peuvent pas être intégrés à l'ISO.

### Installer à côté de Windows (dual-boot)

1. **Sauvegardez vos données.**
2. Sous Windows :
   - désactivez le démarrage rapide (Options d'alimentation) ;
   - si BitLocker est actif (`manage-bde -status`), notez votre clé de récupération ;
   - pour que l'horloge reste juste entre les deux systèmes, lancez en PowerShell administrateur :
     ```
     reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
     ```
3. Dans Gestion des disques (`diskmgmt.msc`), **réduisez** la partition Windows pour libérer de l'espace (laissez-le « non alloué »).
4. Démarrez sur la clé en mode UEFI. **Secure Boot peut rester activé.**
5. Dans l'installeur, choisissez le partitionnement manuel. Un exemple :

   | Partition | Taille | Système de fichiers | Point de montage |
   |---|---|---|---|
   | Partition EFI de Windows (existante) | — | EFI | /boot/efi |
   | Nouvelle | 100 à 300 Gio | Btrfs | / |
   | Nouvelle | le reste | Btrfs | /home (jeux et données) |

   Fedora crée seul la mémoire d'échange (zram).
6. Après l'installation, vérifiez l'horloge avec `timedatectl` : si Windows a été passé en UTC (étape 2) mais que la ligne « RTC in local TZ » vaut `yes`, lancez `sudo timedatectl set-local-rtc 0`. Si vous n'avez pas fait l'étape 2, ne changez rien : les deux systèmes sont alors en heure locale.

## 4. Le bureau

### Plasma façon Windows 11 (bureau principal)

- Barre en bas : menu Démarrer et applis épinglées **au centre** (Dolphin, Firefox, Steam, Naruto Online, Konsole, Paramètres), barre système et horloge à droite.
- Thème sombre Breeze, icônes Papirus, couleur d'accent rouge.
- Réglages jeu : *tearing* autorisé en plein écran (utile avec le VRR/FreeSync), souris sans accélération.
- C'est un thème global Plasma (« Fedora Gaming (Windows 11) ») : on peut le réappliquer ou en changer dans *Paramètres système → Thème global*.

### Session bonus : Niri, simple et façon Windows / Zorin OS

À choisir sur l'écran de connexion (en bas à gauche, « Session de bureau »). Niri est léger (environ 0,9 Go de mémoire utilisée dans nos tests, contre environ 2 Go pour Plasma allégé) et il est réglé ici pour se comporter le plus possible comme Windows, avec l'allure de Zorin OS (barre sombre translucide, accent bleu, police Inter, ombres et coins arrondis, fond d'écran bleu) :

- **Barre des tâches** façon Zorin OS. À gauche : le **menu Démarrer**, le bouton **vue des tâches**, les **applis épinglées** (Firefox, Fichiers, Steam, Lutris ; un clic affiche l'appli si elle est déjà ouverte) et les **fenêtres ouvertes** en icônes, soulignées en bleu pour l'active. À droite : le média en cours, la charge du processeur et de la carte graphique (températures au survol), la manette de **GameMode** quand un jeu l'active, le nombre de **mises à jour**, la zone de notification, l'**éclairage nocturne**, l'anti-veille (pour un film), le volume, l'extinction, l'heure (**calendrier** au survol), les **notifications** et une fine bande **« Afficher le bureau »**.
- **Menu Démarrer façon Linux Mint / Zorin OS** : recherche instantanée (taper directement), catégories à gauche (il suffit de les survoler), applis avec leur description, **Favoris** (clic droit sur une appli pour l'ajouter ou la retirer), **Récents**, dossiers, et boutons verrouiller / se déconnecter / éteindre. Clic droit sur le bouton : menu rapide façon Win+X.
- **Centre de notifications** (SwayNotificationCenter) avec « Ne pas déranger », le média, le volume et des boutons rapides ; indicateur de volume à l'écran avec les touches multimédia.
- **Les fenêtres s'ouvrent en grand**, comme une fenêtre agrandie sous Windows. **Alt+Tab** affiche le sélecteur avec aperçus. Les applications gardent leur barre de titre, avec le bouton de fermeture et le bouton d'agrandissement.
- **Raccourcis Windows** :

  | Action | Raccourci |
  |---|---|
  | Menu Démarrer / menu rapide | Super+Espace (ou le bouton) / Super+X (ou clic droit) |
  | Vue des tâches (toutes les fenêtres, bureaux) | Super+Tab (ou le bouton, ou la souris dans le coin en haut à gauche) |
  | Changer de fenêtre | Alt+Tab |
  | Fermer | Alt+F4 |
  | Afficher le bureau (réappuyer pour revenir) | Super+D |
  | Historique du presse-papiers | Super+V |
  | Notifications | Super+N |
  | Agrandir / moitié d'écran | Super+↑ / Super+↓ |
  | Fenêtre flottante | Super+Maj+V |
  | Fenêtre vers l'écran voisin | Super+Maj+← / → |
  | Bureau virtuel suivant / précédent | Ctrl+Super+→ / Ctrl+Super+← |
  | Explorateur, paramètres, verrouiller | Super+E, Super+I, Super+L |
  | Capture d'une zone / de l'écran | Super+Maj+S / Maj+Impr |
  | Éteindre, redémarrer, se déconnecter | Ctrl+Alt+Suppr (ou le bouton ⏻) |
  | Lancement rapide au clavier | Alt+F2 |
  | Aide (en français) | Super+F1 |

- Particularité de Niri : les fenêtres sont rangées côte à côte sur une bande qui défile, plutôt que superposées. Super+← / → passe d'une fenêtre à sa voisine, et Super+↓ met deux fenêtres côte à côte. Il n'y a pas de « réduire » : on passe d'une fenêtre à l'autre avec la barre des tâches ou Alt+Tab, et Super+D affiche le bureau.
- **Plusieurs écrans** : l'ordre des écrans se règle dans `~/.config/niri/config.kdl` (exemple commenté). Steam, Wine et les jeux s'ouvrent sur l'écran « principal » : par défaut celui de gauche, ou celui dont on écrit un bout du nom (par exemple `AOC`) dans `~/.config/fedora-gaming/ecran-principal`.
- Les applis KDE (Dolphin, Konsole…) gardent leur thème Breeze sombre, leurs icônes et le menu « Ouvrir avec » hors de Plasma.

## 5. Logiciels installés

| Catégorie | Logiciels |
|---|---|
| Dépôts | RPM Fusion (free + nonfree), Flathub |
| Pilotes | AMD/Intel intégrés à Fedora (Mesa), outils Vulkan et VA-API, codecs complets (ffmpeg) |
| Jeu | Steam, GameMode, MangoHud (configuré, Maj droite + F12), Gamescope, ProtonUp-Qt (GE-Proton) |
| Carte AMD | [LACT](https://github.com/ilya-zlobintsev/LACT) : ventilateurs, overclocking, limite de puissance |
| Jeux Windows hors Steam | Wine 11, Lutris, Heroic (Epic, GOG, Amazon), Bottles |
| Applis Windows | [WinBoat](https://winboat.app) : une VM Windows dont les applis s'intègrent au bureau (licence Windows requise) |
| Android | [Waydroid](https://docs.waydro.id) avec Google Play (option `--vanilla` pour s'en passer) et traduction des applis ARM. Si le Play Store signale un appareil « non certifié », enregistrez son identifiant sur [google.com/android/uncertified](https://www.google.com/android/uncertified) ([marche à suivre](https://docs.waydro.id/faq/google-play-certification)) |
| Communication, vidéo | Vesktop (Discord avec partage d'écran et son), Netflix (via Edge, 1080p maximum sous Linux), Jellyfin |
| Bureautique, dev | LibreOffice, Thunderbird, VS Code, Distrobox, ZCode |
| Rétro, Flash | RetroArch, Ruffle (jeux Flash simples) |

> Le gestionnaire de logiciels graphique est **Discover** (paquets Fedora et Flatpaks). En ligne de commande : `sudo dnf install <paquet>`.

## 6. Naruto Online

Le launcher officiel (application .NET avec Chromium et Flash intégrés) fonctionne **sous Wine**. Le script installe aussi **DXVK** (affichage par Vulkan) : avec le Direct3D intégré à Wine, l'affichage saccade.

- Avec l'ISO ou après `install.sh`, une icône **Naruto Online** est dans le menu. Au premier clic, elle cherche l'installeur officiel (`Naruto Online_fr_….zip` ou `.exe` dans vos Téléchargements) ou le jeu sur une partition Windows. Sinon, elle demande où il se trouve, puis installe tout (5 à 30 minutes, à cause de .NET 4.8 ; dans la fenêtre de l'installeur officiel, cliquez sur « Utiliser ») et lance le jeu.
- Affichage saccadé sur une installation antérieure au 12 octobre 2026 : relancez `apps/naruto-online.sh setup`, le jeu fermé, pour ajouter DXVK.
- En ligne de commande : `apps/naruto-online.sh setup <installeur ou dossier>`, puis `apps/naruto-online.sh run`.

Le projet ne contient ni le jeu ni le launcher : vous fournissez l'installeur officiel. Détails, dépannage et fausses pistes : [docs/naruto-online.md](docs/naruto-online.md). Une version indépendante, pour toutes les distributions, existe aussi : [naruto-online-linux](https://github.com/ghermetz/naruto-online-linux).

## 7. Au quotidien et mises à jour

- **Steam** : dans les options de lancement d'un jeu, `gamemoderun mangohud %command%`. Pour la compatibilité des jeux : [ProtonDB](https://www.protondb.com).
- **FreeSync/VRR sur plusieurs écrans** : *Paramètres système → Écran et moniteur*, puis Adaptive Sync « Toujours » sur l'écran principal et « Automatique » sur les autres.
- **Mises à jour** : `sudo dnf upgrade` quand vous le voulez, par exemple une fois par mois. Rien n'est imposé et rien ne casse si vous sautez quelques semaines. Le notificateur de mises à jour est volontairement retiré.
- **Changement de version** (tous les 6 mois, par exemple 44 → 45) : `dnf system-upgrade`, environ 30 minutes. On peut rester une version en arrière sans souci.

## 8. Tester dans une machine virtuelle

Avant de toucher à votre vrai PC, `vm-test/` automatise une VM VirtualBox : création, installation de Fedora sans intervention, puis exécution d'`install.sh` dans la VM.

```bash
# Linux / macOS                  # Windows (PowerShell)
cd vm-test                       cd vm-test
./test-vm.sh download            .\test-vm.ps1 download
./test-vm.sh create              .\test-vm.ps1 create
./test-vm.sh wait-ready          .\test-vm.ps1 wait-ready
./test-vm.sh run                 .\test-vm.ps1 run
./test-vm.sh ssh                 .\test-vm.ps1 ssh
./test-vm.sh destroy             .\test-vm.ps1 destroy
```

Identifiants de la VM de test : `guill` / `osgaming2026`, modifiables avec les variables `VM_USER` et `VM_PW`. La VM est en NAT et n'est pas exposée au réseau.

## 9. État des tests et limites

Le rapport détaillé, avec chaque problème trouvé et sa correction, est dans [docs/TESTS.md](docs/TESTS.md).

**Testé dans une VM Fedora 43 KDE** (VirtualBox, avec et sans accélération 3D) :
- `install.sh` complet et `doctor.sh` sans erreur ;
- l'allègement de Plasma et la disposition Windows 11 ;
- la session Niri (clavier et souris, applis X11) ;
- Naruto Online : connexion, chargement du jeu, son et souris ;
- l'ISO : construction complète avec `iso/build-iso.sh` (5,4 Go), puis démarrage en session live dans une VM EFI. Le support est vérifié au démarrage, et Plasma s'ouvre en français avec la disposition Windows 11 et l'installeur.
- l'installation depuis l'ISO dans une VM EFI : le premier essai a révélé un système qui ne démarrait pas (GRUB sans entrée Fedora, à cause d'un chemin de construction resté dans `grubenv`) ; une fois corrigé, le système démarre sur l'assistant de premier démarrage de Plasma, puis sur l'écran de connexion et la session Niri.

**Testé sur un vrai PC** (Ryzen 7 3800X, Radeon RX 7600 XT, installation depuis l'ISO) : installation, bureau, assistant de fin de configuration, Vulkan, LACT, MangoHud, Wine ; Naruto Online de l'installeur officiel jusqu'au jeu, fluide avec DXVK ; Waydroid (Android 13, applis ARM, Play Store, Internet). Les problèmes trouvés et leurs corrections sont détaillés dans [docs/TESTS.md](docs/TESTS.md#6-vrai-matériel--installation-depuis-liso-12-octobre-2026). L'ISO téléchargeable ci-dessus a été reconstruite avec ces corrections, sauf DXVK pour Naruto Online, ajouté ensuite (relancer `setup`, voir la section 6).

**Pas encore testé** :
- une installation complète depuis l'**ISO reconstruite** le 12 octobre 2026 ;
- les performances en jeu (Steam, Proton) ;
- le VRR ;
- WinBoat (installé et KVM disponible sur le vrai PC, mais pas encore lancé : il faut une licence Windows).

**Limites connues** :
- Les jeux protégés par un anti-triche au niveau du noyau (Valorant, Fortnite, certains Call of Duty) ne fonctionnent pas sous Linux. Gardez Windows en dual-boot pour ceux-là.
- Netflix est limité à 1080p sous Linux (protection DRM).
- Pour WinBoat, il faut activer la virtualisation (SVM/VT-x) dans le BIOS et avoir une licence Windows.

## 10. Structure du projet

```
OS-fedora-gaming/
├── install.sh                 ← installation complète (point d'entrée)
├── doctor.sh                  ← diagnostic de santé
├── desktop/
│   ├── setup-desktop.sh       ← Plasma façon Windows 11, allègement, Naruto
│   ├── debloat-plasma.sh      ← liste de ce qui est retiré et désactivé
│   ├── plasma/                ← thème global « Fedora Gaming (Windows 11) »
│   ├── setup-tiling.sh        ← session Niri façon Windows
│   ├── tiling/                ← configurations Niri, waybar, lanceur, menu d'extinction
│   └── firstrun/              ← assistant de première connexion (ISO)
├── apps/                      ← Naruto Online (script et icône), WinBoat
├── config/                    ← MangoHud, icône Netflix
├── iso/
│   ├── build-iso.sh           ← construction de l'ISO (KIWI)
│   └── kiwi/                  ← profil et configuration de l'image
├── docs/                      ← guides : installation, jeu, réglages AMD, Naruto Online
└── vm-test/                   ← banc d'essai VirtualBox (bash et PowerShell)
```

## 11. Contribuer, feuille de route, sources

Les retours d'expérience (en particulier sur du vrai matériel), les signalements de bugs et les propositions sont les bienvenus dans les *issues* GitHub.

**Feuille de route** :
- [ ] Snapper et retour arrière depuis GRUB, pour revenir à l'état d'avant une mise à jour
- [x] Test sur du vrai matériel AMD (Ryzen 3000, RX 7600 XT)
- [x] Reconstruire et republier l'ISO avec les corrections du 12 octobre 2026
- [ ] Tests sur Intel et NVIDIA (pilote à documenter)
- [x] ISO prête à télécharger (voir la section Installation)
- [x] Dépôt séparé [naruto-online-linux](https://github.com/ghermetz/naruto-online-linux)

**Sources** : [Fedora KDE](https://fedoraproject.org/kde/) · [fedora-kiwi-descriptions](https://forge.fedoraproject.org/releng/fedora-kiwi-descriptions) · [RPM Fusion](https://rpmfusion.org) · [LACT](https://github.com/ilya-zlobintsev/LACT) · [WinBoat](https://winboat.app) · [Waydroid](https://docs.waydro.id) · [Lutris](https://lutris.net) · [ProtonDB](https://www.protondb.com) · [Niri](https://github.com/YaLTeR/niri)

Ce projet ne contient aucun logiciel propriétaire ni contenu protégé : uniquement des scripts, des configurations et de la documentation. Les marques citées appartiennent à leurs propriétaires respectifs.
