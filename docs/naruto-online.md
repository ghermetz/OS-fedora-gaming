# Naruto Online sous Fedora

Naruto Online se lance avec **le launcher Windows officiel, dans Wine**. Aucune VM Windows n'est nécessaire et aucun réglage de rendu n'est à faire.

> ✅ **Validé le 10/10/2026** dans la VM de test (Fedora 43 KDE, Wine 11 Staging) : le launcher démarre, la connexion fonctionne, le jeu Flash charge à 100 % et l'écran de jeu répond.

## Installation (une seule fois, ~30 min)

```bash
cd ~/fedora-gaming
./apps/naruto-online.sh setup "/chemin/vers/Naruto Online"
```

`/chemin/vers/Naruto Online` est le dossier qui contient `Naruto Online.exe`. Sur ta machine Windows, c'est `C:\Program Files (x86)\Naruto Online`. Si la partition Windows est montée, le script trouve le dossier tout seul et tu peux lancer `setup` sans argument.

Le script fait quatre choses :
1. Il copie le jeu dans `~/Games/Naruto Online`. Lancer le jeu directement depuis la partition NTFS de Windows le rend lent et provoque des verrous de fichiers.
2. Il crée un préfixe Wine dédié dans `~/.local/share/wineprefixes/naruto-online`.
3. Il installe **.NET Framework 4.8** et les polices Microsoft (`corefonts`) avec winetricks. C'est l'étape longue, soit 20 à 30 minutes.
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
| Le chargement reste bloqué ou la page est blanche | `./apps/naruto-online.sh clear-cache`, puis relance le jeu (tu devras te reconnecter) |
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
