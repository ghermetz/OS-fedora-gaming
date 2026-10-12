# Rapport de tests

Tests menés du 10 au 11 octobre 2026 dans VirtualBox 7.2 (machines EFI, 4 à 8 cœurs, 8 à 12 Go de mémoire), sur un PC Windows 11 hôte, puis le 12 octobre 2026 sur un vrai PC (section 6).

Légende : ✅ validé · ⚠️ validé avec réserve · ❌ échec corrigé · ⏳ pas encore testé

## 1. `install.sh` sur Fedora 43 KDE (VM)

| Élément | Résultat | Détails |
|---|---|---|
| Exécution complète | ✅ | Code de sortie 0, `doctor.sh` sans erreur |
| Bloc pilotes | ❌ → ✅ | Le paquet `vulkan-mesa-layers` n'existe plus et faisait échouer tout le bloc. Retiré, et ajout de `--skip-unavailable` |
| Waydroid | ⚠️ | Conteneur actif et image Android présente ; `waydroid_script` échoue tant que Waydroid n'a pas été lancé une fois dans une session graphique |
| WinBoat | ⏳ | Impossible à tester : la VM n'a pas de virtualisation imbriquée (KVM) |

## 2. Allègement de Plasma (VM Fedora 43)

| Élément | Résultat | Détails |
|---|---|---|
| Retrait du superflu | ✅ | 139 paquets et 395 Mo en moins (suite PIM KDE + Akonadi/MariaDB, abrt, kleopatra…). Plasma, Dolphin, Konsole, Discover et LibreOffice restent intacts |
| Thème global « Windows 11 » | ✅ | Barre centrée, applis épinglées, thème sombre, appliqué avec `plasma-apply-lookandfeel` |

## 3. Naruto Online (VM Fedora 43, Wine 11 Staging)

| Élément | Résultat | Détails |
|---|---|---|
| Launcher sans accélération 3D | ✅ | Connexion, jeu chargé à 100 %, écran de jeu |
| Launcher avec accélération 3D | ✅ | Chromium passe tout seul en rendu de secours ; son et souris fonctionnent |
| `WINEDLLOVERRIDES="d3d11,dxgi=d"` (ancien « remède ») | ❌ | Fait planter le launcher (`CefSharp.Core.dll` introuvable) : supprimé du projet |
| Icône du menu (installation au 1er clic) | ⚠️ | Détecte l'installeur officiel `.zip` et lance l'installation ; installation complète interrompue par un plantage de la VM, à refaire |
| Sur une vraie Radeon (Direct3D 11 via Wine) | ⏳ | |

## 4. Session Niri façon Windows

Testée d'abord sur Fedora 43, puis sur le système installé depuis l'ISO Fedora 44, avec l'accélération 3D de la VM.

