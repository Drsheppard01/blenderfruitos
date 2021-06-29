#!/bin/bash

#  Name scipt: wireless-updater-offline 
#  Release date: 2021-06-24
#  Version: 1.0
#  Copyright (C) Georgy Boganov | georg.b2014@outlook.com

cd rtl8812au-5.9.3.2
make clean
make
sudo make install
sudo modprobe 8812au
