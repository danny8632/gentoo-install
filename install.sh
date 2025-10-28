#!/bin/bash


# Asks the user to select the partition they
IFS=$'\n' read -r -d '' -a arr2 < <(fdisk -l | grep -w '^Disk /dev' | cut -d ' ' -f 1 --complement | cut -d ',' -f 1; printf '\0')
PS3="Select the disk you want to partition: "
select i in "${arr2[@]}"
do
    DISK=$($i | cut -d ',' -f 1)
	echo "$DISK Has been selected"
	break;
done


# Partition the disks
(
    echo g;
    echo n;
    echo ;
    echo ;
    echo +1G;
    echo t;
    echo 1;
    echo n;
    echo ;
    echo ;
    echo +16G;
    echo t;
    echo 2;
    echo 19;
    echo n
    echo ;
    echo ;
    echo ;
    echo t;
    echo 3;
    echo 23;
    echo w;
) | fdisk "${DISK}"

mkfs.xfs /dev/sda3
mkfs.vfat -F 32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2

mkdir --parents /mnt/gentoo
mount /dev/sda3 /mnt/gentoo
mkdir --parents /mnt/gentoo/efi
mount /dev/sda1 /mnt/gentoo/efi

cd /mnt/gentoo || exit

wget https://mirrors.dotsrc.org/gentoo/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20251026T170339Z.tar.xz

tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
