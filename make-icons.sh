#!/bin/bash
set -e

ICONSET="SpotifyController.iconset"
SVG="icon.svg"
TMP="/tmp/icon_1024.png"

echo "Rendering SVG → PNG..."
# Use Quick Look to render the SVG at 1024×1024
qlmanage -t -s 1024 -o /tmp "$SVG" > /dev/null 2>&1
# qlmanage appends .png to the filename
mv /tmp/icon.svg.png "$TMP"

echo "Creating iconset..."
mkdir -p "$ICONSET"

sizes=(16 32 64 128 256 512 1024)
for size in "${sizes[@]}"; do
  sips -z "$size" "$size" "$TMP" --out "/tmp/icon_${size}.png" > /dev/null
done

# macOS iconset naming convention
cp /tmp/icon_16.png    "$ICONSET/icon_16x16.png"
cp /tmp/icon_32.png    "$ICONSET/icon_16x16@2x.png"
cp /tmp/icon_32.png    "$ICONSET/icon_32x32.png"
cp /tmp/icon_64.png    "$ICONSET/icon_32x32@2x.png"
cp /tmp/icon_128.png   "$ICONSET/icon_128x128.png"
cp /tmp/icon_256.png   "$ICONSET/icon_128x128@2x.png"
cp /tmp/icon_256.png   "$ICONSET/icon_256x256.png"
cp /tmp/icon_512.png   "$ICONSET/icon_256x256@2x.png"
cp /tmp/icon_512.png   "$ICONSET/icon_512x512.png"
cp /tmp/icon_1024.png  "$ICONSET/icon_512x512@2x.png"

echo "Compiling .icns..."
iconutil -c icns "$ICONSET" -o SpotifyController.icns

echo "Done → SpotifyController.icns"
