#!/bin/zsh
set -euo pipefail

configuration="${CONFIGURATION:-Release}"
derived_data="${DERIVED_DATA_PATH:-$PWD/.build/xcode}"

xcodegen generate
xcodebuild \
  -project CapsAwake.xcodeproj \
  -scheme CapsAwake \
  -configuration "$configuration" \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$derived_data" \
  build
