#!/usr/bin/python3
# fedora-gaming — menu Démarrer « façon Linux Mint / Zorin OS » (session Niri)
#
#   • en haut : votre nom et la recherche (tapez directement au clavier) ;
#   • à gauche : raccourcis (dossier perso, paramètres, logiciels) et
#     verrouiller / se déconnecter / éteindre ;
#   • au milieu : Favoris, Récents, Toutes les applications, les catégories et
#     les dossiers (il suffit de survoler une catégorie, comme sous Mint) ;
#   • à droite : les applications avec leur description.
# Clic droit sur une appli : l'ajouter aux favoris ou l'en retirer.
# Échap ou clic à côté : fermer. Relancer le menu pendant qu'il est ouvert le ferme.
#
# Favoris : ~/.config/fedora-gaming/menu-favoris.txt (un identifiant .desktop par ligne)

import json
import os
import pwd
import signal
import sys
import time
import unicodedata

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, Gio, GLib, Gtk, GtkLayerShell, Pango  # noqa: E402

DOSSIER = os.path.expanduser("~/.config/fedora-gaming")
FAVORIS = os.path.join(DOSSIER, "menu-favoris.txt")
RECENTS = os.path.join(GLib.get_user_state_dir(), "fedora-gaming", "menu-recents.json")
VERROU = os.path.join(GLib.get_user_runtime_dir(), "menu-demarrer.pid")

FAVORIS_DEFAUT = [
    "org.mozilla.firefox.desktop", "org.kde.dolphin.desktop", "steam.desktop",
    "com.heroicgameslauncher.hgl.desktop", "net.lutris.Lutris.desktop",
    "dev.vencord.Vesktop.desktop", "netflix.desktop", "org.jellyfin.JellyfinDesktop.desktop",
    "org.kde.konsole.desktop", "kdesystemsettings.desktop",
]

# (libellé, icône, catégories freedesktop)
CATEGORIES = [
    ("Accessoires", "applications-utilities", {"Utility", "Accessibility"}),
    ("Bureautique", "applications-office", {"Office"}),
    ("Développement", "applications-development", {"Development"}),
    ("Éducation", "applications-education", {"Education"}),
    ("Graphisme", "applications-graphics", {"Graphics"}),
    ("Internet", "applications-internet", {"Network"}),
    ("Jeux", "applications-games", {"Game"}),
    ("Multimédia", "applications-multimedia", {"AudioVideo", "Audio", "Video"}),
    ("Science", "applications-science", {"Science"}),
    ("Système", "applications-system", {"System"}),
    ("Paramètres", "preferences-system", {"Settings"}),
]

