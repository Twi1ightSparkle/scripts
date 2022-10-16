#!/bin/bash

# Create three keyboard shortcuts in Gnome settings
# Screen shot area - /home/twilight/Documents/git/scripts/screen_shot.sh area - Shift+Ctrl+1
# Screen shot full screen - /home/twilight/Documents/git/scripts/screen_shot.sh full - Shift+Ctrl+2
# Screen shot window - /home/twilight/Documents/git/scripts/screen_shot.sh window - Shift+Ctrl+3

file_name=$(/usr/bin/date +"Screen Shot %Y-%m-%d at %I.%M.%S %p.png") # Screen Shot 2020-06-21 11.22.33 PM.png
out_directory="/home/twilight/Nextcloud/Photos/Screenshots"
log_file="/home/twilight/Nextcloud/Photos/Screenshots/log.log"

# Returns the current time stamp in format 2022-07-23T14-56-03Z
zulu_time(){
    /bin/echo "$(/bin/date -u "+%Y-%m-%dT%H-%M-%SZ")"
}

# Log some text to the log file. Params:
# 1. The text to log
log() {
    /bin/echo "$(zulu_time) $1" >> "$log_file"
}

if [ "$1" == "area" ]; then
    log "Taking area screenshot"
    /usr/bin/gnome-screenshot --clipboard --area --include-pointer --delay=0 --file="$out_directory/$file_name"
    log "Area screenshot saved to \"$out_directory/$file_name\""
elif [ "$1" == "window" ]; then
    log "Taking window screenshot"
    /usr/bin/gnome-screenshot --clipboard --window --delay=0 --file="$out_directory/$file_name"
    log "Window screenshot saved to \"$out_directory/$file_name\""
elif [ "$1" == "full" ]; then
    log "Taking full screen screenshot"
    /usr/bin/gnome-screenshot --clipboard --include-pointer --delay=0 --file="$out_directory/$file_name"
    log "Full screen screenshot saved to \"$out_directory/$file_name\""
else
    echo "Supported options: area, window, and full."
    echo "Example: ./screen_shot.sh area"
fi
