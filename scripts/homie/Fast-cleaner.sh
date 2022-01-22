#!/bin/bash

#  Name scipt: Snap-Cleaner 
#  Release date: 2021-10-20 
#  Version: 2.0
#  Copyright (C) Georgii Bogdanov | GBOG@protonmail.com

set -eu

snap refresh

LANG=C snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done
