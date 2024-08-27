#!/bin/bash

# Script for installing the most complete software package that covers all your needs

sudo dnf install gnome-console \
clapper \
loupe \
foliate \
gnome-text-editor \
micro
sudo dnf remove gedit \
gnome-terminal \
totem \
snapshot \
rhythmbox