CSS = b"""
* { font-family: "Inter", "Noto Sans", sans-serif; }
#fond { background-color: transparent; }
#menu {
    background-color: rgba(30, 32, 38, 0.97);
    border: 1px solid rgba(255, 255, 255, 0.09);
    border-radius: 16px;
    box-shadow: 0 10px 28px rgba(0, 0, 0, 0.55);
}
#entete { padding: 16px 18px 12px 18px; }
#avatar {
    background-color: #15a6f0;
    color: #ffffff;
    border-radius: 999px;
    min-width: 36px; min-height: 36px;
    font-weight: 700; font-size: 14px;
}
#nom { color: #eef1f5; font-weight: 600; font-size: 14px; }
#sous-nom { color: #8b949e; font-size: 11px; }
entry#recherche {
    background-color: rgba(255, 255, 255, 0.06);
    background-image: none;
    color: #eef1f5;
    caret-color: #15a6f0;
    border: 1px solid rgba(255, 255, 255, 0.09);
    border-radius: 12px;
    padding: 8px 12px;
    min-height: 22px;
    box-shadow: none;
    font-size: 13px;
}
entry#recherche:focus { border-color: #15a6f0; }
entry#recherche image { color: #8b949e; }
#barre-gauche {
    background-color: rgba(255, 255, 255, 0.03);
    border-right: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 0 0 0 16px;
    padding: 10px 6px;
}
button.action {
    background: none; border: none; box-shadow: none;
    border-radius: 10px; padding: 9px; margin: 1px 0;
}
button.action:hover { background-color: rgba(255, 255, 255, 0.10); }
button.eteindre:hover { background-color: rgba(255, 92, 99, 0.35); }
separator { background-color: rgba(255, 255, 255, 0.07); min-width: 1px; min-height: 1px; }
list, viewport, scrolledwindow { background: none; border: none; }
row { background: none; box-shadow: none; outline: none; }
row.categorie {
    color: #c9d1d9; padding: 7px 12px; margin: 1px 6px;
    border-radius: 10px; font-size: 13px;
}
row.categorie:hover { background-color: rgba(255, 255, 255, 0.07); }
row.categorie:selected, row.categorie:selected:focus {
    background-color: rgba(21, 166, 240, 0.24); color: #ffffff;
}
row.appli { padding: 6px 10px; margin: 1px 6px; border-radius: 10px; }
row.appli:hover { background-color: rgba(255, 255, 255, 0.08); }
row.appli:selected, row.appli:selected:focus, row.appli:focus {
    background-color: rgba(21, 166, 240, 0.28);
}
.nom-appli { color: #eef1f5; font-size: 13px; }
.description { color: #8b949e; font-size: 11px; }
.favori { color: #ffc46b; font-size: 11px; }
.titre { color: #8b949e; font-size: 11px; font-weight: 700; margin: 10px 18px 4px 18px; }
.vide { color: #8b949e; font-size: 13px; margin: 40px; }
scrollbar, scrollbar trough { background: none; border: none; }
scrollbar slider { min-width: 4px; border-radius: 4px; background-color: rgba(255, 255, 255, 0.18); }
menu, .menu, .context-menu {
    background-color: #24272e; color: #eef1f5;
    border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 10px; padding: 4px;
}
menuitem { padding: 6px 12px; border-radius: 6px; }
menuitem:hover { background-color: rgba(21, 166, 240, 0.35); }
tooltip { background-color: #24272e; color: #eef1f5; border-radius: 8px; }
"""


def simplifier(texte):
    """minuscules, sans accents : « Paramètres » → « parametres »"""
    t = unicodedata.normalize("NFKD", texte or "")
    return "".join(c for c in t if not unicodedata.combining(c)).casefold()


def lire_lignes(chemin, defaut):
    try:
        with open(chemin) as f:
            return [l.strip() for l in f if l.strip() and not l.startswith("#")]
    except OSError:
        return list(defaut)


def basculer_instance():
    """Un seul menu à la fois : relancer le menu ferme celui déjà ouvert."""
    try:
        with open(VERROU) as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGTERM)
        sys.exit(0)
    except (OSError, ValueError):
        pass
    with open(VERROU, "w") as f:
        f.write(str(os.getpid()))


class Appli:
    def __init__(self, info):
        self.info = info
        self.id = info.get_id()
        self.nom = info.get_display_name() or self.id
        self.desc = info.get_description() or info.get_generic_name() or ""
        self.cats = set(filter(None, (info.get_categories() or "").split(";")))
        self.cle_nom = simplifier(self.nom)
        self.cle_autres = simplifier(" ".join(
            [info.get_generic_name() or "", " ".join(info.get_keywords() or []),
             info.get_executable() or "", self.id]
            + [libelle for libelle, _, cats in CATEGORIES if self.cats & cats]
            + (["parametres reglages configuration"] if "Settings" in self.cats else [])))
        self.cle_desc = simplifier(self.desc)

    def score(self, q):
        if self.cle_nom.startswith(q):
            return 0
        if any(m.startswith(q) for m in self.cle_nom.split()):
            return 1
        if q in self.cle_nom:
            return 2
        if q in self.cle_autres:
            return 3
        if len(q) >= 3 and q in self.cle_desc:
            return 4
        return None


