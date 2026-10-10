// fedora-gaming — disposition « Windows 11 » appliquée à la 1re connexion
// Barre en bas : [espace] Démarrer + applis épinglées (centrés) [espace] systray, heure, bureau
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = "org.kde.image";
}

var panel = new Panel;
panel.location = "bottom";
panel.height = 2 * Math.ceil(gridUnit * 2.5 / 2);   // ~48 px comme Windows 11
panel.floating = false;
panel.hiding = "none";

panel.addWidget("org.kde.plasma.panelspacer");

var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["Shortcuts"];
kickoff.writeConfig("global", "Alt+F1");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "start-here-kde-symbolic");
kickoff.writeConfig("favoritesPortedToKAstats", "true");

var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:org.mozilla.firefox.desktop",
    "applications:steam.desktop",
    "applications:naruto-online.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:systemsettings.desktop"
].join(","));
tasks.writeConfig("iconSpacing", "2");

panel.addWidget("org.kde.plasma.panelspacer");

panel.addWidget("org.kde.plasma.systemtray");
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateFormat", "shortDate");
panel.addWidget("org.kde.plasma.showdesktop");
