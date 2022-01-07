#!/bin/bash

#  Name scipt  Blenderfruit
#  Release date: 2021-30-06
#  Version: 2.0
#  Copyright (C) Georgii Bogdanov | GBOG@protonmail.com

### Update full system ###

echo 'Обновляю систему'

sudo eopkg up -y

### Install developer packages ###

echo 'Устанавливаю пакетов для разработчика'

sudo eopkg it -y -c system.devel git

### Install wi-fi driver ###

echo 'Устанавливаю Wi-Fi драйвер'

git clone https://github.com/gordboy/rtl8812au-5.9.3.2.git
cd rtl8812au-5.9.3.2
echo 'Драйвер собирается, пожалуйста подождите'
make 
echo 'Драйвер собран. Устанавливаю'
sudo make install
echo 'Драйвер установлен. Загружаю драйвер системы'
sudo modprobe 8812au

### Delete pre-installed apps ###

echo 'Удаляю предустановленные приложения'

sudo eopkg rmf gnome-photos gnome-terminal eog evince gnome-mpv rhythmbox hexchat thunderbird seahorse firefox gnome-system-monitor

### Install some apps ###

echo 'Устанавливаю необходимые приложения'

sudo eopkg it vlc telegram shotwell kitty opera-stable lsd neofetch micro bottom

### Install Zoom from Flatpak

echo 'Устанавливаю Zoom'

sudo eopkg it xdg-desktop-portal-gtk
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub us.zoom.Zoom

### Install cursor ###

echo 'Устанавливаю курсор'

wget https://github.com/ful1e5/Bibata_Cursor/releases/download/v1.1.0/Bibata-Modern-Classic.tar.gz
tar xvzf Bibata-Modern-Classic.tar.gz && sudo cp -r ~/Bibata-Modern-Classic /usr/share/icons/

### Install themes ###

echo 'Устанавливаю тему'

wget https://github.com/vinceliuice/Orchis-theme/archive/2021-06-25.tar.gz
tar xvzf 2021-06-25.tar.gz && cd 2021-06-25/Orchis-theme-2021-06-25 && sudo sh install.sh -c standard
gsettings set org.gnome.desktop.wm.preferences theme 'Orchis-compact'
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-compact'

### Install icons ###

echo 'Устанавливаю иконки'

wget https://github.com/vinceliuice/Tela-circle-icon-theme/archive/2020-11-29.tar.gz
tar xvzf 2020-11-29.tar.gz && cd /2020-11-29/Tela-circle-icon-theme-2020-11-29 && sudo sh install.sh -c blue
gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-blue'

### Raven ###

echo 'Включил отображение панели управления питанием в Raven'

gsettings set com.solus-project.budgie-raven show-power-strip true

### Zsh ###

echo 'Меняю Bash на zsh'

sudo eopkg it zsh
sudo chsh -s /bin/zsh $(whoami)
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
