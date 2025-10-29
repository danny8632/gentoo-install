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

sleep 30s

mkfs.xfs -f "${DISK}"3
mkfs.vfat -F -I 32 "${DISK}"1
mkswap "${DISK}"2
swapon "${DISK}"2

sleep 30s

# Mounts the newly created partitions to /mnt/gentoo
mkdir --parents /mnt/gentoo
mount "${DISK}"3 /mnt/gentoo
mkdir --parents /mnt/gentoo/efi
mount "${DISK}"1 /mnt/gentoo/efi

sleep 30s

cd /mnt/gentoo || exit

# Downloads and extracts the stage3 file
wget https://mirrors.dotsrc.org/gentoo/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20251026T170339Z.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# Sets some make.conf values
sed -i 's/^COMMON_FLAGS=.*/COMMON_FLAGS="-O2 -pipe -march=native"/' /mnt/gentoo/etc/portage/make.conf

echo "RUSTFLAGS=\"-C opt-level=3 -C target-cpu=native\"" >> /mnt/gentoo/etc/portage/make.conf

echo "MAKEOPTS=\"-j$(( $(nproc) + 1 ))\"" >> /mnt/gentoo/etc/portage/make.conf

echo "GENTOO_MIRRORS=\"https://mirrors.dotsrc.org/gentoo http://mirrors.dotsrc.org/gentoo\"" >> /mnt/gentoo/etc/portage/make.conf

echo "USE=\"-* X aac aalib acl acpi adns afs alsa ao apache2 asm atm appindicator audiofile audit avif bash-completion big-endian brotli bzip2 caps cddb cdinstall cgi cjk connman cracklib crypt cuda cups curl cvs cxx dbm dbus dedicated dga djvu dri dts egl elogind encode exif expat fam fastcgi fbcon ffmpeg flac fontconfig ftp gd gdbm ggi gif gimp git gmp gsm gstreamer gui gzip heif http2 iconv icu idn imagemagick imap imlib index64 inotify io-uring ipv6 jack java javascript jbig jemalloc jit jpeg jpeg2k jpegxl keyring lame lash libcaca libffi libnotify libsamplerate libwww lm-sensors lto lua lz4 lzip lzma lzo mad man memcached mhash mmap mng modules modules-compress motif mp3 mp4 mpeg mpi mplayer mtp multilib mysql mysqli native-extensions ncurses netcdf networkmanager nls nsplugin nvenc ocaml ocamlopt odbc offensive openal opencl opengl openmp opus oracle orc osc oss otf pam pcre pda pdf perl php png policykit portaudio posix postgres ppds profile pulseaudio python raw rdp readline recode ruby sasl scanner screencast sctp sdl session smp snappy sndfile snmp soap sockets socks5 sound spell sqlite ssl subversion suid svg svga symlink syslog szip taglib tcl tcmalloc tcpd theora threads tiff time64 truetype ttf udev udisks uefi unicode unwind upnp upnp-av upower usb v4l vaapi vdpau vhosts videos vim-syntax vnc vorbis vpx vulkan wavpack wayland webkit webp wmf x264 xattr xcb xcomposite xft xinerama xml xmpp xpm xv xvid zeroconf zip zlib zsh-completion zstd gnome-keyring kde qt6\"" >> /mnt/gentoo/etc/portage/make.conf

sleep 30s

message "Installing cpuid2cpuflags"
command emerge --q --oneshot app-portage/cpuid2cpuflags

message "installing gcc!"
command emerge --q --oneshot sys-devel/gcc
echo "install is done!"

message "Settings flags"
CPU_ARCH="$(gcc -march=native -Q --help=target | grep -- '-march=' | cut -f3 | cut -d ' ' -f 1 -z)"
CFLAGS="-march=${CPU_ARCH} -mtune-${CPU_ARCH} -O3 -pipe -fno-plt -pthread -fsanitize=bounds,alignment,object-size -fsanitize-undefined-trap-on-error \
        -fvisibility=hidden -fexceptions -Wformat -Werror=format-security \
        -Wvla -Wimplicit-fallthrough -Wno-unused-result -Wno-unneeded-internal-declaration -Warray-bounds"
CPU_FLAGS=$(cpuid2cpuflags | cut -c 1-15 --complement)




install_gentoo_prep()
{
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
  command chroot /mnt/gentoo /bin/env -i TERM="${TERM}" /bin/bash -c "install_gentoo_chroot"
}


