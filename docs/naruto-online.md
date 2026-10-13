# Naruto Online sous Fedora

Naruto Online se lance avec **le launcher Windows officiel, dans Wine**. Aucune VM Windows n'est nécessaire et aucun réglage de rendu n'est à faire.

> ✅ **Validé le 10/10/2026** dans la VM de test (Fedora 43 KDE, Wine 11 Staging) : le launcher démarre, la connexion fonctionne, le jeu Flash charge à 100 % et l'écran de jeu répond.
>
> ✅ **Testé le 12/10/2026 sur un vrai PC** (Fedora 44, Radeon RX 7600 XT) avec l'installeur officiel 3.4.7.0 : installation complète, launcher, connexion et jeu, fluide avec DXVK. Un premier essai est resté bloqué à 14 % pendant qu'un serveur du jeu refusait les connexions ; c'était passager (voir *Dépannage*).
>
> ✅ **Testé le 13/10/2026 sous la session Niri** (xwayland-satellite, deux écrans) : souris corrigée (elle était décalée de ~30 px), et deux comptes en jeu en même temps une fois le contournement du blocage à 14 % activé (voir *Dépannage*).

## Installation (une seule fois, 5 à 30 min)

```bash
cd ~/fedora-gaming
./apps/naruto-online.sh setup "/chemin/vers/Naruto Online"
```

La source peut être l'installeur officiel (`Naruto Online_fr_….zip` ou `.exe`), ou le dossier qui contient `Naruto Online.exe`. Avec l'installeur, **une fenêtre s'ouvre : clique sur « Utiliser »**. Il ne sait plus s'installer sans fenêtre (version 3.4.7.0) et s'installe dans le préfixe Wine, que le script relie à `~/Games/Naruto Online`. À la fin, le launcher s'ouvre : ferme-le pour que le script termine.

Pour un dossier, `/chemin/vers/Naruto Online` est celui qui contient `Naruto Online.exe`. Sur ta machine Windows, c'est `C:\Program Files (x86)\Naruto Online`. Si la partition Windows est montée, le script trouve le dossier tout seul et tu peux lancer `setup` sans argument.

Le script fait quatre choses :
1. Il copie le jeu dans `~/Games/Naruto Online`. Lancer le jeu directement depuis la partition NTFS de Windows le rend lent et provoque des verrous de fichiers.
2. Il crée un préfixe Wine dédié dans `~/.local/share/wineprefixes/naruto-online`.
3. Il installe **.NET Framework 4.8** et les polices Microsoft (`corefonts`) avec winetricks. C'est l'étape longue : 5 minutes sur le PC de test (fibre), jusqu'à 30 minutes ailleurs. Il installe aussi **DXVK** (affichage par Vulkan), bien plus fluide que le Direct3D de Wine.
4. Il ajoute **« Naruto Online »** au menu des applications.

## Jouer

Lance le jeu depuis le menu KDE, ou avec :

```bash
./apps/naruto-online.sh run
```

Le premier chargement du jeu est long, comme le signale le launcher lui-même.

## Dépannage

| Symptôme | Solution |
|---|---|
| Le chargement du jeu reste bloqué (par exemple à 14 %) et recommence, parfois sur un seul de deux comptes ouverts | Le jeu n'arrive pas à joindre un de ses serveurs : `debug.log`, dans le dossier du jeu, contient alors `IO_ERROR`. Une cause fréquente : au chargement, le jeu interroge le service DNS de Tencent à l'adresse `182.254.116.117`, et toute requête qui porte ce nom est coupée en route (alors que le même service répond sous ses autres adresses). **Correctif, validé le 13/10/2026 avec deux comptes en jeu en même temps** : `bash apps/naruto-reseau.sh activer` (sans sudo : le mot de passe est demandé pour le pare-feu). Il installe un petit relais local (service utilisateur `naruto-httpdns`) et une règle firewalld qui lui envoie ces requêtes ; `etat` pour vérifier, `desactiver` pour tout retirer. Si le blocage persiste, le serveur de jeu lui-même (port 6001) peut être indisponible : réessaie plus tard ou essaie un autre serveur |
| Souris décalée (les clics tombent ~30 px trop bas), seulement sous niri | niri ne dessine pas de barre de titre aux fenêtres X11, mais Wine en suppose une. Le script règle `Decorated=N` dans le préfixe au lancement suivant ; ferme puis relance le jeu |
| Affichage saccadé ou lent | Vérifie que DXVK est installé : relance `./apps/naruto-online.sh setup` (le jeu fermé) |
| La page reste blanche | `./apps/naruto-online.sh clear-cache`, puis relance le jeu (tu devras te reconnecter) |
| « Préfixe incomplet » | Relance `setup` : les étapes déjà faites sont sautées |
| Tout recommencer | `./apps/naruto-online.sh uninstall`, puis `setup` |
| Voir les erreurs Wine | `WINEDEBUG=err+all ./apps/naruto-online.sh run` |

## Comment ça marche, et les fausses pistes

Le launcher est une application .NET (WinForms) en **32 bits**. Elle embarque **Chromium 75** (CefSharp) et le plugin **Flash PPAPI** (`Plugins/pepflashplayer32.dll`), puis affiche la page `naruto.narutowebgame.com/fr/serverlist/…`. Le jeu lui-même est un ensemble de modules Flash ActionScript 3 (`entry.swf`, `naruto.core.swf`, des dizaines de plugins…).

- ❌ **Désactiver `d3d11`/`dxgi`** (l'ancien « anti écran noir », `WINEDLLOVERRIDES="d3d11,dxgi=d"`) **fait planter le launcher** : `libcef.dll` dépend de ces DLL, et l'erreur obtenue est `Could not load file or assembly 'CefSharp.Core.dll'`. Il ne faut pas l'utiliser.
- ❌ **Ruffle** : le jeu est une grosse application AS3 modulaire qui se connecte en socket aux serveurs, ce qui dépasse ce que Ruffle sait faire de façon fiable.
- ❌ **Bottles (Flatpak)** : son bac à sable complique l'usage de winetricks et `bottles-cli` est limité. Le Wine système suffit.
- 🛟 **Solution de secours** : si un jour Wine ne suffit plus, utilise WinBoat, c'est-à-dire une vraie VM Windows ([naruto-online-winboat.md](naruto-online-winboat.md)).

### Rendu GPU

Le jeu a été testé deux fois dans la VM :
- **sans accélération 3D** : Chromium tourne en rendu logiciel ;
- **avec l'accélération 3D de VirtualBox** (pilote SVGA3D, OpenGL 4.1) : Chromium tente d'abord Direct3D 11 via Wine, qui n'est pas disponible en OpenGL 4.1, puis **bascule tout seul** sur un autre mode de rendu.

Dans les deux cas, la connexion, le jeu, le son et la souris fonctionnent, sans écran noir.

Sur une vraie Radeon (OpenGL 4.6), Direct3D 11 devrait être disponible. C'est le seul chemin qui n'a pas pu être testé. En cas d'écran noir, la piste sera de forcer le rendu logiciel de Chromium, **pas** de désactiver `d3d11`/`dxgi`.
