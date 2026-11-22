#!/usr/bin/env bash
# Runs the iOS tests on the first available iPhone simulator, whatever Xcode version is installed.
# Extra arguments are passed to xcodebuild, e.g. -only-testing:CatalogueUITests/RealBackendUITests
set -euo pipefail
cd "$(dirname "$0")/.."

device=$(xcrun simctl list devices available | grep -E '^\s+iPhone' | head -1 || true)
udid=$(echo "$device" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' || true)
if [ -z "$udid" ]; then
  echo "No iPhone simulator found. Add one in Xcode: Window > Devices and Simulators." >&2
  exit 1
fi
echo "Testing on: $(echo "$device" | sed -E 's/^[[:space:]]+//; s/ \([0-9A-F-]{36}\).*//')"

xcodebuild test -project apps/ios/Catalogue.xcodeproj -scheme Catalogue -destination "id=$udid" "$@"
