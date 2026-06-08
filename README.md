# PKbrain
## 🔥 V3 - MAJOR UPDATE

![Project icon](icon.png)

[🇫🇷 FR](README.md) · [🇬🇧 EN](README_en.md)

✨ Application de notes native macOS inspirée de la lignée PKbrain, avec calcul inline, palette de commandes et gestion avancée des raccourcis.

![Aperçu Jorts](https://github.com/elly-code/jorts/blob/main/data/screenshots/spread.png)
![Preferences Light](https://github.com/elly-code/jorts/blob/main/data/screenshots/preferences-light.png)
![Preferences Dark](https://github.com/elly-code/jorts/blob/main/data/screenshots/preferences-dark.png)
![Default Theme](https://github.com/elly-code/jorts/blob/main/data/screenshots/default.png)

## ✅ Fonctionnalités
- Port natif macOS (SwiftUI/AppKit) inspiré de Jorts.
- Palette de commandes (`Cmd+K`) avec:
  - recherche titre/contenu
  - navigation clavier
  - ouverture note
  - création note
  - ouverture Préférences / À propos
- Raccourcis clavier éditables dans les préférences (modificateurs + touche).
- Deux raccourcis globaux configurables:
  - focus dernière note
  - création nouvelle note
- Rechargement dynamique des raccourcis dans les menus.
- Calcul inline dans les notes:
  - évaluation en direct
  - variables par lignes
  - conversions d’unités
  - parsing d’expressions dans l’éditeur
- Icônes inline automatiques:
  - intégration du catalogue `developer-icons`
  - insertion d’icône à la fin d’un mot reconnu
  - plus de 300 icônes techniques disponibles
- Options de calcul inline activables/désactivables dans les réglages.
- Moteur de saisie texte enrichi:
  - toggle listes
  - toggle monospace
  - zoom in/out/reset
  - effets de frappe
- Fenêtre liste des notes (notes actives + corbeille).
- Restauration des notes depuis corbeille.
- Gestion couleurs/thèmes:
  - sélecteur couleur
  - contraste texte auto
  - prévisualisation des couleurs
- Clipboard drawer global:
  - refonte visuelle inspirée `deck2.html` (header/toolbar/viewport/cartes/actions)
  - capture texte, URL, images, fichiers et couleurs hex
  - historique persistant dans le dossier de stockage
  - pictogrammes de l'application source pour chaque item
  - recherche instantanée + filtres par type
  - filtres par source, favoris et récent
  - pins, lock, suppression item par item
  - navigation clavier complète
  - `Enter` et `Cmd+V` collent la carte sélectionnée dans la dernière app externe active
  - collage direct validé depuis le drawer et la fenêtre standard `PKClipboard`
  - restauration fiable de l'app cible avant injection de `Cmd+V`
  - `Cmd+Enter` convertit l'item en note
  - aperçu image complet sans crop + lightbox
  - aperçu URL enrichi (titre, favicon, description, thumbnail)
  - QuickLook pour les fichiers
  - aperçu couleur intelligent avec Hex/RGB/HSL/OKLCH
  - position du drawer configurable: haut, bas, gauche, droite
  - clic hors drawer: fermeture automatique
  - `Esc` en 2 temps:
    - 1er `Esc`: reset contexte (catégorie/filtres/recherche/sélection) vers la carte la plus récente
    - 2e `Esc`: fermeture du drawer
  - catégories simplifiées par pictos: Tout / Images / Texte / URL
  - bouton dédié pour ouvrir la fenêtre `PKClipboard` depuis le drawer
  - recherche: animation d'ouverture au clic, `Cmd+F`, et à la première frappe
  - correction saisie recherche: plus d'écrasement de la 1re lettre
  - bande animée basse en pleine largeur du drawer
  - cartes format plus carré/polaroid
  - cartes centrées dans le drawer vertical (left/right)
  - drawer vertical plus compact (largeur minimale réduite)
  - ouverture drawer priorise l'écran actif (multi-écrans)
  - position haute collée à la barre de menu macOS, sans espace visible
  - fallback icône app au lancement direct (`swift run`) pour `Cmd+Tab`
  - clic droit sur carte clipboard: épingler, verrouiller, copier, convertir en note ou supprimer
 - Fenêtre standard PKClipboard:
  - taille par défaut: 1200x1000
  - raccourcis visuels limités aux 9 premières tuiles (`⌘1` ... `⌘9`)
  - navigation clavier activée (flèches + Entrée)
  - `Enter` copie puis colle la carte sélectionnée dans la dernière app externe active
  - fermeture/masquage automatique de `PKClipboard` avant collage pour préserver la cible
  - `Esc` ferme la fenêtre standard
  - pagination fonctionnelle avec pages cliquables
 - nombre d'items par page dynamique selon la taille visible de la grille
  - layout renforcé au resize (haut/bas non tronqués)
  - anti-chevauchement fenêtres: masquage des notes lors de l'ouverture du drawer/PKClipboard
  - focus clavier renforcé du drawer pour éviter saisie partagée note/clipboard
  - clic droit sur carte: menu tags (taguer/retirer/nouveau tag)
  - double-clic sur carte: aperçu agrandi consultable (texte complet, URL, fichiers, image)
  - exception note: double-clic ouvre directement la sticky note
  - tags persistants multi-app avec filtre sidebar par tag
  - tags aussi disponibles sur cartes notes (session PKClipboard)
  - compteurs discrets alignés à droite pour tags et applications
  - `Cmd+Option+V` branché en global hotkey (ouverture directe PKClipboard)
  - preview agrandi en popover, fermeture par clic extérieur + `Esc`
  - cartes notes rendues en style sticky note (fond/thème distinctifs)
  - boutons rapides `Paramètres` + `Ouvrir dossier local` ajoutés dans drawer et PKClipboard
  - mode `Settings` intégré:
    - bouton paramètres en footer qui bascule toute la fenêtre en mode paramètres
    - sidebar dédiée (`General`, `Shortcuts`, `Clipboard`, `About`)
    - écran principal dynamique selon la section sélectionnée
    - sortie mode paramètres via `Esc` ou bouton `Retour`
  - `Cmd+,` redirigé vers `PKClipboard` en mode paramètres (plus de popup séparé)
  - section backup complète dans paramètres clipboard (export/restore dossier de données complet)
  - gestion corbeille notes enrichie: clic droit par ligne `Restaurer` / `Supprimer`
- Persistance et stockage:
  - stockage Markdown par note
  - métadonnées note en fin de fichier (`<!-- JORTS_META ... -->`)
  - JSON d’historique de versions
  - migration JSON legacy -> Markdown
  - consolidation des doublons
  - canonicalisation/cleanup
- Opérations données:
  - import/export
  - archivage doublons/backups
  - backup automatique vers un dossier choisi, avec intervalle réglable et snapshots horodatés
  - ouverture dossier de stockage dans Finder
- Internationalisation:
  - ressources localisées
  - changement de langue via préférences
- Gestion fenêtres:
  - comportement natif palette flottante
  - restauration focus fenêtre après palette
  - persistance notes ouvertes/fermées au relaunch (seules les notes ouvertes se rouvrent)
- App séparée:
  - `PKwindowsManagement/` contient l’outil standalone de gestion de fenêtres
  - lancement: `cd ../PKwindowsManagement && swift run`
  - cible dédiée pour tester les raccourcis de snap hors de `PKbrain`
- Menubar native:
  - actions rapides
  - entrée dédiée: afficher le tiroir presse-papiers
  - accès settings/about/restart/quit
- Refactor repo:
  - `PKbrain/` pour le code app
  - `submodules/jorts` pour la source d’inspiration
  - `submodules/developer-icons` pour la source des icônes techniques
  - `releases/` dédié artefacts

## 🧠 Utilisation
- Lancement dev: `./src/run-dev.sh`
- Ouvrir la palette: `Cmd+K`
- Préférences: `Cmd+,`
- Raccourcis globaux (par défaut, configurables):
  - `Cmd+Shift+Space` : rouvrir / focus la dernière note
  - `Ctrl+Shift+Space` : créer une nouvelle note
- Intégration Spotlight / Raycast / Alfred (URLs):
  - Nouvelle note: `pkbrain://new`
  - Rouvrir la dernière note: `pkbrain://last`
  - Afficher la liste des notes: `pkbrain://list`
  - Ouvrir le clipboard: `pkbrain://clipboard`
- Dossier de stockage par défaut: `~/Documents/PKbrain/`

### Clipboard drawer
- Toggle: `Cmd+Shift+V`
- Ouvrir `PKClipboard` (fenêtre standard): `Cmd+Option+V`
- Navigation: flèches gauche/droite
- `Enter`: copie puis colle dans la dernière app externe active + ferme le drawer ou masque `PKClipboard`
- `Cmd+V`: copie puis colle directement la carte sélectionnée vers la dernière app externe active
- `Cmd+C`: copie la carte sélectionnée vers le presse-papier système
- Clic droit sur carte: épingler, verrouiller, copier, convertir en note ou supprimer
- badges raccourcis visibles sur les 9 premières cartes (`⌘1...⌘9`)
- Clic hors drawer: ferme le drawer
- `Cmd+Enter`: convertir en note
- Filtres: texte, URL, image, fichier, couleur, source, épinglé, récent
- Couleurs: copier `#2C3861` crée une carte couleur avec:
  - Hex: `#2C3861`
  - RGB: `44, 56, 97`
  - HSL: `226, 38, 28`
  - OKLCH: aperçu calculé automatiquement

> Le collage direct nécessite l'autorisation macOS **Accessibilité** pour PKbrain. macOS affiche la demande au premier collage; l'autorisation peut aussi être gérée dans **Réglages Système > Confidentialité et sécurité > Accessibilité**.

## ⚙️ Réglages
- Préférences générales (langue, stockage, import/export).
- Préférences raccourcis (modificateurs + touche).
- Activation/désactivation du calcul inline.
- Position du clipboard drawer.
- Backup automatique vers un dossier choisi, avec intervalle réglable.

## 🧾 Commandes
- `./src/run-dev.sh` : build + package + run
- `swift build` : build SwiftPM

## 📦 Build & Package
- Le script `scripts/build_macos.sh` reconstruit le bundle `.app` local en mode `dev`.
- Le script `scripts/package_macos.sh` reconstruit le bundle `.app` local en mode `release`.
- Le bundle de test est généré dans `releases/PKbrain.app`.
- La copie officielle à lancer peut être placée dans `/Applications/PKbrain.app`.
- `dist` pointe vers `../releases`.
- La cible SwiftPM pointe sur `src/macos/PKbrain`.

## 🧪 Installation (Antigravity)
- Non utilisé pour ce projet actuellement.

## 🧾 Changelog
- `182f57a` : ajout icônes inline dans les notes.
- `d06eea4` : refactor structure repo (`PKbrain/`, `submodules/jorts`, `releases`).
- `f9c95c5` : shortcuts globaux configurables + unification run dev + stockage par défaut.
- `45a7297` : nouveaux raccourcis + traduction.
- `8e97ab3` : ajout palette de commandes.
- `0aedc51` : ajouts calcul inline.

## 🔗 Liens
- Repo source d’inspiration (Jorts): https://github.com/elly-code/jorts
- Inspirations calcul:
  - https://github.com/bornova/numara-calculator
  - https://github.com/teamxenox/caligator
- README EN: [README_en.md](README_en.md)
