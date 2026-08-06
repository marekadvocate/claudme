#!/bin/bash
# The share card is a real screenshot of the page, not a mock of it — so it can never
# drift from what people actually land on. Serve docs/ and capture the hero at 1200x630.
set -e
cd "$(dirname "$0")"
python3 -m http.server 8971 --bind 127.0.0.1 >/dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null' EXIT
sleep 1
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
  --hide-scrollbars --window-size=1200,630 --virtual-time-budget=3500 \
  --screenshot="$PWD/og.png" "http://127.0.0.1:8971/?og=1" 2>/dev/null
echo "og.png written ($(wc -c < og.png) bytes)"