class Menu(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.set_name("fond")
        self.set_app_paintable(True)
        visuel = self.get_screen().get_rgba_visual()
        if visuel:
            self.set_visual(visuel)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "menu-demarrer")
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        for bord in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM,
                     GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
            GtkLayerShell.set_anchor(self, bord, True)
        GtkLayerShell.set_exclusive_zone(self, -1)     # couvre aussi la barre : un clic à côté ferme
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)

        self.applis = self.charger_applis()
        self.favoris = [i for i in lire_lignes(FAVORIS, FAVORIS_DEFAUT) if i in self.applis]
        try:
            with open(RECENTS) as f:
                self.recents = json.load(f)
        except (OSError, ValueError):
            self.recents = {}
        self.minuteur_survol = None

        fond = Gtk.EventBox()
        fond.set_visible_window(False)
        fond.connect("button-press-event", self.clic_fond)
        self.add(fond)

        self.revealer = Gtk.Revealer()
        self.revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP)
        self.revealer.set_transition_duration(160)
        self.revealer.set_halign(Gtk.Align.START)
        self.revealer.set_valign(Gtk.Align.END)
        self.revealer.set_margin_start(8)
        self.revealer.set_margin_bottom(56)            # juste au-dessus de la barre des tâches
        fond.add(self.revealer)

        self.menu = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.menu.set_name("menu")
        self.menu.set_size_request(760, 600)
        self.menu.set_margin_start(6)
        self.menu.set_margin_top(14)
        self.menu.set_margin_end(14)
        self.menu.set_margin_bottom(6)
        self.revealer.add(self.menu)

        self.menu.pack_start(self.construire_entete(), False, False, 0)
        self.menu.pack_start(Gtk.Separator(), False, False, 0)
        corps = Gtk.Box()
        self.menu.pack_start(corps, True, True, 0)
        corps.pack_start(self.construire_barre_gauche(), False, False, 0)
        corps.pack_start(self.construire_categories(), False, False, 0)
        corps.pack_start(Gtk.Separator(orientation=Gtk.Orientation.VERTICAL), False, False, 0)
        corps.pack_start(self.construire_liste(), True, True, 0)

        self.connect("key-press-event", self.touche)
        self.connect("destroy", self.quitter)
        self.show_all()
        self.choisir_categorie(self.lignes_cat[0 if self.favoris else 2])
        GLib.idle_add(self.revealer.set_reveal_child, True)
        self.recherche.grab_focus()

    # ── données ─────────────────────────────────────────────────────────────
    def charger_applis(self):
        applis = {}
        for info in Gio.AppInfo.get_all():
            if isinstance(info, Gio.DesktopAppInfo) and info.should_show():
                applis[info.get_id()] = Appli(info)
        return applis

    def tri(self, liste):
        return sorted(liste, key=lambda a: a.cle_nom)

    # ── construction ────────────────────────────────────────────────────────
    def construire_entete(self):
        boite = Gtk.Box(spacing=12)
        boite.set_name("entete")
        nom = (pwd.getpwuid(os.getuid()).pw_gecos.split(",")[0] or os.getlogin()).title()
        initiales = "".join(m[0] for m in nom.split()[:2]).upper() or "?"
        avatar = Gtk.Label(label=initiales)
        avatar.set_name("avatar")
        avatar.set_valign(Gtk.Align.CENTER)
        boite.pack_start(avatar, False, False, 0)
        textes = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        textes.set_valign(Gtk.Align.CENTER)
        l_nom = Gtk.Label(label=nom, xalign=0)
        l_nom.set_name("nom")
        l_sous = Gtk.Label(label=GLib.get_host_name(), xalign=0)
        l_sous.set_name("sous-nom")
        textes.pack_start(l_nom, False, False, 0)
        textes.pack_start(l_sous, False, False, 0)
        boite.pack_start(textes, False, False, 0)

        self.recherche = Gtk.SearchEntry()
        self.recherche.set_name("recherche")
        self.recherche.set_placeholder_text("Rechercher une application…")
        self.recherche.set_width_chars(34)
        self.recherche.set_valign(Gtk.Align.CENTER)
        self.recherche.connect("search-changed", self.recherche_changee)
        self.recherche.connect("activate", self.lancer_premier)
        self.recherche.connect("key-press-event", self.touche_recherche)
        boite.pack_end(self.recherche, False, False, 0)
        return boite

    def bouton_action(self, icone, info_bulle, action, classe=None):
        b = Gtk.Button()
        b.get_style_context().add_class("action")
        if classe:
            b.get_style_context().add_class(classe)
        img = Gtk.Image.new_from_icon_name(icone, Gtk.IconSize.LARGE_TOOLBAR)
        img.set_pixel_size(24)
        b.add(img)
        b.set_tooltip_text(info_bulle)
        b.set_relief(Gtk.ReliefStyle.NONE)
        b.connect("clicked", lambda *_: self.executer(action))
        return b

    def construire_barre_gauche(self):
        barre = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        barre.set_name("barre-gauche")
        haut = [
            ("user-home", "Dossier personnel", ["dolphin", GLib.get_home_dir()]),
            ("folder-download", "Téléchargements",
             ["dolphin", GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DOWNLOAD) or GLib.get_home_dir()]),
            ("preferences-system", "Paramètres", ["systemsettings"]),
            ("plasmadiscover", "Logiciels : installer et mettre à jour", ["plasma-discover"]),
        ]
        for icone, texte, cmd in haut:
            barre.pack_start(self.bouton_action(icone, texte, cmd), False, False, 0)
        bas = [
            ("system-lock-screen", "Verrouiller (Super+L)", ["swaylock", "-f"], None),
            ("system-log-out", "Se déconnecter", ["niri", "msg", "action", "quit", "--skip-confirmation"], None),
            ("system-shutdown", "Éteindre, redémarrer, mettre en veille…",
             ["wlogout", "-p", "layer-shell", "-b", "5", "-T", "330", "-B", "330"], "eteindre"),
        ]
        for icone, texte, cmd, classe in reversed(bas):
            barre.pack_end(self.bouton_action(icone, texte, cmd, classe), False, False, 0)
        return barre

    def construire_categories(self):
        defil = Gtk.ScrolledWindow()
        defil.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        defil.set_size_request(210, -1)
        self.liste_cat = Gtk.ListBox()
        self.liste_cat.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.liste_cat.connect("row-selected", lambda _l, r: r and self.afficher(r.contenu))
        defil.add(self.liste_cat)

        entrees = [("Favoris", "starred", "favoris"), ("Récents", "document-open-recent", "recents"),
                   ("Toutes les applications", "applications-all", "toutes")]
        utilisees = set()
        for libelle, icone, cats in CATEGORIES:
            if any(a.cats & cats for a in self.applis.values()):
                entrees.append((libelle, icone, cats))
                utilisees |= cats
        connues = set().union(*(c for _, _, c in CATEGORIES))
        if any(not (a.cats & connues) for a in self.applis.values()):
            entrees.append(("Autres", "applications-other", "autres"))
        entrees.append(("Dossiers", "folder", "dossiers"))

        self.lignes_cat = []
        for libelle, icone, contenu in entrees:
            ligne = Gtk.ListBoxRow()
            ligne.get_style_context().add_class("categorie")
            ligne.contenu = contenu
            ligne.libelle = libelle
            boite = Gtk.Box(spacing=10)
            img = Gtk.Image.new_from_icon_name(icone, Gtk.IconSize.LARGE_TOOLBAR)
            img.set_pixel_size(22)
            boite.pack_start(img, False, False, 0)
            boite.pack_start(Gtk.Label(label=libelle, xalign=0), True, True, 0)
            evt = Gtk.EventBox()
            evt.add(boite)
            # Comme sous Mint : survoler une catégorie l'ouvre
            evt.connect("enter-notify-event", self.survol_categorie, ligne)
            evt.connect("leave-notify-event", self.fin_survol)
            ligne.add(evt)
            self.liste_cat.add(ligne)
            self.lignes_cat.append(ligne)
        return defil

    def construire_liste(self):
        boite = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.titre = Gtk.Label(xalign=0)
        self.titre.get_style_context().add_class("titre")
        boite.pack_start(self.titre, False, False, 0)
        self.defil_applis = Gtk.ScrolledWindow()
        self.defil_applis.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.liste = Gtk.ListBox()
        self.liste.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.liste.set_activate_on_single_click(True)
        self.liste.connect("row-activated", lambda _l, r: r.action())
        self.liste.connect("key-press-event", self.touche_liste)
        self.defil_applis.add(self.liste)
        boite.pack_start(self.defil_applis, True, True, 0)
        return boite

    def ligne_element(self, icone, nom, desc, action, appli=None):
        ligne = Gtk.ListBoxRow()
        ligne.get_style_context().add_class("appli")
        ligne.action = action
        ligne.appli = appli
        boite = Gtk.Box(spacing=12)
        if isinstance(icone, Gio.Icon):
            img = Gtk.Image.new_from_gicon(icone, Gtk.IconSize.DND)
        else:
            img = Gtk.Image.new_from_icon_name(icone or "application-x-executable", Gtk.IconSize.DND)
        img.set_pixel_size(34)
        boite.pack_start(img, False, False, 0)
        textes = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        textes.set_valign(Gtk.Align.CENTER)
        l_nom = Gtk.Label(label=nom, xalign=0)
        l_nom.set_ellipsize(Pango.EllipsizeMode.END)
        l_nom.get_style_context().add_class("nom-appli")
        textes.pack_start(l_nom, False, False, 0)
        if desc:
            l_desc = Gtk.Label(label=desc, xalign=0)
            l_desc.set_ellipsize(Pango.EllipsizeMode.END)
            l_desc.get_style_context().add_class("description")
            textes.pack_start(l_desc, False, False, 0)
        boite.pack_start(textes, True, True, 0)
        if appli and appli.id in self.favoris:
            etoile = Gtk.Label(label="★")
            etoile.get_style_context().add_class("favori")
            boite.pack_end(etoile, False, False, 4)
        if appli:
            evt = Gtk.EventBox()
            evt.add(boite)
            evt.connect("button-press-event", self.clic_appli, appli)
            ligne.add(evt)
        else:
            ligne.add(boite)
        if desc:
            ligne.set_tooltip_text(desc)
        return ligne

    # ── affichage ───────────────────────────────────────────────────────────
    def remplir(self, titre, elements, vide="Rien à afficher"):
        self.titre.set_text(titre.upper())
        for enfant in self.liste.get_children():
            self.liste.remove(enfant)
        for e in elements:
            self.liste.add(e)
        if not elements:
            l = Gtk.Label(label=vide)
            l.get_style_context().add_class("vide")
            ligne = Gtk.ListBoxRow()
            ligne.set_selectable(False)
            ligne.set_activatable(False)
            ligne.add(l)
            self.liste.add(ligne)
        self.liste.show_all()
        self.defil_applis.get_vadjustment().set_value(0)

    def lignes_applis(self, applis):
        return [self.ligne_element(a.info.get_icon(), a.nom, a.desc,
                                   (lambda a=a: self.lancer(a)), a) for a in applis]

    def afficher(self, contenu):
        ligne = self.liste_cat.get_selected_row()
        titre = ligne.libelle if ligne else ""
        if contenu == "favoris":
            applis = [self.applis[i] for i in self.favoris]
            self.remplir(titre, self.lignes_applis(applis),
                         "Aucun favori : clic droit sur une appli → « Ajouter aux favoris »")
        elif contenu == "recents":
            ids = sorted((i for i in self.recents if i in self.applis),
                         key=lambda i: -self.recents[i])[:15]
            self.remplir(titre, self.lignes_applis([self.applis[i] for i in ids]),
                         "Les applis lancées depuis ce menu apparaîtront ici")
        elif contenu == "toutes":
            self.remplir(titre, self.lignes_applis(self.tri(self.applis.values())))
        elif contenu == "autres":
            connues = set().union(*(c for _, _, c in CATEGORIES))
            self.remplir(titre, self.lignes_applis(
                self.tri(a for a in self.applis.values() if not (a.cats & connues))))
        elif contenu == "dossiers":
            self.remplir(titre, self.lignes_dossiers())
        else:
            self.remplir(titre, self.lignes_applis(
                self.tri(a for a in self.applis.values() if a.cats & contenu)))

    def lignes_dossiers(self):
        D = GLib.UserDirectory
        dossiers = [
            ("user-home", "Dossier personnel", GLib.get_home_dir()),
            ("folder-documents", "Documents", GLib.get_user_special_dir(D.DIRECTORY_DOCUMENTS)),
            ("folder-download", "Téléchargements", GLib.get_user_special_dir(D.DIRECTORY_DOWNLOAD)),
            ("folder-pictures", "Images", GLib.get_user_special_dir(D.DIRECTORY_PICTURES)),
            ("folder-music", "Musique", GLib.get_user_special_dir(D.DIRECTORY_MUSIC)),
            ("folder-videos", "Vidéos", GLib.get_user_special_dir(D.DIRECTORY_VIDEOS)),
            ("user-trash", "Corbeille", "trash:/"),
        ]
        return [self.ligne_element(i, n, c if not c.startswith("trash") else "",
                                   (lambda c=c: self.executer(["dolphin", c])))
                for i, n, c in dossiers if c and (c.startswith("trash") or os.path.isdir(c))]

    def choisir_categorie(self, ligne):
        self.liste_cat.select_row(ligne)

    def survol_categorie(self, _w, _e, ligne):
        if self.recherche.get_text():
            return
        self.fin_survol()
        self.minuteur_survol = GLib.timeout_add(120, self.fin_minuteur, ligne)

    def fin_minuteur(self, ligne):
        self.minuteur_survol = None
        self.choisir_categorie(ligne)
        return False

    def fin_survol(self, *_):
        if self.minuteur_survol:
            GLib.source_remove(self.minuteur_survol)
            self.minuteur_survol = None

    def recherche_changee(self, entree):
        q = simplifier(entree.get_text().strip())
        if not q:
            ligne = self.liste_cat.get_selected_row() or self.lignes_cat[2]
            self.afficher(ligne.contenu)
            return
        resultats = []
        for a in self.applis.values():
            s = a.score(q)
            if s is not None:
                resultats.append((s, -self.recents.get(a.id, 0), a.cle_nom, a))
        resultats.sort(key=lambda t: t[:3])
        self.remplir("Résultats", self.lignes_applis([t[3] for t in resultats[:40]]),
                     "Aucune application trouvée")
        premier = self.liste.get_row_at_index(0)
        if premier and premier.get_selectable():
            self.liste.select_row(premier)

    # ── actions ─────────────────────────────────────────────────────────────
    def lancer(self, appli):
        self.recents[appli.id] = time.time()
        try:
            os.makedirs(os.path.dirname(RECENTS), exist_ok=True)
            with open(RECENTS, "w") as f:
                json.dump(self.recents, f)
        except OSError:
            pass
        contexte = Gdk.Display.get_default().get_app_launch_context()
        try:
            appli.info.launch([], contexte)
        except GLib.Error as err:
            print("Lancement impossible :", err, file=sys.stderr)
        self.fermer()

    def executer(self, commande):
        GLib.spawn_async(commande, flags=GLib.SpawnFlags.SEARCH_PATH)
        self.fermer()

    def lancer_premier(self, *_):
        ligne = self.liste.get_selected_row() or self.liste.get_row_at_index(0)
        if ligne and ligne.get_activatable():
            ligne.action()

    def clic_appli(self, _w, evenement, appli):
        if evenement.button != 3:
            return False
        menu = Gtk.Menu()
        if appli.id in self.favoris:
            item = Gtk.MenuItem(label="Retirer des favoris")
            item.connect("activate", lambda *_: self.changer_favori(appli, False))
        else:
            item = Gtk.MenuItem(label="Ajouter aux favoris")
            item.connect("activate", lambda *_: self.changer_favori(appli, True))
        menu.append(item)
        menu.show_all()
        menu.attach_to_widget(self.liste, None)
        menu.popup_at_pointer(evenement)
        return True

    def changer_favori(self, appli, ajouter):
        if ajouter and appli.id not in self.favoris:
            self.favoris.append(appli.id)
        elif not ajouter and appli.id in self.favoris:
            self.favoris.remove(appli.id)
        os.makedirs(DOSSIER, exist_ok=True)
        with open(FAVORIS, "w") as f:
            f.write("# Favoris du menu Démarrer (identifiants .desktop), dans l'ordre d'affichage\n")
            f.write("\n".join(self.favoris) + "\n")
        if self.recherche.get_text():
            self.recherche_changee(self.recherche)
        else:
            self.afficher(self.liste_cat.get_selected_row().contenu)

    def clic_fond(self, _w, evenement):
        alloc = self.menu.get_allocation()
        x, y = self.menu.translate_coordinates(self, 0, 0)
        if not (x <= evenement.x <= x + alloc.width and y <= evenement.y <= y + alloc.height):
            self.fermer()
        return False

    def touche(self, _w, evenement):
        if evenement.keyval == Gdk.KEY_Escape:
            if self.recherche.get_text():
                self.recherche.set_text("")
            else:
                self.fermer()
            return True
        # Taper n'importe où lance la recherche
        if not self.recherche.has_focus() and Gdk.keyval_to_unicode(evenement.keyval) > 32:
            self.recherche.grab_focus_without_selecting()
            return self.recherche.event(evenement)
        return False

    def touche_recherche(self, _w, evenement):
        if evenement.keyval in (Gdk.KEY_Down, Gdk.KEY_Tab):
            ligne = self.liste.get_selected_row() or self.liste.get_row_at_index(0)
            if ligne:
                suivante = self.liste.get_row_at_index(ligne.get_index() + 1) \
                    if self.liste.get_selected_row() else ligne
                cible = suivante or ligne
                self.liste.select_row(cible)
                cible.grab_focus()
            return True
        return False

    def touche_liste(self, _w, evenement):
        ligne = self.liste.get_selected_row()
        if evenement.keyval == Gdk.KEY_Up and ligne and ligne.get_index() == 0:
            self.recherche.grab_focus_without_selecting()
            return True
        return False

    def fermer(self):
        self.revealer.set_reveal_child(False)
        GLib.timeout_add(170, self.destroy)

    def quitter(self, *_):
        try:
            if open(VERROU).read().strip() == str(os.getpid()):
                os.remove(VERROU)
        except OSError:
            pass
        Gtk.main_quit()


def main():
    basculer_instance()
    reglages = Gtk.Settings.get_default()
    reglages.set_property("gtk-application-prefer-dark-theme", True)
    reglages.set_property("gtk-icon-theme-name", "Papirus-Dark")
    fournisseur = Gtk.CssProvider()
    fournisseur.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), fournisseur, Gtk.STYLE_PROVIDER_PRIORITY_USER)
    menu = Menu()
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, lambda: (menu.fermer(), False)[1])
    Gtk.main()


if __name__ == "__main__":
    main()
