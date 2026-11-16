#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SDK="${SDKROOT:-}"
if [[ -z "$SDK" ]]; then
  if ! xcode-select -p | grep -q Xcode && [[ -d /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk ]]; then
    SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
  else
    SDK="$(xcrun --sdk macosx --show-sdk-path)"
  fi
fi
SCRATCH="$(mktemp -d "${PKBRAIN_TEST_TEMP:-${TMPDIR:-/tmp}}/pkbrain-checks.XXXXXX")"
trap 'rm -f "$SCRATCH/checks"; rmdir "$SCRATCH"' EXIT
swiftc -swift-version 5 -sdk "$SDK" -whole-module-optimization -Onone \
  src/macos/PKbrain/Models/{NoteData,NoteTheme,NoteVersion,FontFamily,RandomContent,NoteDocument,DrawerAppearance,WidgetNoteSnapshot}.swift \
  src/macos/PKbrain/Support/{Comparable+Clamp,Color+Hex,NoteTheme+Colors}.swift \
  src/macos/PKbrain/Services/NoteWidgetPublisher.swift \
  Tests/WidgetAndDrawerChecks.swift -o "$SCRATCH/checks"
"$SCRATCH/checks"
# Type-check the actual widget against the macOS 14+ extension API surface.
swiftc -typecheck -parse-as-library -application-extension -swift-version 5 \
  -target "$(uname -m)-apple-macos14.0" -sdk "$SDK" \
  src/macos/PKbrain/Models/WidgetNoteSnapshot.swift src/widgets/PKbrainWidgets.swift
echo "PASS: WidgetKit extension type-check."
