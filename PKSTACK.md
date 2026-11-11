# PKSTACK — PKbrain

Cartographie des skills du hub agent utilisées sur ce projet et de leurs livrables
(convention `-pk-COMMIT` §4). Dernière mise à jour : 2026.11.1.

| Skill | Usage sur le projet | Livrables |
|---|---|---|
| `-pk-COMMIT` | Commits (`ADD`/`FIX`/`REFACTO`/`MAJ`), CalVer `YYYY.MM.PATCH`, CHANGELOG source de vérité, README FR/EN synchronisés, lien Ko-fi | `CHANGELOG.md`, `README.md`, `README_en.md` |
| `macos-build` | Compilation et vérification de l'app native depuis le CLI | `swift build`, bundle `releases/PKbrain.app` |
| `macos-patterns` | Référentiel des patterns natifs macOS (fenêtres, menus, raccourcis Carbon, activation) appliqué aux développements AppKit/SwiftUI | code `src/macos/PKbrain/` |
| `app-presence-sync` | Synchronisation de la présence produit (README FR/EN, landing, hub `Web_HubApps`) lors des features visibles | `store/`, `Web_HubApps/index.html` (à la demande) |
| `premium-promo-media` | Kit média store, captures natives et landing promotionnelle bilingue | `store/website/`, `store/app-store/` |

> Les interventions antérieures à 2026.11.1 n'ont pas été tracées ici ; ce fichier
> démarre avec l'archivage des notes (2026.11.1).
