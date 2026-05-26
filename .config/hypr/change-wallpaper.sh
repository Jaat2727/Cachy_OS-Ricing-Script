#!/bin/bash

# --- CONFIGURATION ---
BASE="$HOME/Downloads/Wallpapers"
STATE_FILE="$HOME/.config/hypr/.last_wallpapers"
mkdir -p "$(dirname "$STATE_FILE")"

# --- RE-ADD THIS AS THE FIRST LINE OF change-wallpaper.sh ---
CURRENT_WS=$(hyprctl monitors | grep "active workspace" | awk '{print $3}' | tr -d '()' | tail -n 1)

# NOTE: The rest of change-wallpaper.sh remains the same, starting from the case statement.
# --- 1. IDENTIFY CURRENT WORKSPACE & FOLDER ---

echo "Current workspace: $CURRENT_WS"

# --- The rest of the script remains the same ---



# Map workspace to folder

case $CURRENT_WS in
    1) FOLDER="$BASE/Blue" ;;
    2) FOLDER="$BASE/Green" ;;
    3) FOLDER="$BASE/Purple" ;;
    4) FOLDER="$BASE/Red" ;;
    5) FOLDER="$BASE/Yellow" ;;
    *) FOLDER="$BASE/Blue" ;; # Fallback to Blue
esac

# --- 2. FIND NEXT WALLPAPER SEQUENTIALLY (Optimized Logic) ---

# List files and load into an indexed array (Robustly handles spaces/special chars)
mapfile -t FILES < <(find "$FOLDER" -maxdepth 1 -type f | sort)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No files found in $FOLDER. Exiting."
    exit 1
fi

# Get the path of the last used wallpaper for this workspace
LAST_WALL=$(grep "^${CURRENT_WS}|" "$STATE_FILE" 2>/dev/null | cut -d'|' -f2)

# Default to the first wallpaper's index (0)
NEXT_INDEX=0
FOUND=false

for i in "${!FILES[@]}"; do
    if [[ "${FILES[$i]}" == "$LAST_WALL" ]]; then
        # Last wallpaper found, set the next index (wrap around)
        NEXT_INDEX=$(( (i + 1) % ${#FILES[@]} ))
        FOUND=true
        break
    fi
done

# IMPORTANT: If the workspace is new (FOUND=false), NEXT_INDEX remains 0. 
# If the script is run on an existing workspace, it uses the NEXT_INDEX calculated in the loop.

WALL="${FILES[$NEXT_INDEX]}"

# --- 3. UPDATE STATE FILE (Simplified using sed for atomic update) ---
# We use '|' as the separator to avoid conflicts with file paths that might contain ':'
NEW_LINE="${CURRENT_WS}|${WALL}"

if grep -q "^${CURRENT_WS}|" "$STATE_FILE"; then
    # Replace existing line using sed -i (in-place update)
    sed -i "/^${CURRENT_WS}|/c\\$NEW_LINE" "$STATE_FILE"
else
    # Append new line
    echo "$NEW_LINE" >> "$STATE_FILE"
fi

killall swww 2>/dev/null
sleep 0.1

# --- VM DETECTION ---
# In VM environments, swww can crash due to GPU timing issues.
# Add a small delay to let the virtualized graphics stack stabilize.
is_vm() {
    if command -v systemd-detect-virt &>/dev/null; then
        [ "$(systemd-detect-virt)" != "none" ]
    elif [ -f /sys/class/dmi/id/product_name ]; then
        grep -qiE "virtualbox|vmware|qemu|kvm|hyperv" /sys/class/dmi/id/product_name 2>/dev/null
    else
        return 1
    fi
}

if is_vm; then
    echo "VM environment detected, adding delay for swww stability..."
    sleep 2
fi

# --- 4. APPLY WALLPAPER AND THEME ---
echo "Setting wallpaper: $WALL"
swww img "$WALL" --transition-fps 60 --transition-duration 1 --transition-type grow
cp "$WALL" ~/.config/hypr/current_wallpaper
convert ~/.config/hypr/current_wallpaper[0] ~/.config/hypr/current_wallpaper_static.png
wait


# Generate Matugen theme
matugen image "$WALL"
.config/hypr/keyb.sh
# Apply to Kitty
cp ~/.config/matugen/colors ~/.config/kitty/colors.conf
kitty @ set-colors ~/.config/kitty/colors.conf

# Apply to Waybar
cp ~/.config/matugen/colors.css ~/.config/waybar/colors.css
pkill -SIGUSR2 waybar
