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

mkfs.xfs -f /dev/sda3
mkfs.vfat -F -I 32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2

# Mounts the newly created partitions to /mnt/gentoo
mkdir --parents /mnt/gentoo
mount /dev/sda3 /mnt/gentoo
mkdir --parents /mnt/gentoo/efi
mount /dev/sda1 /mnt/gentoo/efi

cd /mnt/gentoo || exit

# Downloads and extracts the stage3 file
wget https://mirrors.dotsrc.org/gentoo/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20251026T170339Z.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# Sets some make.conf values
sed -i 's/^COMMON_FLAGS=.*/COMMON_FLAGS="-O2 -pipe -march=native"/' /mnt/gentoo/etc/portage/make.conf

echo "RUSTFLAGS=\"\${RUSTFLAGS} -C target-cpu=native\"" >> /mnt/gentoo/etc/portage/make.conf

echo "MAKEOPTS=\"-j$(( $(nproc) + 1 ))\"" >> /mnt/gentoo/etc/portage/make.conf

echo "GENTOO_MIRRORS=\"https://mirrors.dotsrc.org/gentoo http://mirrors.dotsrc.org/gentoo\"" >> /mnt/gentoo/etc/portage/make.conf


# TODO: ADD useflags here once I know the onces to use

LRED='\033[01;31m'
GREEN='\033[0;32m'
LCYAN='\033[1;36m'
LBLUE='\033[1;34m'
LPURPLE='\033[0;35m'
DGRAY='\033[1;30m'
NC='\033[0m' # No Color



message ()
{
  echo
  echo -e " $LBLUE>>> $LRED $* $NC"
}

command ()
{
  echo -e "$LCYAN$*$NC"
  "$@"
  if [ $? -ne 0 ]; then
    echo -e "$LREDFailed$NC"
    return 1
  fi
}


# Copy DNS info
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

# Mounting the necessary filesystems
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

# Entering the new environment
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"


message "Installing portage snapshot"
command emerge-webrsync
message "Updating portage tree"
command emerge --sync

message "Installing cpuid2cpuflags"
command emerge --q --oneshot app-portage/cpuid2cpuflags

message "installing gcc!"
command emerge --q --oneshot sys-devel/gcc
echo "install is done!"

CPU_ARCH="$(gcc -march=native -Q --help=target | grep -- '-march=' | cut -f3 | cut -d ' ' -f 1 -z)"
CFLAGS="-march=${CPU_ARCH} -mtune-${CPU_ARCH} -O3 -pipe -fno-plt -pthread -fsanitize=bounds,alignment,object-size -fsanitize-undefined-trap-on-error \
        -fvisibility=hidden -fexceptions -Wformat -Werror=format-security \
        -Wvla -Wimplicit-fallthrough -Wno-unused-result -Wno-unneeded-internal-declaration -Warray-bounds"
CPU_FLAGS=$(cpuid2cpuflags | cut -c 1-15 --complement)