install_gentoo_chroot()
{
  command env-update
  command source /etc/profile
  command export PS1="(chroot) $PS1"

  message "Installing portage snapshot"
  command emerge-webrsync
  message "Updating portage tree"
  command emerge --sync

message "Configuring /etc/portage/env/compiler-gcc"
  cat << EOF > /etc/portage/env/compiler-gcc
CC="gcc"
CXX="g++"
AR="ar"
NM="nm"
RANLIB="ranlib"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS}"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-gcc
  
  message "Configuring /etc/portage/make.conf"
  if [ -f /etc/portage/make.conf ]; then
  cp -v /etc/portage/make.conf /etc/portage/make.conf.default.bak
  fi
  cp -v /etc/portage/env/compiler-gcc /etc/portage/make.conf
  
  message "Configuring /etc/portage/env/compiler-gcc-static"
  cat << EOF > /etc/portage/env/compiler-gcc-static
CC="gcc"
CXX="g++"
AR="ar"
NM="nm"
RANLIB="ranlib"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -static -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS}"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-gcc-static

  message "Configuring /etc/portage/env/compiler-gcc-nvidia"
  cat << EOF > /etc/portage/env/compiler-gcc-nvidia
CC="gcc"
CXX="g++"
AR="ar"
NM="nm"
RANLIB="ranlib"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -static -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS} static-libs tools"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="nvidia"
EOF
  chmod 755 /etc/portage/env/compiler-gcc-nvidia

    message "Configuring /etc/portage/env/compiler-gcc-wine"
  cat << EOF > /etc/portage/env/compiler-gcc-wine
### Wine doesn't play nice with LTO; it usually doesn't compile
CC="gcc"
CXX="g++"
AR="ar"
NM="nm"
RANLIB="ranlib"
_CLFAGS="${CFLAGS/-fno-plt/}" ## Wine Doesn't play nice with -fno-plt
_CLFAGS="\${_CFLAGS/-O3/}" ## Wine is faster with -O2
CFLAGS="\${_CFLAGS} -O2"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -Wl,-O3,--sort-common,--as-needed" ## mingw can't use relro
CROSSCFLAGS="\${CFLAGS}"
CROSSCXXFLAGS="\${CXXFLAGS}"
CROSSLDFLAGS="\${LDFLAGS}"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS} capi cups fontconfig gecko gstreamer mono mp3 netapi nls odbc openal opengl osmesa oss pcap perl realtime run-exes samba scanner sdl ssl threads unwind xcomposite xinerama abi_x86_64 abi_x86_32 -custom-cflags -mingw -crossdev-mingw"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-gcc-wine

  message "Configuring /etc/portage/env/compiler-gcc-lto"
  cat << EOF > /etc/portage/env/compiler-gcc-lto
CC="gcc"
CXX="g++"
AR="gcc-ar"
NM="gcc-nm"
RANLIB="gcc-ranlib"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-flto -fuse-linker-plugin -lpthread -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS}"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-gcc-lto
  
  message "Configuring /etc/portage/env/compiler-gcc-static-lto"
  cat << EOF > /etc/portage/env/compiler-gcc-static-lto
CC="gcc"
CXX="g++"
AR="gcc-ar"
NM="gcc-nm"
RANLIB="gcc-ranlib"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-flto -fuse-linker-plugin -lpthread -static -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS}"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-gcc-static-lto

  message "Configuring /etc/portage/env/compiler-clang"
  cat << EOF > /etc/portage/env/compiler-clang
### See:
## https://wiki.gentoo.org/wiki/Clang
## https://bugs.gentoo.org/408963
## and
## https://github.com/BilyakA/gentoo-clang 
### for building an exclusively clang system

CC="clang"
CXX="clang++"
OBJC=clang
LD="/usr/bin/ld.lld"
AS="llvm-as"
### Ignore these three for non-LTO builds:
AR=""
NM=""
RANLIB=""
###
STRIP="llvm-strip"
OBJCOPY="llvm-objcopy"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -fuse-ld=lld -rtlib=compiler-rt -unwindlib=libunwind -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS} libcxxabi libunwind"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-clang
  
  message "Configuring /etc/portage/env/compiler-clang-static"
  cat << EOF > /etc/portage/env/compiler-clang-static
### See:
## https://wiki.gentoo.org/wiki/Clang
## https://bugs.gentoo.org/408963
## and
## https://github.com/BilyakA/gentoo-clang 
### for building an exclusively clang system

CC="clang"
CXX="clang++"
OBJC=clang
LD="/usr/bin/ld.lld"
AS="llvm-as"
### Ignore these three for non-LTO builds:
AR=""
NM=""
RANLIB=""
###
STRIP="llvm-strip"
OBJCOPY="llvm-objcopy"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -fuse-ld=lld -rtlib=compiler-rt -unwindlib=libunwind -static -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS} libcxxabi libunwind"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-clang-static

  message "Configuring /etc/portage/env/compiler-clang-nvidia"
  cat << EOF > /etc/portage/env/compiler-clang-nvidia
