#!/bin/bash

_PARALLEL_THREADS="\$((\$(nproc)+1))"
INSTALL_NVIDIA_DRIVER=true
INSTALL_NVIDIA_OPEN_GPU_MODULES=true
USED_VIDEO_CARDS="nvidia"

MOUNT_LOCATION=/mnt/gentoo
TIMEZONE=Europe/Copenhagen

USE_FLAGS="-* nvidia persistenced driver X aac aalib acl acpi adns afs alsa ao apache2 asm atm appindicator audiofile audit avif bash-completion big-endian brotli bzip2 caps cddb cdinstall cgi cjk connman cracklib crypt cuda cups curl cvs cxx dbm dbus dedicated dga djvu dri dts egl elogind encode exif expat fam fastcgi fbcon ffmpeg flac fontconfig ftp gd gdbm ggi gif gimp git gmp gsm gstreamer gui gzip heif http2 iconv icu idn imagemagick imap imlib index64 inotify io-uring ipv6 jack java javascript jbig jemalloc jit jpeg jpeg2k jpegxl keyring lame lash libcaca libffi libnotify libsamplerate libwww lm-sensors lto lua lz4 lzip lzma lzo mad man memcached mhash mmap mng modules modules-compress motif mp3 mp4 mpeg mpi mplayer mtp multilib mysql mysqli native-extensions ncurses netcdf networkmanager nls nsplugin nvenc ocaml ocamlopt odbc offensive openal opencl opengl openmp opus oracle orc osc oss otf pam pcre pda pdf perl php png policykit portaudio posix postgres ppds profile pulseaudio python raw rdp readline recode ruby sasl scanner screencast sctp sdl session smp snappy sndfile snmp soap sockets socks5 sound spell sqlite ssl subversion suid svg svga symlink syslog szip taglib tcl tcmalloc tcpd theora threads tiff time64 truetype ttf udev udisks uefi unicode unwind upnp upnp-av upower usb v4l vaapi vdpau vhosts videos vim-syntax vnc vorbis vpx vulkan wavpack wayland webkit webp wmf x264 xattr xcb xcomposite xft xinerama xml xmpp xpm xv xvid zeroconf zip zlib zsh-completion zstd gnome-keyring kde qt6"
MAKE_OPTIONS="-j${_PARALLEL_THREADS}"

IS_SSD=true
IS_NVME=true

LATE_PACKAGES="app-shells/fish dev-util/rustup net-misc/croc app-misc/neofetch net-misc/axel dev-lang/mono virtual/dotnet-sdk games-util/lutris dev-vcs/git-lfs net-ftp/filezilla net-im/discord-bin media-gfx/blender media-video/obs-studio app-office/libreoffice games-fps/xonotic games-action/supertuxkart dev-util/shellcheck app-admin/hardinfo net-print/cups app-emulation/wine-vanilla app-emulation/wine-gecko app-emulation/wine-mono app-emulation/winetricks app-emulation/wine-desktop-common"
HOSTNAME="GENTOO"

PACKAGES="sys-apps/uutils sys-fs/btrfs-progs sys-fs/btrfsmaintenance sys-fs/e2fsprogs sys-fs/dosfstools sys-fs/ntfs3g net-wireless/iwd net-wireless/wireless-tools net-misc/dhcpcd app-text/tree sys-apps/pciutils sys-fs/genfstab x11-misc/xdg-user-dirs"
TOOLS="app-admin/sysklogd sys-process/cronie sys-apps/mlocate sys-apps/man-pages sys-apps/man-db app-editors/nano app-shells/bash"

INSTALL_STEAM="y"
INSTALL_GAME_EMULATORS="y"
MAKE_CLANG_DEFAULT_COMPILER=true

EMERGE="emerge"

ROOT_FS_TYPE=xfs

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


# Asks the user to select the partition they
IFS=$'\n' read -r -d '' -a arr2 < <(fdisk -l | grep -w '^Disk /dev' | cut -d ' ' -f 1 --complement | cut -d ',' -f 1; printf '\0')
PS3="Select the disk you want to partition: "
select i in "${arr2[@]}"
do
  DISK=$(printf "%s" "$i" | cut -d ':' -f 1)
	echo "$DISK Has been selected"
	break;
