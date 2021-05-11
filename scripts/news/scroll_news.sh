#!/bin/bash

# see man zscroll for documentation of the following parameters
zscroll -l 40 \
        --delay 0.3 \
        --match-command "$HOME/.config/scripts/news/news.sh --status" \
        --match-text "Playing" "--scroll 1" \
        --match-text "Paused" "--scroll 0" \
        --update-check true "$HOME/.config/scripts/news/news.sh" &

wait
