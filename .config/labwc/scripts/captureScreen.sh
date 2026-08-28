#! /usr/bin/env bash

location="$HOME"/Pictures/Screenshots/"$(date +'%s_grim.png')"

grim -g "$(slurp -d -o)" "$location"

wl-copy <"$location"

notify-send -t 1500 "Screenshot Taken"
