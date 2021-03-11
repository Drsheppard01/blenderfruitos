#!/bin/bash

# Update full
sudo eopkg up -y

# Install developer packages
sudo eopkg it -y make gcc binutils git linux-current-headers eopkg-deps

# Install wi-fi driver
git clone https://github.com/gordboy/rtl8812au-5.9.3.2.git
cd rtl8812au
make
sudo make install
modprobe 8812au


# Delete pre-installed apps
sudo eopkg rmf gnome-photos gnome-terminal eog evince gnome-mpv rhythmbox hexchat thunderbird seahorse libreoffice-common yelp
# Install some apps
sudo eopkg it vlc steam telegram-desktop bookworm shotwell cantarell-fonts kitty

#Raven
gsettings set com.solus-project.budgie-raven show-power-strip true
#Zsh
sudo eopkg it zsh powerlevel9k zsh-autosuggestions zsh-syntax-highlighting
sudo chsh -s /bin/zsh $(whoami)
