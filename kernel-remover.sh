#!/usr/bin/bash

old_kernels=($(dnf5 repoquery --installonly --latest-limit=-1 -q))
if [ "${#old_kernels[@]}" -eq 0 ]; then
    notify-send "No old kernels found"
    exit 0
fi

if ! dnf5 remove "${old_kernels[@]}"; then
    notify-send "Failed to remove old kernels"
    exit 1
fi

echo "Removed old kernels"
exit 0
