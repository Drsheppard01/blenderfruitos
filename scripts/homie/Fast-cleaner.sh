#!/bin/bash

#  Name scipt: FastCleaner 
#  Release date: 2021-07-12 
#  Version: 1.0
#  Copyright (C) Georgii Bogdanov | GBOG@protonmail.com

set -eu

LANG=C snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        snap remove "$snapname" --revision="$revision"
    done
sudo flatpak remove --unused
sudo rm /var/lib/snapd/cache/*
sudo eopkg dc
sudo eopkg rmo
rm -f ~/.cache/thumbnails/*
sudo journalctl --vacuum-time=2day