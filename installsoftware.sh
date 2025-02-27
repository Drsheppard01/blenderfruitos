#!/bin/bash

# Script for installing the most complete software package that covers all your needs

sudo dnf install foot \
clapper \
loupe \
foliate \
gnome-text-editor \
micro
sudo dnf remove gnome-software flatpak \
ptyxis \
totem \
snapshot \
rhythmbox &&
sudo dnf autoremove
