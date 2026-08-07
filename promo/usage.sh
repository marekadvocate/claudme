#!/bin/bash
# Renders the two-second opener at a given size. Separate from render.sh because it uses
# ?usage instead of ?promo and carries no beat sheet.
set -e
cd "$(dirname "$0")"
NAME=$1 W=$2 H=$3
node capture.mjs "http://127.0.0.1:8899/?usage=1" "/tmp/frames-$NAME" "$W" "$H" 2 15
ffmpeg -y -loglevel error -framerate 15 -i "/tmp/frames-$NAME/f%05d.jpg" \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart "$NAME.mp4"
echo "✓ $NAME.mp4 $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$NAME.mp4")s"
