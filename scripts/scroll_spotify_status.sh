#!/bin/bash

# see man zscroll for documentation of the following parameters
zscroll -l 20 \
        --delay 0.1 \
        --scroll-padding "  /  " \
        --match-command "$HOME/.config/scripts/get_spotify_status.sh --status" \
        --match-text "Playing" "--scroll 1" \
        --match-text "Paused" "--scroll 0" \
        --update-check true "$HOME/.config/scripts/get_spotify_status.sh" &

wait