| Élément | Résultat | Détails |
|---|---|---|
| Configuration lue par niri | ❌ → ✅ | Elle était copiée sous le nom `config.kcl` (jamais lue) ; corrigé en `config.kdl` |
| Barre des tâches (Démarrer, fenêtres, systray, heure) | ✅ | Clics réels avec ydotool |
| Bouton Vue des tâches | ❌ → ✅ | Le clic est reçu deux fois et la bascule refermait la vue ; corrigé avec `open-overview` |
| Fenêtres ouvertes en grand, avec barre de titre | ✅ | |
| Alt+Tab avec aperçus | ✅ | |
| Super+↓ (moitié d'écran) | ✅ | |
| Aide en français | ✅ | Toutes les lignes traduites ou masquées |
| Applis X11 (Wine) via xwayland-satellite | ✅ | |
| Programmes KDE lancés automatiquement hors Plasma | ❌ → ✅ | Fenêtre noire, alerte de plantage, IBus : masqués pour Niri seulement |
| Sans accélération 3D | ⚠️ | Niri refuse le rendu logiciel et n'affiche rien. Concerne uniquement les VM sans 3D, pas un vrai GPU |

## 5. ISO Fedora Gaming 44 (`iso/build-iso.sh`)

| Élément | Résultat | Détails |
|---|---|---|
| Construction sur un hôte Fedora 43 | ❌ → ✅ | Le `rpm` de Fedora 43 ne sait pas préparer une image 44 : la construction passe automatiquement dans un conteneur Fedora 44 |
| Configuration fedora-gaming appliquée | ❌ → ✅ | Elle était ajoutée après l'`exit 0` du `config.sh` officiel ; elle est maintenant insérée avant |
| Fichiers EFI | ❌ → ✅ | Étiquettes SELinux refusées dans le conteneur ; corrigé en montant le `/var/tmp` de l'hôte |
| Compression | ❌ → ✅ | lzma faisait planter la VM ; passage en lz4hc (ISO de 5,4 Go) |
| Nom de volume | ❌ → ✅ | Il dépassait 32 caractères ; profil renommé `Gaming-KDE` |
| Session live | ✅ | Vérification du support « PASS », Plasma en français avec la disposition Windows 11 |
| Installation sur disque | ✅ | Partitionnement automatique Btrfs ; l'installeur propose aussi le partage du disque (dual-boot) |
| Démarrage du système installé | ❌ → ✅ | GRUB n'affichait que « UEFI Firmware Settings » : la configuration de GRUB contenait un chemin de la machine de construction (`blsdir`). Corrigé dans la construction ; vérifié sur le système installé et dans la nouvelle image |
| Assistant de premier démarrage (plasma-setup) | ✅ | Langue, clavier AZERTY, thème, fuseau horaire |
| Installation complète depuis l'ISO reconstruite | ⏳ | À faire, sur le vrai PC |
| Assistant « terminer la configuration » (install.sh) | ⏳ | |

## 6. Vrai matériel : installation depuis l'ISO (12 octobre 2026)

PC : AMD Ryzen 7 3800X, Radeon RX 7600 XT (Navi 33), 32 Go, Fedora 44 sur un SSD dédié (Btrfs), Windows sur un autre disque. Démarrage UEFI avec rEFInd, Secure Boot désactivé. Noyau 7.2.9, Mesa 26.2.4.

| Élément | Résultat | Détails |
|---|---|---|
| Installation depuis l'ISO et démarrage | ✅ | Plasma façon Windows 11 en français, AZERTY |
| Assistant de 1re connexion | ❌ → ✅ | Jamais affiché : les scripts étaient en mode 644 dans le dépôt (commités depuis Windows), donc pas exécutables dans l'ISO, et systemd refusait l'entrée de démarrage automatique (`Permission denied`). Bits exécutables posés dans git, `chmod` dans la construction de l'ISO, et les `.desktop` passent par `bash` |
| Icône Naruto Online | ❌ → ✅ | Même cause : le clic ne faisait rien |
| `install.sh` lancé depuis le menu « Terminer la configuration » | ✅ | Tout installé, `doctor.sh` sans erreur |
| Vulkan (RADV), LACT, MangoHud, Wine 11 | ✅ | RX 7600 XT reconnue par RADV et LACT ; `vkcube` avec MangoHud |
| Décodage vidéo matériel H.264/H.265 | ❌ → ✅ | Absent : le Mesa de Fedora ne l'a pas. `install.sh` installe maintenant `mesa-va-drivers-freeworld` (RPM Fusion) |
| GameMode | ❌ → ✅ | `gamemoded -t` : le processeur restait en `powersave`, car l'utilisateur n'était pas dans le groupe `gamemode` (règle polkit). `install.sh` l'y ajoute |
| Waydroid | ❌ → ✅ | Image Android jamais téléchargée : le service crée `/var/lib/waydroid` en démarrant, et le script prenait ce dossier pour la preuve d'une image. On teste maintenant `waydroid.cfg` (aussi dans `doctor.sh`) |
| Docker à la demande | ❌ → ✅ | Docker démarrait avec le système : le réglage par socket n'était appliqué que par l'étape bureau, sautée par l'assistant (`--skip-desktop`). Fait maintenant dans l'étape WinBoat |
| Notifications sous Plasma | ❌ → ✅ | `mako` (notifications de Niri) tentait de démarrer dans Plasma et finissait en échec. Réservé aux sessions hors KDE |
| KVM (WinBoat) | ✅ | `/dev/kvm` accessible, SVM actif |
| Naruto Online : installeur officiel 3.4.7.0 | ❌ → ✅ | L'installeur ignore désormais le mode silencieux (`/S` le faisait quitter en 2 s sans rien installer) et choisit son dossier. Le script l'affiche (« Utiliser ») et relie son dossier à `~/Games/Naruto Online`. Installation complète validée, .NET 4.8 en 5 minutes |
| Naruto Online : launcher et rendu Direct3D 11 sur la Radeon | ✅ | Launcher, connexion et page du jeu affichés avec le rendu accéléré |
| Naruto Online : chargement du jeu | ⚠️ | Bloqué à 14 % : le serveur de jeu `182.254.116.117` coupe toutes les connexions de ce réseau, même hors Wine (`curl`). Problème réseau ou serveur, pas Linux |
| `doctor.sh` | ✅ | Nouveaux contrôles : VA-API H.264, groupe gamemode, image Waydroid, Docker à la demande, KVM, scripts lançables, services en échec, horloge en dual-boot |
| Horloge en dual-boot | ⚠️ | L'installeur a réglé l'horloge matérielle en heure locale, comme Windows par défaut. Ne rien changer, sauf si Windows a été passé en UTC (README) |

## À tester sur le vrai matériel

- Performances en jeu, VRR/FreeSync sur plusieurs écrans, LACT
- Naruto Online jusqu'à l'écran de jeu (serveur injoignable le 12/10/2026)
- WinBoat (virtualisation matérielle)
- Waydroid dans une vraie session