### See:
## https://wiki.gentoo.org/wiki/Clang
## https://bugs.gentoo.org/408963
## and
## https://github.com/BilyakA/gentoo-clang 
### for building an exclusively clang system

CC="clang"
CXX="clang++"
OBJC=clang
LD="/usr/bin/ld.lld"
AS="llvm-as"
### Ignore these three for non-LTO builds:
AR=""
NM=""
RANLIB=""
###
STRIP="llvm-strip"
OBJCOPY="llvm-objcopy"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -fuse-ld=lld -rtlib=compiler-rt -unwindlib=libunwind -static -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS} static-libs tools libcxxabi libunwind"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="nvidia"
EOF
  chmod 755 /etc/portage/env/compiler-clang-nvidia
  
  message "Configuring /etc/portage/env/compiler-clang-wine"
  cat << EOF > /etc/portage/env/compiler-clang-wine
## Not the Wine default because Wine doesn't always play nice with Clang at runtime

### See:
## https://wiki.gentoo.org/wiki/Clang
## https://bugs.gentoo.org/408963
## and
## https://github.com/BilyakA/gentoo-clang 
### for building an exclusively clang system

CC="clang"
CXX="clang++"
OBJC=clang
LD="/usr/bin/ld.lld"
AS="llvm-as"
### Ignore these three for non-LTO builds:
AR=""
NM=""
RANLIB=""
### Wine doesn't play nice with LTO; it usually doesn't compile
STRIP="llvm-strip"
OBJCOPY="llvm-objcopy"
_CLFAGS="${CFLAGS/-fno-plt/}" ## Wine Doesn't play nice with -fno-plt
_CLFAGS="\${_CFLAGS/-O3/}" ## Wine is faster with -O2
CFLAGS="\${_CFLAGS} -O2 -std=gnu89"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -fuse-ld=lld -rtlib=compiler-rt -unwindlib=libunwind -static -Wl,-O2,--sort-common,--as-needed" ## mingw can't use relro
CROSSCFLAGS="\${CFLAGS}"
CROSSCXXFLAGS="\${CXXFLAGS}"
CROSSLDFLAGS="\${LDFLAGS}"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS} capi cups fontconfig gecko gstreamer mono mp3 netapi nls odbc openal opengl osmesa oss pcap perl realtime run-exes samba scanner sdl ssl threads unwind xcomposite xinerama abi_x86_64 abi_x86_32 -custom-cflags -mingw -crossdev-mingw libcxxabi libunwind"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-clang-wine

  message "Configuring /etc/portage/env/compiler-clang-lto"
  cat << EOF > /etc/portage/env/compiler-clang-lto
### See:
## https://wiki.gentoo.org/wiki/Clang
## https://bugs.gentoo.org/408963
## and
## https://github.com/BilyakA/gentoo-clang 
### for building an exclusively clang system

CC="clang"
CXX="clang++"
OBJC=clang
LD="/usr/bin/ld.lld"
AR="llvm-ar"
NM="llvm-nm"
AS="llvm-as"
RANLIB="llvm-ranlib"
STRIP="llvm-strip"
OBJCOPY="llvm-objcopy"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} -flto=thin \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -fuse-ld=lld -rtlib=compiler-rt -unwindlib=libunwind -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS} libcxxabi libunwind"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-clang-lto
  
    message "Configuring /etc/portage/env/compiler-clang-static-lto"
  cat << EOF > /etc/portage/env/compiler-clang-static-lto
### See:
## https://wiki.gentoo.org/wiki/Clang
## https://bugs.gentoo.org/408963
## and
## https://github.com/BilyakA/gentoo-clang 
### for building an exclusively clang system
## This file exists to prevent system-critical packages from breaking due to dependency issues

