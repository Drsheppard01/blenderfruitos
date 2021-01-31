#!/bin/bash

# Update full
sudo eopkg up -y
# Install developer packages
sudo eopkg it -c system.devel -y
# Delete pre-installed apps
sudo eopkg rmf gnome-photos gnome-terminal eog evince gnome-mpv rhythmbox hexchat thunderbird seahorse libreoffice-common yelp
# Install some apps
sudo eopkg it vlc steam telegram-desktop bookworm shotwell zsh make linux-current-headers cantarell-fonts kitty

#Raven
gsettings set com.solus-project.budgie-raven show-power-strip true
#Zsh
sudo eopkg it zsh powerlevel9k zsh-autosuggestions zsh-syntax-highlighting
sudo chsh -s /bin/zsh $(whoami)
