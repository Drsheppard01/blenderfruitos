# Update full
sudo eopkg up -y
# Install developer packages
sudo eopkg it -c system.devel -y
git clone --single-branch -b driver-5.6.4 https://github.com/diederikdehaas/rtl8812AU.git
cd rtl8812au
echo -e "\e[40;38;5;82m Building driver \e[30;48;5;82m\e[0m"
make
echo -e "\e[40;38;5;82m Installing driver \e[30;48;5;82m\e[0m"
echo $PASSWORD | sudo -S "make install"
echo -e "\e[40;38;5;82m Done :) \e[30;48;5;82m You can now use your wifi adapter! \e[0m"
cd /home/$USER/Tomomi
rm -d -r rtl8812au-5.6.4.2
fi
# Delete pre-installed apps
sudo eopkg rmf gnome-photos gnome-terminal eog evince gnome-mpv rhythmbox hexchat thunderbird seahorse libreoffice-common yelp
# Install some apps
sudo eopkg it vlc steam telegram-desktop bookworm shotwell zsh make linux-current-headers cantarell-fonts kitty

#Raven
gsettings set com.solus-project.budgie-raven show-power-strip true
#Zsh
sudo eopkg it zsh powerlevel9k zsh-autosuggestions zsh-syntax-highlighting
sudo chsh -s /bin/zsh $(whoami)
