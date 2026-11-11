# store — Dossier de présentation PKbrain

- `website/` — **la landing page à héberger** : dossier 100 % autonome (HTML +
  CSS + JS + assets, chemins relatifs, aucun serveur requis). Landing bilingue
  FR/EN dans un seul fichier : détection automatique de la langue
  (`navigator.languages`, défaut FR), bascule manuelle mémorisée en
  `localStorage`, contenu FR lisible sans JavaScript. C'est tout son contenu
  que l'on uploade (Netlify/Vercel Drop, GitHub Pages, FTP).
- `app-store/` — **matériel de listing** pour la publication de l'app :
  laïus (`description-store.md`), bannière `banner-1544x500.png`, card
  `card-1200x675.png` et `screenshots/` (captures natives).
- `archive/` — versions remplacées, jamais supprimées : `site/` conserve
  l'ancienne page « bureau Mac interactif » (2026.09.x).
- `tools/` — harness de régénération des captures (voir la skill
  `premium-promo-media`).

## Aperçu local

```sh
python3 -m http.server 8000 --directory store/website   # puis http://localhost:8000/
```

## Régénérer les captures natives (`website/assets/*.png`)

Les captures sont rendues depuis les vues SwiftUI/AppKit actuelles du dépôt,
avec un jeu de données de démonstration (aucune donnée utilisateur lue) :
notes pastel, tiroir presse-papiers, fenêtre PKClipboard et vue Notes
archivées. Le harness compile les vraies vues ; il exclut
`Services/UpdaterManager.swift` (dépendance Sparkle) et fournit le strict
minimum de surface via `store/tools/capture-shims.swift`.

```sh
SC=/tmp/pkbrain-capture && mkdir -p "$SC/services"
cp src/macos/PKbrain/Services/*.swift "$SC/services/" && rm "$SC/services/UpdaterManager.swift"
swiftc -swift-version 5 -target arm64-apple-macos13.0 \
  -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk \
  -whole-module-optimization -Onone \
  src/macos/PKbrain/Models/*.swift src/macos/PKbrain/Stores/*.swift \
  src/macos/PKbrain/Support/*.swift "$SC/services"/*.swift \
  src/macos/PKbrain/Views/*.swift src/macos/PKbrain/Views/Preferences/*.swift \
  src/macos/PKbrain/Views/Settings/*.swift \
  store/tools/capture-shims.swift store/tools/capture-native.swift \
  -o "$SC/PKbrainCapture"
ln -sfn "$PWD/releases/PKbrain.app/Contents/Resources/PKbrain_PKbrain.bundle" \
  "$SC/PKbrain_PKbrain.bundle"
"$SC/PKbrainCapture" "$PWD/store/website/assets"
```

Puis dériver les captures de listing et la bannière :

```sh
magick store/website/assets/drawer.png   -resize 1440x store/app-store/screenshots/01-presse-papiers-tiroir.png
magick store/website/assets/library.png  -resize 1440x store/app-store/screenshots/02-pkclipboard-par-application.png
magick store/website/assets/archives.png -resize 1440x store/app-store/screenshots/04-notes-archivees.png
# 03-notes-autocollantes.png : les trois notes côte à côte (montage +append)
# app-store/banner-1544x500.png : wallpaper + drawer centré avec ombre portée
```

Le fond d'écran (`website/assets/wallpaper-*.webp`) provient d'une maquette de
référence : `python3 store/tools/prepare-assets.py <référence.html> <sortie.jpg>`.

## Checklist landing (avant upload)

- Bascule FR ↔ EN au clavier (boutons `aria-pressed`), attribut `lang` et
  métadonnées mis à jour ; rendu complet dans chaque langue.
- Sans JavaScript : version FR complète et lisible.
- CTA principal → `releases/latest/download/PKbrain.dmg` (asset réel) ; badge
  de version via l'API GitHub ; commandes `brew` / `curl` copiables.
- Ko-fi (`https://ko-fi.com/pouark`) visible près du CTA et dans le pied de
  page, `rel="noopener noreferrer"`.
- Vérifier 390 / 768 / 1440 px et `prefers-reduced-motion`.
