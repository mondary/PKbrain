# store3 — Playground PKbrain

Landing page + bureau Mac interactif : tiroir presse-papiers, collection par
application, sticky notes converties depuis l'historique.

## Aperçu local

```sh
python3 -m http.server 8000 --directory store3   # puis http://localhost:8000/
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
  store3/tools/capture-native.swift -o /tmp/pkbrain-capture/PKbrainCapture
ln -sfn "$PWD/releases/PKbrain.app/Contents/Resources/PKbrain_PKbrain.bundle" \
  /tmp/pkbrain-capture/PKbrain_PKbrain.bundle
/tmp/pkbrain-capture/PKbrainCapture "$PWD/store3/assets"
```

Le fond d'écran (`assets/wallpaper.webp`) provient de la maquette de référence
fournie : `python3 store3/tools/prepare-assets.py <référence.html> <sortie.jpg>`.
