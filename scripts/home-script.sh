#!/bin/bash

### Update full system ###

sudo eopkg up -y

### Install developer packages ###

sudo eopkg it -y make gcc binutils git linux-current-headers eopkg-deps

### Install wi-fi driver ###

git clone https://github.com/gordboy/rtl8812au-5.9.3.2.git
cd rtl8812au-5.9.3.2
make
sudo make install
sudo modprobe 8812au


### Delete pre-installed apps ###

sudo eopkg rmf gnome-photos gnome-terminal eog evince gnome-mpv rhythmbox hexchat thunderbird seahorse

### Install some apps ###

sudo eopkg it vlc telegram shotwell cantarell-fonts kitty

### Install cursor ###

wget https://github.com/ful1e5/Bibata_Cursor/releases/download/v1.1.0/Bibata-Modern-Classic.tar.gz
tar xvzf Bibata-Modern-Classic.tar.gz && sudo cp -r ~/Bibata-Modern-Classic /usr/share/icons/

### Install themes ###

wget https://github.com/vinceliuice/Orchis-theme/archive/2021-02-28.tar.gz
tar xvzf 2021-02-28.tar.gz && cd Orchis-theme-2021-02-28 && sudo sh install.sh
gsettings set org.gnome.desktop.wm.preferences theme 'Orchis-compact'
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-compact'

### Install icons ###

wget https://github.com/vinceliuice/Tela-circle-icon-theme/archive/2020-11-29.tar.gz
tar xvzf 2020-11-29.tar.gz && cd Tela-circle-icon-theme-2020-11-29 && sudo sh install.sh
gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle'

### Raven ###

gsettings set com.solus-project.budgie-raven show-power-strip true

### Zsh ###

sudo eopkg it zsh powerlevel9k zsh-autosuggestions zsh-syntax-highlighting
sudo chsh -s /bin/zsh $(whoami)