done

USE_KERNEL_CONFIG=$(read -n 1 -r -p "Use your own kernel .config file? - (y/n): ")
if [ "${USE_KERNEL_CONFIG}" != n ]; then
  USE_KERNEL_CONFIG=true
else
  USE_KERNEL_CONFIG=false
fi

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

mkfs.xfs -f "${DISK}"3
mkfs.vfat -F -I 32 "${DISK}"1
mkswap "${DISK}"2
swapon "${DISK}"2

# Mounts the newly created partitions to /mnt/gentoo
mkdir --parents /mnt/gentoo
mount "${DISK}"3 /mnt/gentoo
mkdir --parents /mnt/gentoo/efi
mount "${DISK}"1 /mnt/gentoo/efi

cd /mnt/gentoo || exit

# Downloads and extracts the stage3 file
command wget https://mirrors.dotsrc.org/gentoo/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20251026T170339Z.tar.xz
command tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# Sets some make.conf values
sed -i 's/^COMMON_FLAGS=.*/COMMON_FLAGS="-O2 -pipe -march=native"/' /mnt/gentoo/etc/portage/make.conf

echo "RUSTFLAGS=\"-C opt-level=3 -C target-cpu=native\"" >> /mnt/gentoo/etc/portage/make.conf

echo "MAKEOPTS=\"-j$(( $(nproc) + 1 ))\"" >> /mnt/gentoo/etc/portage/make.conf

echo "GENTOO_MIRRORS=\"https://mirrors.dotsrc.org/gentoo http://mirrors.dotsrc.org/gentoo\"" >> /mnt/gentoo/etc/portage/make.conf

echo "USE=\"-* X aac aalib acl acpi adns afs alsa ao apache2 asm atm appindicator audiofile audit avif bash-completion big-endian brotli bzip2 caps cddb cdinstall cgi cjk connman cracklib crypt cuda cups curl cvs cxx dbm dbus dedicated dga djvu dri dts egl elogind encode exif expat fam fastcgi fbcon ffmpeg flac fontconfig ftp gd gdbm ggi gif gimp git gmp gsm gstreamer gui gzip heif http2 iconv icu idn imagemagick imap imlib index64 inotify io-uring ipv6 jack java javascript jbig jemalloc jit jpeg jpeg2k jpegxl keyring lame lash libcaca libffi libnotify libsamplerate libwww lm-sensors lto lua lz4 lzip lzma lzo mad man memcached mhash mmap mng modules modules-compress motif mp3 mp4 mpeg mpi mplayer mtp multilib mysql mysqli native-extensions ncurses netcdf networkmanager nls nsplugin nvenc ocaml ocamlopt odbc offensive openal opencl opengl openmp opus oracle orc osc oss otf pam pcre pda pdf perl php png policykit portaudio posix postgres ppds profile pulseaudio python raw rdp readline recode ruby sasl scanner screencast sctp sdl session smp snappy sndfile snmp soap sockets socks5 sound spell sqlite ssl subversion suid svg svga symlink syslog szip taglib tcl tcmalloc tcpd theora threads tiff time64 truetype ttf udev udisks uefi unicode unwind upnp upnp-av upower usb v4l vaapi vdpau vhosts videos vim-syntax vnc vorbis vpx vulkan wavpack wayland webkit webp wmf x264 xattr xcb xcomposite xft xinerama xml xmpp xpm xv xvid zeroconf zip zlib zsh-completion zstd gnome-keyring kde qt6\"" >> /mnt/gentoo/etc/portage/make.conf

install_gentoo_prep()
{
  message "Running gentoo prep"
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

  command cp /root/gentoo-install/chroot.sh /mnt/gentoo/chroot.sh
  command chmod +x /mnt/gentoo/chroot.sh

  # Entering the new environment
  command chroot /mnt/gentoo /bin/env -i TERM="${TERM}" /bin/bash -c "./chroot.sh"
}

install_gentoo_prep