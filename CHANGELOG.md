# Changelog

Format Keep a Changelog — les versions suivent le CalVer `YYYY.MM.PATCH`.
Le fichier `VERSION` à la racine est la source de vérité.

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
