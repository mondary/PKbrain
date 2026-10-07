# Changelog

Format Keep a Changelog — les versions suivent le CalVer `YYYY.MM.PATCH`.
`CHANGELOG.md` est la source de vérité de la version (les scripts de build la
lisent en tête de fichier ; `src/macos/PKbrain/Resources/VERSION` n'est qu'un
repli embarqué, régénéré à chaque version).

## [2026.10.1] - 2026-10-07

### Added
- Shell de réglages PKmonitor (skill pk-settings-shell) : sidebar 220 pt sur material, recherche profonde des réglages avec surlignage accent, groupes APP / NOTES / PROJETS PK, drapeaux de langue (FR/EN/IT/DE/ES, bascule immédiate) et version en pied — les réglages remplacent le contenu de la fenêtre PKclipboard avec bouton retour vers le studio.
- Section À propos refondue : texte éditorial, canal de mise à jour Stable/Dev, comparaison des dernières versions publiées des deux appcasts, bouton « Rechercher les mises à jour… », footer GitHub / Issues / Ko-fi.
- Section Crédits dans À propos (pattern Pulse) : Jorts, Numara Calculator, Caligator, developer-icons et PastePal nommés et liés, avec note d'implémentation indépendante.
- Page Soutenir (Ko-fi, carte café + CTA rouge, liens GitHub/Issues/projet original/profil PK) et Project Library partagée (10 projets PK, vedette PKbrain avec capture).
- Sparkle : dépendance + UpdaterManager avec canaux (clé "updateChannel"), clés SUFeedURL/SUPublicEDKey dans les Info.plist générés, appcast.xml/appcast-dev.xml squelettes.
- Clic droit sur l'icône de barre de menus : menu compact Settings / Soutenir sur Ko-fi / Rechercher les mises à jour / À propos / Quitter ; clic gauche réordonné (données d'abord, bloc d'actions compact) — chaque item porte un picto 16×16 inline aligné sur le logo Ko-fi.
- Argument de lancement `--open-settings [section]` pour ouvrir les réglages de façon scriptable.

### Changed
- « À propos » du menu et de la barre de menus ouvre désormais l'onglet À propos des Réglages (plus de panneau système).
- La version est lue dans CHANGELOG.md par les scripts de build (build dev : suffixe `-dev.HHMM` + CFBundleVersion epoch pour ordonner Dev/Stable dans Sparkle) ; package_macos.sh ne dépend plus du fichier VERSION racine supprimé.
- AppVersion lit d'abord CFBundleShortVersionString, avec repli sur la ressource VERSION embarquée.

### Fixed
- Versionnage incohérent : scripts hardcodés en 4.2.x, Resources/VERSION en retard, package_macos.sh cassé par la suppression du VERSION racine — tout converge vers le CalVer du CHANGELOG.
- Localisation : bloc « post-it sur les bords » codé en dur en français et carte OCR codée en dur en anglais désormais localisés dans les 5 langues (~75 nouvelles clés par langue, alignées sur les valeurs partagées PKmonitor/PKwindowsManagement).

### Removed
- Code mort : PreferencesWindowController, PreferencesView (NavigationSplitView), GlobalSettingsInClipboardView, PreferencePageHeader, PreferenceSidebarButton, ancien AboutPreferencesView et panneau About système.

## [2026.09.10] - 2026-10-01

### Added
- Bouton « Soutenir sur Ko-fi » également dans le hero du store (haut de page), en plus de la section téléchargement et du pied de page.

### Changed
- Les actions du hero passent à la ligne proprement sur petit écran (flex-wrap).

## [2026.09.9] - 2026-10-01

### Changed
- README FR/EN : les captures du projet amont Jorts sont remplacées par deux vues natives de PKbrain (tiroir presse-papiers, collection PKClipboard), déjà présentes dans le dépôt.

## [2026.09.8] - 2026-10-01

### Added
- Bouton « Soutenir sur Ko-fi » dédié sur la landing store, en plus du lien du pied de page ; badge et section Ko-fi dans les README FR/EN.
- Commande `curl` de téléchargement direct du DMG à côté du `brew install`, avec bouton copier.
- Asset `PKbrain.dmg` à nom stable publié sur la release GitHub : le lien `releases/latest/download/PKbrain.dmg` reste valable d'une version à l'autre.

### Changed
- Les boutons « Télécharger pour Mac » du store (haut et bas de page) pointent désormais vers le DMG de la dernière release en téléchargement direct, au lieu de la page des releases.

## [Unreleased]

### Added
- Landing page animée et responsive dans `store2/`, avec démonstrations des notes, du presse-papiers et de la palette de commandes.
- Playground de présentation dans `store/` : bureau Mac interactif (tiroir presse-papiers, collection par application, sticky notes converties depuis l'historique) et captures natives régénérables via `store/tools/capture-native.swift`.

### Changed
- Un seul dossier `store/` organisé en deux sous-dossiers : `store/website/` (landing 100 % autonome, contenu à héberger tel quel) et `store/app-store/` (laius, bannières, captures de listing) ; vidéo de démo supprimée, captures régénérées depuis le natif, bannière recomposée.

## [2026.09.7] - 2026-09-17

### Changed
- Refacto racine du dépôt : product.html déplacé dans store/ (+ product2.html avec vraies captures), icônes archivées dans design/icons/, dossier experiments et outillage pnpm supprimés.


## [2026.09.6] - 2026-09-16

### Added
- Choix des bords utilisés par les post-it (gauche, droite, bas) dans les réglages.

## [2026.09.5] - 2026-09-14

### Changed
- Les post-it de bord sont désormais masqués et décollés par défaut ; l’affichage collé aux bords reste une option.

## [2026.09.4] - 2026-09-14

### Added
- Option pour afficher ou masquer les petits post-it collés aux bords de l’écran.

## [2026.09.3] - 2026-09-14

### Added
- Choix de la destination des résultats OCR : presse-papiers, fenêtre, ou les deux.

## [2026.09.2] - 2026-09-14

### Changed
- Ajustement du masquage des stickers inférieurs et incrément de version.

## [2026.09.1] - 2026-09-14

### Changed
- Bump de version : cumule les modifications du jour (decks de bords, OCR, CalVer).

## [2026.09.0] - 2026-09-14

### Added
- OCR de capture d'écran façon TRex : sélection d'écran native (`screencapture -i`), reconnaissance de texte Vision (fr-FR + en-US), texte copié dans le presse-papiers + panneau de résultat flottant éditable près du curseur, gestion de la permission Screen Recording.
- Raccourci global ⌥⌘O pour l'OCR, configurable dans Préférences → Raccourcis, visible dans la dropdown du menu bar.
- Numéro de version affiché en bas de la dropdown du menu bar.

### Changed
- Passage du versioning en CalVer `YYYY.MM.PATCH` (fichier `VERSION`).

### Fixed
- Les decks de bords n'affichent plus les mêmes notes sur les trois bords : chaque bord ne déploie que sa part (round-robin bas → gauche → droite).
- `scripts/restart_pkbrain.sh` pointait sur un ancien chemin de projet.
