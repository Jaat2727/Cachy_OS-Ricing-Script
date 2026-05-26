#!/bin/bash

# Define a log file path for debugging
LOG_FILE="/tmp/switch_and_theme.log"
# Start a new log entry
echo "--- $(date) ---" >> $LOG_FILE
echo "Script started." >> $LOG_FILE

TARGET_WORKSPACE=$1

if [ -z "$TARGET_WORKSPACE" ]; then
    echo "ERROR: No workspace number provided (Waybar likely failed to pass {id})." >> $LOG_FILE
    exit 1
fi

echo "1. Switching to workspace: $TARGET_WORKSPACE" >> $LOG_FILE
# Execute Hyprland command (we don't check exit code here, Hyprland rarely fails)
hyprctl dispatch workspace "$TARGET_WORKSPACE"

# The sleep command is usually safe, but we log its presence
echo "2. Sleeping 0.1s..." >> $LOG_FILE
sleep 0.1 

# CRITICAL STEP: Execute the main theme change script and redirect all its errors (stderr) to the log
echo "3. Executing main theme script: ~/.config/hypr/change-wallpaper.sh" >> $LOG_FILE
"$HOME/.config/hypr/change-wallpaper.sh" 2>>$LOG_FILE

# Check the exit code of the last command (change-wallpaper.sh)
if [ $? -ne 0 ]; then
    echo "FATAL ERROR: change-wallpaper.sh returned an error code ($?)!" >> $LOG_FILE
fi

echo "Script finished successfully." >> $LOG_FILE