CC="clang"
CXX="clang++"
OBJC=clang
LD="/usr/bin/ld.lld"
AR="llvm-ar"
NM="llvm-nm"
AS="llvm-as"
RANLIB="llvm-ranlib"
STRIP="llvm-strip"
OBJCOPY="llvm-objcopy"
_HARDENING_FLAGS="-fstack-clash-protection -fstack-protector-strong -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"
CFLAGS="${CFLAGS} -flto=thin \${_HARDENING_FLAGS}"
CXXFLAGS="\${CFLAGS}"
RUSTFLAGS="-C opt-level=3 -C target-cpu=native"
LDFLAGS="-lpthread -fuse-ld=lld -rtlib=compiler-rt -unwindlib=libunwind -static -Wl,-O3,--sort-common,--as-needed,-z,relro,-z,now"
CPU_FLAGS="${CPU_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided by the
# profile used for building.
USE="${USE_FLAGS} libcxxabi libunwind"
MAKEOPTS="-j${_PARALLEL_THREADS}"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
ACCEPT_LICENSE="*"
VIDEO_CARDS="${USED_VIDEO_CARDS}"
EOF
  chmod 755 /etc/portage/env/compiler-clang-static-lto

  message "Updating @world set"
  command ${EMERGE} --update --deep --newuse @world

  message "Installing filesystem packages"
  command ${EMERGE} "${PACKAGES}"

  message "Configuring timezone"
  command echo "$TIMEZONE" > /etc/timezone
  command emerge --quiet --config sys-libs/timezone-data

  message "Writing /etc/locale.gen file"
  cat << EOF > /etc/locale.gen
# All blank lines and lines starting with # are ignored.
#en_US ISO-8859-1
#en_US.UTF-8 UTF-8
en_DK.utf8
#ja_JP.EUC-JP EUC-JP
#ja_JP.UTF-8 UTF-8
#ja_JP EUC-JP
#en_HK ISO-8859-1
#en_PH ISO-8859-1
#de_DE ISO-8859-1
#de_DE@euro ISO-8859-15
#es_MX ISO-8859-1
#fa_IR UTF-8
#fr_FR ISO-8859-1
#fr_FR@euro ISO-8859-15
#it_IT ISO-8859-1
EOF

  command locale-gen
  command eselect locale set en_DK.utf8

  message "Selecting keymap"
  command sed -i "/keymap=/c\\keymap=\"dk\"" /etc/conf.d/keymaps

  message "Reloading Environment"
  command env-update && source /etc/profile && export PS1="(chroot) $PS1"

  if [ ${USE_KERNEL_CONFIG} != false ]; then
    message "Downloading Kernel Sources and mcelog"
    command ${EMERGE} sys-kernel/gentoo-sources app-admin/mcelog
  else
    message "Downloading Gentoo Kernel Source and mcelog"
    command ${EMERGE} sys-kernel/installkernel-gentoo
    command ${EMERGE} sys-kernel/gentoo-kernel-bin app-admin/mcelog
  fi  

  message "Cleaning Kernel source folder"
  command cd /usr/src/linux/ || return
  command make clean
  command make mrproper
  
  if [ ${USE_KERNEL_CONFIG} != false ]; then
    message "Loading kernel configuration file"
    command mv -v /kernel-config /usr/src/linux/.config-gentoo-final
    command cp -rv /usr/src/linux/.config-gentoo-final /usr/src/linux/.config
  fi

  message "Beginning Kernel Compilation Process"
  command make ${MAKE_OPTIONS}
  command make modules_install
  command make install

  message "Removing old kernel files"
  command rm -rf /boot/*old
  
  message "Creating bootx64.efi, (Meant for UEFI systems)"
  command mkdir -pv /boot/efi/boot
  command cp /boot/vmlinuz-* /boot/efi/boot/bootx64.efi

  message "Installing genkernel"
  command ${EMERGE} sys-kernel/genkernel
  
  message "Installing linux-firmware"
  command ${EMERGE} sys-kernel/linux-firmware

  if [ ${USE_KERNEL_CONFIG} != false ]; then
    command genkernel --${ROOT_FS_TYPE} --kerneldir=/usr/src/linux --kernel-config="/usr/src/linux/.config-gentoo-final" --install --no-ramdisk-modules initramfs
  else
    command genkernel --${ROOT_FS_TYPE} --kerneldir=/usr/src/linux --install --no-ramdisk-modules initramfs
  fi




}







#exporting necessary functions and variables
export -f install_gentoo_chroot
export -f message
export -f command

export LRED
export GREEN
export LCYAN
export LBLUE
export LPURPLE
export DGRAY
export NC

export TIMEZONE
export CPU_ARCH
export CPU_FLAGS
export USE_FLAGS
export IS_SSD
export IS_NVME
export ROOT_FS_TYPE
export HOSTNAME
export CFLAGS
export PACKAGES
export MAKE_OPTIONS
export TOOLS
export LATE_PACKAGES
export USE_KERNEL_CONFIG
export INSTALL_NVIDIA_DRIVER
export INSTALL_NVIDIA_OPEN_GPU_MODULES
export USED_VIDEO_CARDS
export INSTALL_STEAM
export EMERGE
export INSTALL_GAME_EMULATORS
export MAKE_CLANG_DEFAULT_COMPILER

install_gentoo_prep
