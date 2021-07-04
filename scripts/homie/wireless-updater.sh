#!/bin/bash

#  Name scipt  Wireless-updater
#  Release date: 2021-03-15
#  Version: 1.0
#  Copyright (C) Georgii Bogdanov | GBOG@protonmail.com

git clone https://github.com/gordboy/rtl8812au-5.9.3.2.git
cd rtl8812au-5.9.3.2
echo "Драйвер собирается, пожалуйста подождите"
make 
echo "Драйвер собран. Сейчас будет произведена установка"
sudo make install
echo "Драйвер установлен. Сейчас пытаюсь его загрузить из системы"
sudo modprobe 8812au
