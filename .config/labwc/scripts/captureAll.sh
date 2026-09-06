#! /usr/bin/env bash

location="$HOME"/Изображения/'Снимки экрана'/"$(date +'%s_grim.png')"

grim "$location"

wl-copy <"$location"

notify-send -t 1500 -e "Screenshot Taken"
