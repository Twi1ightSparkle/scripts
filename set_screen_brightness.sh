#!/bin/bash

error_string="An integer in the range 10-100 must be specified. For example \"./set_screen_brightness.sh 75\""

# Validate option is an integer
re='^[0-9]+$'
if ! [[ "$1" =~ $re ]]
then
   echo "$error_string"
   exit 1
fi

# Validate option is in valid range
if [ "$1" -gt 100 ] || [ "$1" -lt 10 ]
then
   echo "$error_string"
   exit 1
fi

# Set brightness for all monitors
while read -r monitor
do
    if [ "$1" == 100 ]
    then
        xrandr --output "$monitor" --brightness 1
    else
        xrandr --output "$monitor" --brightness "0.$1"
    fi
done < <(xrandr --query | grep " connected" | cut --delimiter " " --fields 1)
