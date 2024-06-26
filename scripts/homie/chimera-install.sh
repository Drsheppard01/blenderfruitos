#!/bin/sh

doas wipefs -a /dev/nvme0n1
doas sfdisk /dev/nvme0n1 <<EOF
label: gpt
name=esp, size=100M, type="EFI System"
name=root
EOF
doas mkfs.vfat /dev/nvme0n1p1
doas mkfs.xfs /dev/nvme0n1p2
doas mkdir /media/root
doas mount /dev/nvme0n1p2 /media/root
doas mkdir -p /media/root/boot/efi
doas mount /dev/nvme0n1p1 /media/root/boot/efi
doas chmod 755 /media/root
doas chimera-bootstrap -l /media/root
doas chimera-chroot /media/root
apk update
apk upgrade --available
apk fix
apk add linux-stable systemd-boot
genfstab -t PARTLABEL / > /etc/fstab
passwd root
useradd myuser
passwd myuser
usermod -a -G wheel myuser
echo mycomputer > /etc/hostname
ln -sf ../usr/share/zoneinfo/Europe/P /etc/localtime
dinitctl -o enable gdm
dinitctl -o enable chrony
dinitctl -o enable networkmanager
update-initramfs -c -k all
exit
reboot
