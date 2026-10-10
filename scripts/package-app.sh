#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="${1:-$PROJECT_DIR/dist}"
APP="$DESTINATION/电源模式.app"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Helpers"
cp "$PROJECT_DIR/.build/release/PowerModes" "$APP/Contents/MacOS/PowerModes"
cp "$PROJECT_DIR/.build/release/PowerModesHelper" "$APP/Contents/Helpers/PowerModesHelper"
chmod 755 "$APP/Contents/Helpers/PowerModesHelper"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/CompiledAssets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$PROJECT_DIR/Resources/CompiledAssets/Assets.car" "$APP/Contents/Resources/Assets.car"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "$APP"
