#!/bin/bash

#  Name scipt 
#  Release date: 
#  Version: 
#  Copyright (C) Georgy Boganov | georg.b2014@outlook.com

cd rtl8812au-5.9.3.2
make clean
make
sudo make install
sudo modprobe 8812au
