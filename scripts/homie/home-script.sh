#!/bin/bash

#  Name scipt  Blenderfruit
#  Release date: 2024-27-06
#  Version: 5.0
#  Copyright (C) DrSheppard01 | GBOG@protonmail.com



wget https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz
tar xvzf Bibata-Modern-Classic.tar.xz && sudo cp -r ~/Bibata-Modern-Classic /usr/share/icons/


### Install themes ###

git clone https://github.com/vinceliuice/Colloid-gtk-theme.git
cd Colloid-gtk-theme
sudo bash install.sh -c light -s standard -l system --tweaks rimless normal
gsettings set org.gnome.desktop.wm.preferences theme 'Colloid-Light'
gsettings set org.gnome.desktop.interface gtk-theme 'Colloid-Light'

### Install icons ###

git clone https://github.com/darkomarko42/Marwaita-Icons.git
cd Marwaita-Icons
cp ~/Marwaita-Light/* ~/Marwaita
mkdir ~/.icons && cp ~/Marwaita ~/.icons
gsettings set org.gnome.desktop.interface icon-theme 'Marwaita'

### Install font

curl -fsSL https://www.gent.media/assets/manrope/manrope.zip | unzip
cd manrope
mkdir ~/.fonts && cp ~/manrope ~/.fonts
gsettings set org.gnome.desktop.interface "Manrope 10"

### Zsh ###

doas apk add zsh
sudo chsh -s /bin/zsh $(whoami)
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
