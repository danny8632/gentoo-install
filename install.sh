#!/bin/bash

i=0; arr1=()
while IFS='' read -r value; do
    arr1+=("$value")
done <<-EOT
$(printf '%s\n' fdisk -l | grep -w '^Disk /dev' | cut -d ' ' -f 1 --complement | cut -d ',' -f 1)
EOT

printf '%s\n' "${arr1[@]}"

DISK_OPTIONS=$(fdisk -l | grep -w '^Disk /dev' | cut -d ' ' -f 1 --complement | cut -d ',' -f 1)

printf '%s\n' "${DISK_OPTIONS}"


DISK=$(read -r -p "What disk do you want to use? - (/dev/sda): ")

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
) | fdisk ${DISK}

mkfs.xfs /dev/sda3
mkfs.vfat -F 32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2

mkdir --parents /mnt/gentoo
mount /dev/sda3 /mnt/gentoo
mkdir --parents /mnt/gentoo/efi
mount /dev/sda1 /mnt/gentoo/efi

cd /mnt/gentoo

wget https://mirrors.dotsrc.org/gentoo/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20251026T170339Z.tar.xz

tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo


GET_ARCH="$(lscpu | grep -w '^Architecture' | sed 's/\s\s*/ /g' | cut -d ' ' -f 1 --complement | cut -d ' ' -f 1 -z)"

_PARALLEL_THREADS="\$((\$(nproc)+1))"

LRED='\033[01;31m'
GREEN='\033[0;32m'
LCYAN='\033[1;36m'
LBLUE='\033[1;34m'
LPURPLE='\033[0;35m'
DGRAY='\033[1;30m'
NC='\033[0m' # No Color

MOUNT_LOCATION=/mnt/gentoo
TIMEZONE=Europe/Copenhagen # Change this to your relevant timezone located in "/usr/share/zoneinfo"

CPU_ARCH="$(gcc -march=native -Q --help=target | grep -- '-march=' | cut -f3 | cut -d ' ' -f 1 -z)"

CFLAGS="-march=${CPU_ARCH} -mtune-${CPU_ARCH} -O3 -pipe -fno-plt -pthread -fsanitize=bounds,alignment,object-size -fsanitize-undefined-trap-on-error \
        -fvisibility=hidden -fexceptions -Wformat -Werror=format-security \
        -Wvla -Wimplicit-fallthrough -Wno-unused-result -Wno-unneeded-internal-declaration -Warray-bounds"

emerge --oneshot --noreplace cpuid2cpuflags

CPU_FLAGS=$(cpuid2cpuflags | cut -c 1-15 --complement)

USE_FLAGS="a52 aac acpi branding cairo cdr dbus dri dts dvd dvdr encode exif flac gif gpm gui icu jpeg lcms libnotify mad mng mp3 mp4 mpeg ogg pdf png ppds spell startup-notification svg tiff truetype vorbis udev udisks unicode upower usb wxwidgets x264 xml xv xvid X xcb wayland acl bindist mmx sse sse2 initramfs redistributable elogind -suid -selinux xattr clang desktop-portal accessibility crypt bluetooth browser-integration sna pulseaudio pipewire pipewire-alsa policykit sysv-utils netifrc ncurses audit pam -systemd -test -examples layers vulkan opencl discord-presence mgba autotype browser keeshare network introspection zip steamruntime en-US d3d9 gles1 gles2 llvm lm-sensors opencl osmesa valgrind xa xvmc zink 64 32 x32 unwind vaapi zstd dist-kernel symlink fonts seccomp"
MAKE_OPTIONS="-j${_PARALLEL_THREADS}"

echo "${MAKE_OPTIONS}"
echo "${CPU_FLAGS}"
echo "${CPU_ARCH}"
echo "${CFLAGS}"
