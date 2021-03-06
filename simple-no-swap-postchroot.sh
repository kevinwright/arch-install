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

echo Now Chrooted

#Locale again, and timezone, on the target system this time
sed -i 's/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/en_US.UTF-8 UTF-8/#en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
export LANG=en_GB.UTF-8
loadkeys uk
setfont Lat2-Terminus16
echo -e "KEYMAP=uk\nFONT=Lat2-Terminus16\n" > /etc/vconsole.conf
ln -s /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc --utc

#host name
read -e -p "Enter the Host name: " TGT_HOSTNAME
echo $TGT_HOSTNAME > /etc/hostname

#Network setup. Multiple choice here to select static or DHCP
if ask "Use DHCP for network config?"; then
	cat > /etc/netctl/local-net <<- EOF
		Description='Local Network'
		Interface=ens32
		Connection=ethernet
		IP=dhcp
		IP6=stateless
		EOF
else
	read -e -p "Address: " -i "1.2.3.4/24" TGT_IP_ADDR
	read -e -p "Gateway: " -i "1.2.3.4" TGT_GW_ADDR
	read -e -p "DNS: " -i "1.2.3.4" TGT_DNS_ADDR
	read -e -p "DNS Domain: " -i "my.lan" TGT_DNS_DOM
	cat > /etc/netctl/local-net <<- EOF
		Description='Local Network'
		Interface=ens32
		Connection=ethernet
		IP=static
		IP6=stateless
		Address=('$TGT_IP_ADDR')
		Gateway='$TGT_GW_ADDR'
		DNS=('$TGT_DNS_ADDR')
		DNSDomain='$TGT_DNS_DOM'
		EOF
fi
netctl enable local-net

#init boot ramdrive
mkinitcpio -p linux

#set root password
passwd

#install bootloader
pacman -S --noconfirm syslinux
pacman -S --noconfirm gptfdisk
syslinux-install_update -i -a -m
sed -i 's:/dev/sda3:/dev/sda2:g' /boot/syslinux/syslinux.cfg

exit