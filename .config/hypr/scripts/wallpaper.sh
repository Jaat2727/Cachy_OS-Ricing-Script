#!/bin/bash
WALLPAPER_DIR="$HOME/Downloads/Wallpapers"
SWWW_TRANSITIONS=(wipe grow wave fade outer)
INTERVAL=300

while true; do
    mapfile -t WALLS < <(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \))
    [ ${#WALLS[@]} -eq 0 ] && sleep "$INTERVAL" && continue
    WALL="${WALLS[RANDOM % ${#WALLS[@]}]}"
    TRANS="${SWWW_TRANSITIONS[RANDOM % ${#SWWW_TRANSITIONS[@]}]}"
    ANGLE=$((RANDOM % 360))

    swww img "$WALL" \
        --transition-type "$TRANS" \
        --transition-duration 2 \
        --transition-angle "$ANGLE" \
        --transition-fps 60 \
        --transition-bezier .43,1.19,1,.4

    matugen image "$WALL"
    sleep "$INTERVAL"
done
