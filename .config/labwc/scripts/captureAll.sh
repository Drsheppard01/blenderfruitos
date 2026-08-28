#! /usr/bin/env bash

location="$HOME"/Pictures/Screenshots/"$(date +'%s_grim.png')"

grim "$location"

wl-copy <"$location"

notify-send -t 1500 -e "Screenshot Taken"
