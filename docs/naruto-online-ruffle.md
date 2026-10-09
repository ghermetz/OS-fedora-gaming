# Naruto Online — Route 1 : Ruffle (Flash émulé)

## 📖 Vue d'ensemble

**Méthode** : Émulateur Flash moderne (Rust)  
**Compatibilité** : ⚠️ Partielle (Flash Player 32 émulé)  
**Performances** : ⭐⭐⭐ Correctes  
**Difficulté** : ⭐ Facile

## ✅ Avantages
- ✅ Natif Linux (pas de Wine)
- ✅ Léger et rapide
- ✅ Pas de dépendances lourdes
- ✅ Open-source et sécurisé

## ❌ Inconvénients
- ❌ Flash pas 100% compatible
- ❌ Bugs possibles (jeu ancien)
- ❌ Pas de garantie de fonctionnement

## 🚀 Installation

### Via install.sh
```bash
# Déjà installé si tu as lancé install.sh
flatpak info rs.ruffle.Ruffle
```

### Manuel
```bash
sudo flatpak install -y flathub rs.ruffle.Ruffle
```

## 🌐 Méthode 1 : Extension Firefox (recommandé)

### 1. Installer l'extension Ruffle
```
Firefox → Extensions
→ Rechercher "Ruffle"
→ Installer "Ruffle - Flash Emulator"
```

Ou directement :
https://addons.mozilla.org/firefox/addon/ruffle_ruffle_provider/

### 2. Ouvrir le jeu
```
Firefox → https://gamebox3.narutowebgame.com
```

Le jeu se charge automatiquement via Ruffle.

### 3. Connexion
- Login avec tes identifiants Naruto Online
- Le launcher Flash devrait fonctionner

## 🖥️ Méthode 2 : App Ruffle Desktop

### Lancer Ruffle
```bash
flatpak run rs.ruffle.Ruffle
```

⚠️ **Limitation** : L'app desktop ne navigue PAS sur le web. Elle ne peut ouvrir que des fichiers `.swf` locaux.

### Utilisation
```bash
# Si tu as téléchargé un .swf local
flatpak run rs.ruffle.Ruffle /chemin/vers/jeu.swf
```

## 📝 Script helper

### Via apps/naruto-online.sh
```bash
cd ~/Documents/fedora-gaming
./apps/naruto-online.sh ruffle
```

## 🔧 Troubleshooting

### Extension ne se charge pas
```
Firefox → about:addons
→ Ruffle → Options
→ Vérifier "Activer sur tous les sites"
```

### Jeu ne démarre pas
```
F12 → Console
→ Chercher erreurs Flash/Ruffle
```

### Performance faible
```
Firefox → about:config
→ layers.acceleration.force-enabled = true
```

### Écran blanc
- Vider cache Firefox (Ctrl+Shift+Del)
- Désactiver bloqueurs pub (uBlock Origin)
- Essayer mode navigation privée

## ⚙️ Configuration Ruffle

### Paramètres extension
```
Ruffle Options → Advanced
→ Maximum Execution Time: 30s
→ Log Level: Error
```

## 🎮 Compatibilité

| Fonctionnalité | Statut |
|----------------|--------|
| Login | ✅ OK |
| Menu principal | ✅ OK |
| Combat | ⚠️ Bugs possibles |
| Animations | ⚠️ Ralentissements |
| Son | ✅ OK |
| Sauvegarde | ✅ OK (serveur) |

## 🔄 Alternatives

Si Ruffle ne fonctionne pas bien :
- **Route 2** : [Bottles + Wine](naruto-online-bottles.md) (software rendering)
- **Route 3** : [WinBoat Windows VM](naruto-online-winboat.md) (garantie 100%)

## 📊 Verdict

**Recommandé pour** : Tester rapidement  
**Éviter si** : Tu veux garantie 100%  
**Note** : ⭐⭐⭐ / 5
