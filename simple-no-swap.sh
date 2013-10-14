#!/bin/bash



#Set installation locale for UK/GB
loadkeys uk
setfont Lat2-Terminus16
sed -i 's/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/en_US.UTF-8 UTF-8/#en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
export LANG=en_GB.UTF-8

#512MB FAT32 partition for boot, the rest of the drive as btrfs for root
sgdisk -Z /dev/sda
sgdisk -o -n 1:0:+512M -n 2:0:0 -c 1:Boot -c 2:Root -p /dev/sda
mkfs.vfat -F32 /dev/sda1
mkfs.btrfs /dev/sda2
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

#Fetch a list of all known UK mirrors
wget "https://www.archlinux.org/mirrorlist/?country=GB&protocol=http&ip_version=4" -O /etc/pacman.d/mirrorlist.uk
#uncomment them all
sed '/^#\S/ s|#||' -i /etc/pacman.d/mirrorlist.uk
#order according to speed
rankmirrors -n 6 /etc/pacman.d/mirrorlist.uk > /etc/pacman.d/mirrorlist

#load the raw installation onto the filesystem, and chroot
pacstrap /mnt base
genfstab -U -p /mnt >> /mnt/etc/fstab

wget "https://raw.github.com/kevinwright/arch-install/master/simple-no-swap-postchroot.sh" -O /mnt/root/simple-no-swap-postchroot.sh
chmod +x /mnt/root/simple-no-swap-postchroot.sh
arch-chroot /mnt /root/simple-no-swap-postchroot.sh
rm /mnt/root/simple-no-swap-postchroot.sh

#unmount and reboot
umount /mnt/{boot,home,}
reboot