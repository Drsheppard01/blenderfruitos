#!/bin/bash

#  Name scipt: FastCleaner 
#  Release date: 2021-10-20 
#  Version: 1.6
#  Copyright (C) Georgii Bogdanov | GBOG@protonmail.com

set -eu

snap refresh

LANG=C snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done
sudo flatpak update
sudo flatpak remove --unused
sudo rm /var/lib/snapd/cache/*
sudo eopkg dc
sudo eopkg rmo
sudo journalctl --vacuum-size=64M
sudo journalctl --vacuum-time=1days
sudo rm -r ~/.cache/thumbnails/*
sudo usysconf run -f
