#!/bin/bash

#  Name scipt  Blenderfruit
#  Release date: 2021-30-06
#  Version: 2.0
#  Copyright (C) Georgy Boganov | georg.b2014@outlook.com

### Update full system ###

echo 'Выполняется обновление системы'

sudo eopkg up -y

### Install developer packages ###

echo 'Установка пакетов для разработчика'

sudo eopkg it -y -c system.devel

### Install wi-fi driver ###

echo 'Установка Wi-Fi драйвера'

git clone https://github.com/gordboy/rtl8812au-5.9.3.2.git
cd rtl8812au-5.9.3.2
echo "Драйвер собирается, пожалуйста подождите"
make 
echo "Драйвер собран. Сейчас будет произведена установка"
sudo make install
echo "Драйвер установлен. Сейчас пытаюсь его загрузить из системы"
sudo modprobe 8812au

### Delete pre-installed apps ###

echo 'Удаление предустановленных приложений'

sudo eopkg rmf gnome-photos gnome-terminal eog evince gnome-mpv rhythmbox hexchat thunderbird seahorse firefox

### Install some apps ###

echo 'Установка необходимых приложений'

sudo eopkg it vlc telegram shotwell kitty opera-stable lsd neofetch micro

### Install VMWare Horizon Client ###

echo 'Установка VMWare для работы'

sh -c "$(wget https://download3.vmware.com/software/view/viewclients/CART22FQ1/VMware-Horizon-Client-2103-8.2.0-17742757.x64.bundle)"

### Install Zoom from Flatpak

echo 'Install Zoom'

sudo eopkg it xdg-desktop-portal-gtk
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub us.zoom.Zoom

### Install cursor ###

echo 'Установка курсора'

wget https://github.com/ful1e5/Bibata_Cursor/releases/download/v1.1.0/Bibata-Modern-Classic.tar.gz
tar xvzf Bibata-Modern-Classic.tar.gz && sudo cp -r ~/Bibata-Modern-Classic /usr/share/icons/

### Install themes ###

echo 'Установка темы'

wget https://github.com/vinceliuice/Orchis-theme/archive/2021-06-25.tar.gz
tar xvzf 2021-06-25.tar.gz && cd 2021-06-25/Orchis-theme-2021-06-25 && sudo sh install.sh
gsettings set org.gnome.desktop.wm.preferences theme 'Orchis-compact'
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-compact'

### Install icons ###

echo 'Установка иконок'

wget https://github.com/vinceliuice/Tela-circle-icon-theme/archive/2020-11-29.tar.gz
tar xvzf 2020-11-29.tar.gz && cd /2020-11-29/Tela-circle-icon-theme-2020-11-29 && sudo sh install.sh -c blue
gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-blue'

### Raven ###

echo 'Отображать панель управления питанием в Raven'

gsettings set com.solus-project.budgie-raven show-power-strip true

### Zsh ###

echo 'Установка ZSH'

sudo eopkg it zsh zsh-autosuggestions zsh-syntax-highlighting
sudo chsh -s /bin/zsh $(whoami)
