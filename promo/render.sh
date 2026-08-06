#!/bin/bash
# beats -> frames -> mp4. The scene plays itself in the page; we only collect frames.
set -e
cd "$(dirname "$0")"
NAME=$1 BEATS=$2 W=$3 H=$4 SECS=$5 FPS=${6:-30}
B=$(python3 -c "import json,urllib.parse,sys;print(urllib.parse.quote(open(sys.argv[1]).read()))" "$BEATS")
URL="http://127.0.0.1:8899/?promo=1&beats=$B"
echo "▶ $NAME  ${W}x${H}  ${SECS}s @ ${FPS}fps"
node capture.mjs "$URL" "/tmp/frames-$NAME" "$W" "$H" "$SECS" "$FPS"
ffmpeg -y -loglevel error -framerate "$FPS" -i "/tmp/frames-$NAME/f%05d.png" \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart "$NAME.mp4"
echo "✓ $NAME.mp4  $(du -h "$NAME.mp4" | cut -f1)  $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$NAME.mp4")s"
