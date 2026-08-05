#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP=build/Claudme.app
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O Sources/*.swift \
  -o "$APP/Contents/MacOS/Claudme" \
  -framework AppKit -framework Network -framework QuartzCore

cp Info.plist "$APP/Contents/Info.plist"
codesign --force -s - "$APP" >/dev/null 2>&1 || true

echo "Built $APP"
