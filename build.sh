#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP=build/Claudme.app
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O Sources/*.swift \
  -o "$APP/Contents/MacOS/Claudme" \
  -framework AppKit -framework Network -framework QuartzCore -framework CoreAudio

cp Info.plist "$APP/Contents/Info.plist"

# App icon. Regenerated from tools/logo.swift only when the source model changes,
# so a plain clone builds without needing to run the generator.
if [ ! -f assets/Claudme.icns ] || [ tools/logo.swift -nt assets/Claudme.icns ]; then
  if command -v swiftc >/dev/null && command -v iconutil >/dev/null; then
    swiftc -O tools/logo.swift -o build/logogen 2>/dev/null \
      && build/logogen assets >/dev/null \
      && iconutil -c icns assets/Claudme.iconset -o assets/Claudme.icns
  fi
fi
[ -f assets/Claudme.icns ] && cp assets/Claudme.icns "$APP/Contents/Resources/Claudme.icns"
[ -f assets/menubar.png ] && cp assets/menubar.png "$APP/Contents/Resources/menubar.png"

codesign --force -s - "$APP" >/dev/null 2>&1 || true

echo "Built $APP"
