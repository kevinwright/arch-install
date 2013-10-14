#!/bin/bash

function ask {
    while true; do
 
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi
 
        # Ask the question
        read -p "$1 [$prompt] " REPLY
 
        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi
 
        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
 
    done
}

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

#load the raw installation onto the filesystem, and chroot
#The mirrormist is first updated to a uk-optimised version
wget "https://www.archlinux.org/mirrorlist/?country=GB&protocol=http&ip_version=4&use_mirror_status=on" -O /etc/pacman.d/mirrorlist
pacstrap /mnt base
genfstab -U -p /mnt >> /mnt/etc/fstab


arch-chroot /mnt simple-no-swap-postchroot.sh

#unmount and reboot
umount /mnt/{boot,home,}
reboot