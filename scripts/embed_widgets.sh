#!/usr/bin/env bash
# Embed a real WidgetKit extension in an already-built PKbrain bundle.
# Opt-in: the default ad-hoc/SwiftPM build keeps working without Xcode.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${1:?usage: embed_widgets.sh /path/to/PKbrain.app}"
: "${PK_WIDGET_TEAM:?Apple Development Team ID requis}"
: "${PK_WIDGET_APP_GROUP:?App Group autorisé pour les deux identifiants requis}"
: "${PK_WIDGET_SIGN_IDENTITY:?Identité de signature commune à l’app et à l’extension requise}"
# For group.* App Groups, pass the matching host provisioning profile too.
if [[ "$PK_WIDGET_APP_GROUP" == group.* && ! -f "${PK_WIDGET_HOST_PROFILE:-}" ]]; then
  echo "WidgetKit: PK_WIDGET_HOST_PROFILE doit désigner le profil de l’app autorisant cet App Group." >&2
  exit 1
fi
if [[ "$PK_WIDGET_APP_GROUP" != group.* && "$PK_WIDGET_APP_GROUP" != "$PK_WIDGET_TEAM".* ]]; then
  echo "WidgetKit: le groupe macOS doit commencer par le Team ID ou être un groupe group.* provisionné." >&2
  exit 1
fi
[[ -d "$APP/Contents/MacOS" ]] || { echo "Bundle app introuvable: $APP" >&2; exit 1; }
BUILD="${PK_WIDGET_BUILD_DIR:-$ROOT/.build/widgets}"
mkdir -p "$BUILD/project"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$APP/Contents/Info.plist")
# CFBundleShortVersionString must be numeric for the extension.
NUMERIC_VERSION="${VERSION%%-dev*}"
if [[ -n "${PK_WIDGET_PREBUILT_DIR:-}" ]]; then
  EXTENSION="$PK_WIDGET_PREBUILT_DIR"
else
  if ! xcrun --find xcodebuild >/dev/null 2>&1 ||
     ! xcrun --find appintentsmetadataprocessor >/dev/null 2>&1; then
    echo "WidgetKit: Xcode complet ou PK_WIDGET_PREBUILT_DIR (extension construite par la CI) requis." >&2
    exit 1
  fi
  command -v xcodegen >/dev/null || { echo "WidgetKit: xcodegen requis." >&2; exit 1; }
  xcodegen generate --spec "$ROOT/packaging/widgets/project.yml" --project "$BUILD/project"
  xcodebuild -project "$BUILD/project/PKbrainWidgets.xcodeproj" \
    -scheme PKbrainWidgets -configuration Release -destination 'platform=macOS' \
    -derivedDataPath "$BUILD/DerivedData" \
    DEVELOPMENT_TEAM="$PK_WIDGET_TEAM" PK_WIDGET_TEAM="$PK_WIDGET_TEAM" \
    PK_WIDGET_APP_GROUP="$PK_WIDGET_APP_GROUP" \
    PK_WIDGET_CONFIG_DIR="$ROOT/packaging/widgets" \
    MARKETING_VERSION="$NUMERIC_VERSION" CURRENT_PROJECT_VERSION="$BUNDLE_VERSION" \
    CODE_SIGN_IDENTITY="$PK_WIDGET_SIGN_IDENTITY" build
  EXTENSION="$BUILD/DerivedData/Build/Products/Release/PKbrainWidgets.appex"
fi
[[ -d "$EXTENSION" ]] || { echo "Extension non produite" >&2; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$EXTENSION/Contents/Info.plist")" == "io.github.mondary.pkbrain.widgets" ]] ||
  { echo "Identifiant d’extension incorrect" >&2; exit 1; }
STAGED="$BUILD/staged/PKbrainWidgets.appex"
mkdir -p "$(dirname "$STAGED")"
ditto "$EXTENSION" "$STAGED"
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $NUMERIC_VERSION" "$STAGED/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set CFBundleVersion $BUNDLE_VERSION" "$STAGED/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set PKbrainWidgetAppGroup $PK_WIDGET_APP_GROUP" "$STAGED/Contents/Info.plist"
cp "$ROOT/packaging/widgets/Widget.entitlements" "$BUILD/Widget.entitlements"
/usr/libexec/PlistBuddy -c "Set :com.apple.security.application-groups:0 $PK_WIDGET_APP_GROUP" "$BUILD/Widget.entitlements"
codesign --force --sign "$PK_WIDGET_SIGN_IDENTITY" --entitlements "$BUILD/Widget.entitlements" "$STAGED"
codesign --verify --strict "$STAGED"
TEAM="$(codesign -dv "$STAGED" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
[[ "$TEAM" == "$PK_WIDGET_TEAM" ]] || { echo "Équipe de signature incorrecte" >&2; exit 1; }

# Only mutate the supplied bundle after the extension build has succeeded.
mkdir -p "$APP/Contents/PlugIns"
ditto "$STAGED" "$APP/Contents/PlugIns/PKbrainWidgets.appex"
/usr/libexec/PlistBuddy -c "Delete PKbrainWidgetAppGroup" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add PKbrainWidgetAppGroup string $PK_WIDGET_APP_GROUP" "$APP/Contents/Info.plist"
if [[ -n "${PK_WIDGET_HOST_PROFILE:-}" ]]; then
  cp "$PK_WIDGET_HOST_PROFILE" "$APP/Contents/embedded.provisionprofile"
fi
cp "$ROOT/packaging/widgets/Host.entitlements" "$BUILD/Host.entitlements"
/usr/libexec/PlistBuddy -c "Set :com.apple.security.application-groups:0 $PK_WIDGET_APP_GROUP" "$BUILD/Host.entitlements"
# Sign inside-out, not --deep (which can overwrite an extension's entitlements).
if [[ -d "$APP/Contents/Frameworks" ]]; then
  while IFS= read -r item; do
    codesign --force --sign "$PK_WIDGET_SIGN_IDENTITY" "$item"
  done < <(find "$APP/Contents/Frameworks" -depth \( -name '*.xpc' -o -name '*.app' -o -name '*.framework' \) -type d)
fi
codesign --force --sign "$PK_WIDGET_SIGN_IDENTITY" --entitlements "$BUILD/Host.entitlements" "$APP"
codesign --verify --deep --strict "$APP"
echo "WidgetKit: extension embarquée et signature vérifiée. Validation dans la galerie macOS encore requise."
