#!/bin/zsh
set -euo pipefail

version="${VERSION:?Set VERSION, for example 1.0.0}"
output_dir="${OUTPUT_DIR:-$PWD/.build/release}"
app_path="${APP_PATH:-$PWD/.build/xcode/Build/Products/Release/CapsAwake.app}"
identity="${APPLE_SIGNING_IDENTITY:-}"

mkdir -p "$output_dir"
if [[ ! -d "$app_path" ]]; then
  CONFIGURATION=Release DERIVED_DATA_PATH="$PWD/.build/xcode" "$PWD/Scripts/build-app.sh"
fi

if [[ -n "$identity" ]]; then
  codesign --deep --force --options runtime --timestamp --sign "$identity" "$app_path"
fi

ditto -c -k --keepParent "$app_path" "$output_dir/CapsAwake.zip"
(cd "$output_dir" && shasum -a 256 CapsAwake.zip > CapsAwake.zip.sha256)

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]]; then
  xcrun notarytool submit "$output_dir/CapsAwake.zip" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait
  xcrun stapler staple "$app_path"
  ditto -c -k --keepParent "$app_path" "$output_dir/CapsAwake-notarized.zip"
  (cd "$output_dir" && shasum -a 256 CapsAwake-notarized.zip > CapsAwake-notarized.zip.sha256)
fi
