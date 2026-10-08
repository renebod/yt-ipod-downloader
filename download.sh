#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="$SCRIPT_DIR/downloads"
TEMP="$(mktemp -d "$SCRIPT_DIR/.download-tmp.XXXXXX")"
trap 'rm -rf -- "$TEMP"' EXIT

mkdir -p "$OUTPUT"

yt-dlp \
    --batch-file "$SCRIPT_DIR/urls.txt" \
    -f 140 \
    --write-thumbnail \
    --convert-thumbnails jpg \
    --embed-metadata \
    --no-embed-thumbnail \
    -o "$TEMP/%(title)s.%(ext)s"

for audio in "$TEMP"/*.m4a; do
    [ -e "$audio" ] || continue

    title="${audio##*/}"
    title="${title%.m4a}"
    thumbnail="$TEMP/$title.jpg"

    if [ -f "$thumbnail" ]; then
        ffmpeg -hide_banner -loglevel error -y \
            -i "$audio" -i "$thumbnail" \
            -map 0:a -map 1:v \
            -map_metadata 0 \
            -c:a copy -c:v mjpeg \
            -vf 'scale=1000:1000:force_original_aspect_ratio=increase,crop=1000:1000' \
            -metadata:s:v title=Cover \
            -metadata:s:v 'comment=Cover (Front)' \
            -disposition:v attached_pic -f mp4 \
            "$OUTPUT/$title.m4a"
    else
        cp -f "$audio" "$OUTPUT/$title.m4a"
    fi

    echo "✓ $title"
done

echo "Done! Files are in: $OUTPUT/"
