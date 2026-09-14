# Changelog

Format Keep a Changelog — les versions suivent le CalVer `YYYY.MM.PATCH`.
Le fichier `VERSION` à la racine est la source de vérité.

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
