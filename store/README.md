# store — Dossier de présentation PKbrain

Un seul dossier pour tout le matériel de présentation :

- `index.html` + `style.css` + `app.js` + `model.js` — la landing page et son
  bureau Mac interactif (tiroir presse-papiers, collection par application,
  sticky notes converties depuis l'historique).
- `description-store.md` — le laïus du listing (FR/EN).
- `assets/` — assets web (captures natives, fonds d'écran, icônes) + assets de
  listing (`banner-1544x500.png`, `card-1200x675.png`).
- `screenshots/` — captures du listing, dérivées des captures natives.
- `tools/` — harness de régénération (voir la skill `premium-promo-media`).

## Aperçu local

```sh
python3 -m http.server 8000 --directory store   # puis http://localhost:8000/
```

## Régénérer les captures natives (`assets/*.png`)

Les captures sont rendues depuis les vues SwiftUI/AppKit actuelles du dépôt,
avec un jeu de données de démonstration (aucune donnée utilisateur lue) :

```sh
mkdir -p /tmp/pkbrain-capture
swiftc -swift-version 5 -target arm64-apple-macos13.0 \
  -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk \
  -whole-module-optimization -Onone \
  src/macos/PKbrain/Models/*.swift src/macos/PKbrain/Stores/*.swift \
  src/macos/PKbrain/Support/*.swift src/macos/PKbrain/Services/*.swift \
  src/macos/PKbrain/Views/*.swift src/macos/PKbrain/Views/Preferences/*.swift \
  store/tools/capture-native.swift -o /tmp/pkbrain-capture/PKbrainCapture
ln -sfn "$PWD/releases/PKbrain.app/Contents/Resources/PKbrain_PKbrain.bundle" \
  /tmp/pkbrain-capture/PKbrain_PKbrain.bundle
/tmp/pkbrain-capture/PKbrainCapture "$PWD/store/assets"
```

Puis dériver les captures de listing et la bannière :

```sh
magick store/assets/drawer.png  -resize 1440x store/screenshots/01-presse-papiers-tiroir.png
magick store/assets/library.png -resize 1440x store/screenshots/02-pkclipboard-par-application.png
# 03-notes-autocollantes.png : les trois notes côte à côte (montage)
# banner-1544x500.png : wallpaper + drawer centré avec ombre portée
```

Le fond d'écran (`assets/wallpaper-*.webp`) provient d'une maquette de
référence : `python3 store/tools/prepare-assets.py <référence.html> <sortie.jpg>`.
