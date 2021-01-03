#!/bin/bash

# Create three shortcuts in Gnome settings
# Screen shot area - /home/twilight/Documents/git/scripts/screen_shot.sh area - Shift+Super+4
# Screen shot full screen - /home/twilight/Documents/git/scripts/screen_shot.sh full - Shift+Super+3
# Screen shot window - /home/twilight/Documents/git/scripts/screen_shot.sh window - Shift+Super+5

file_name=$(/usr/bin/date +"Screen Shot %Y-%m-%d at %I.%M.%S %p.png") # Screen Shot 2020-06-21 11.22.33 PM.png
out_directory="/home/twilight/Nextcloud/Photos/Screenshots"

if [ "$1" == "area" ]; then
    /usr/bin/gnome-screenshot --clipboard --area --include-pointer --delay=0 --file="$out_directory/$file_name"
elif [ "$1" == "window" ]; then
    /usr/bin/gnome-screenshot --clipboard --window --delay=0 --file="$out_directory/$file_name"
elif [ "$1" == "full" ]; then
    /usr/bin/gnome-screenshot --clipboard --include-pointer --delay=0 --file="$out_directory/$file_name"
else
    echo "Supported options: area, window and full."
    echo "Example: ./screen_shot.sh area"
fi
