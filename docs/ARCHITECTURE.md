# PKbrain Architecture

## Root Layout
- `src/`: main native app sources (Swift / macOS).
- `scripts/`: build, run, packaging scripts.
- `releases/`: packaged artifacts by platform.
- `design/`: UI references and mockups.
- `submodules/`: upstream inspirations / external code.
- `experiments/`: non-core prototypes and clones.

## Source Layout
- `src/macos/PKbrain/`: app target source root.
- `src/macos/PKbrain/App/`: app lifecycle and delegate.
- `src/macos/PKbrain/Views/`: SwiftUI views.
- `src/macos/PKbrain/Services/`: managers/controllers.
- `src/macos/PKbrain/Stores/`: persistence/settings.
- `src/macos/PKbrain/Resources/`: fonts, localizations, assets.

## Releases Layout
- `releases/macos/`
- `releases/windows/`
- `releases/linux/`
- `releases/ios/`
- `releases/android/`

## Naming Conventions
- Product name: `PKbrain`
- Clipboard feature label: `Clipboard`
- Sticky notes label: `Stickies`
- Bundle identifier: `io.github.mondary.pkbrain`
- URL scheme: `pkbrain`

## Notes
- Legacy Jorts strings remain only for migration/import compatibility and explicit inspiration references.
