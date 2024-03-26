#!/bin/bash

# Create three keyboard shortcuts in Gnome settings
# Screen shot area - /home/twilight/Documents/git/scripts/screen_shot.sh area "/optional/alternate/path/to/save/screenshots" - Shift+Ctrl+1
# Screen shot full screen - /home/twilight/Documents/git/scripts/screen_shot.sh full "/optional/alternate/path/to/save/screenshots" - Shift+Ctrl+2
# Screen shot window - /home/twilight/Documents/git/scripts/screen_shot.sh window "/optional/alternate/path/to/save/screenshots" - Shift+Ctrl+3

# Returns the current time stamp in format 2022-07-23T14-56-03Z
zulu_time(){
    /bin/echo "$(/bin/date -u "+%Y-%m-%dT%H-%M-%SZ")"
}

if [[ -n "$2" ]]; then
    SCREENSHOT_PATH="$2"
else
    SCREENSHOT_PATH="$HOME/Pictures"
fi

file_name="screenshot_$(zulu_time).png"
out_directory="$SCREENSHOT_PATH"
log_file="$SCREENSHOT_PATH/screenshots.log"

# Log some text to the log file. Params:
# 1. The text to log
log() {
    /bin/echo "$(zulu_time) $1" >> "$log_file"
    echo "$1"
}

GNOME_CMD=(
    "/usr/bin/gnome-screenshot"
    "--clipboard"
    "--include-pointer"
    "--delay" "0"
    "--file" "$out_directory/$file_name"
)

KDE_CMD=(
    "/usr/bin/spectacle"
    "--background"
    "--copy-image"
    "--delay" "0"
    "--nonotify"
    "--output" "$out_directory/$file_name"
)

case "$1" in
    area)
        LOG_STRING=area
        GNOME_CMD+=("--area")
        KDE_CMD+=("--region");;
    window)
        LOG_STRING=window
        GNOME_CMD+=("--window")
        KDE_CMD+=("--activewindow");;
    full)
        LOG_STRING="full screen"
        KDE_CMD+=("--fullscreen");;
    *)
        log "Supported options: area, window, and full."
        exit 1;;
esac


log "Taking $LOG_STRING screenshot"

if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    "${GNOME_CMD[@]}"
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    "${KDE_CMD[@]}"
else
    log "Unsupported desktop environment: $XDG_CURRENT_DESKTOP"
    exit 1
fi

log "Screenshot $LOG_STRING saved to \"$out_directory/$file_name\""
