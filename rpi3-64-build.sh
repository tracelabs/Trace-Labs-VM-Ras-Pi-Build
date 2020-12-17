#!/bin/bash
# This is the Raspberry Pi 2 v1.2/3/4 Kali ARM 64 bit build script - http://www.kali.org/downloads
# A trusted Kali Linux image created by Offensive Security - http://www.offensive-security.com
set -e

# Give the option to install all tools now, or just create a min install
echo "Would you like to install all additional tools?  y/n:  "
read answer
if [[ $answer != "y" && $answer != "n" ]]; then
    echo "Not a valid choice"
    exit 0
fi


# Uncomment to activate debug
# debug=true
if [ "$debug" = true ]; then
  exec > >(tee -a -i "${0%.*}.log") 2>&1
  set -x
fi

# Architecture
architecture=${architecture:-"arm64"}
# Generate a random machine name to be used.
machine=$(dbus-uuidgen)
# Custom hostname variable
hostname=${2:-kali}
# Custom image file name variable - MUST NOT include .img at the end.
imagename=${3:-kali-linux-$1-rpi4-nexmon-64}
# Suite to use, valid options are:
# kali-rolling, kali-dev, kali-bleeding-edge, kali-dev-only, kali-experimental, kali-last-snapshot
suite=${suite:-"kali-rolling"}
# Free space rootfs in MiB
free_space="300"
# /boot partition in MiB
bootsize="128"
# Select compression, xz or none
compress="none"
# Choose filesystem format to format ( ext3 or ext4 )
fstype="ext3"
# If you have your own preferred mirrors, set them here.
mirror=${mirror:-"http://http.kali.org/kali"}
# Gitlab url Kali repository
kaligit="https://gitlab.com/kalilinux"
# Github raw url
githubraw="https://raw.githubusercontent.com"

# Check EUID=0 you can run any binary as root.
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or have super user permissions"
  echo "Use: sudo $0 ${1:-2.0} ${2:-kali}"
  exit 1
fi

# Pass version number
if [[ $# -eq 0 ]] ; then
  echo "Please pass version number, e.g. $0 2.0, and (if you want) a hostname, default is kali"
  exit 0
fi

# Check exist bsp directory.
if [ ! -e "bsp" ]; then
  echo "Error: missing bsp directory structure"
  echo "Please clone the full repository ${kaligit}/build-scripts/kali-arm"
  exit 255
fi

# Current directory
current_dir="$(pwd)"
# Base directory
basedir=${current_dir}/rpi4-nexmon-64-"$1"
# Working directory
work_dir="${basedir}/kali-${architecture}"

# Check directory build
if [ -e "${basedir}" ]; then
  echo "${basedir} directory exists, will not continue"
  exit 1
elif [[ ${current_dir} =~ [[:space:]] ]]; then
  echo "The directory "\"${current_dir}"\" contains whitespace. Not supported."
  exit 1
else
  echo "The basedir thinks it is: ${basedir}"
  mkdir -p ${basedir}
fi



components="main,contrib,non-free"
#arm="kali-linux-arm ntpdate"
arm="ntpdate"
base="apt-transport-https apt-utils bash-completion console-setup dialog e2fsprogs ifupdown initramfs-tools inxi iw man-db mlocate netcat-traditional net-tools parted pciutils psmisc rfkill screen tmux unrar usbutils wget whiptail zerofree gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"
desktop="kali-desktop-xfce kali-root-login xserver-xorg-video-fbdev xserver-xorg-input-evdev xserver-xorg-input-synaptics"
tools=""
services=""
# additional packages that can be installed from kali repo
extras="kali-linux-core git golang python3-pip"

packages="${arm} ${base}"

# Automatic configuration to use an http proxy, such as apt-cacher-ng.
# You can turn off automatic settings by uncommenting apt_cacher=off.
# apt_cacher=off
# By default the proxy settings are local, but you can define an external proxy.
# proxy_url="http://external.intranet.local"
apt_cacher=${apt_cacher:-"$(lsof -i :3142|cut -d ' ' -f3 | uniq | sed '/^\s*$/d')"}
if [ -n "$proxy_url" ]; then
  export http_proxy=$proxy_url
elif [ "$apt_cacher" = "apt-cacher-ng" ] ; then
  if [ -z "$proxy_url" ]; then
    proxy_url=${proxy_url:-"http://127.0.0.1:3142/"}
    export http_proxy=$proxy_url
  fi
fi

# Detect architecture
case ${architecture} in
  arm64)
    qemu_bin="/usr/bin/qemu-aarch64-static"
    lib_arch="aarch64-linux-gnu" ;;
  armhf)
    qemu_bin="/usr/bin/qemu-arm-static"
    lib_arch="arm-linux-gnueabihf" ;;
  armel)
    qemu_bin="/usr/bin/qemu-arm-static"
    lib_arch="arm-linux-gnueabi" ;;
esac

# create the rootfs - not much to modify here, except maybe throw in some more packages if you want.
eatmydata debootstrap --foreign --keyring=/usr/share/keyrings/kali-archive-keyring.gpg --include=kali-archive-keyring,eatmydata \
  --components=${components} --arch ${architecture} ${suite} ${work_dir} http://http.kali.org/kali

# systemd-nspawn enviroment
systemd-nspawn_exec(){
  LANG=C systemd-nspawn -q --bind-ro ${qemu_bin} --capability=cap_setfcap --setenv=RUNLEVEL=1 -M ${machine} -D ${work_dir} "$@"
}

# We need to manually extract eatmydata to use it for the second stage.
for archive in ${work_dir}/var/cache/apt/archives/*eatmydata*.deb; do
  dpkg-deb --fsys-tarfile "$archive" > ${work_dir}/eatmydata
  tar -xkf ${work_dir}/eatmydata -C ${work_dir}
  rm -f ${work_dir}/eatmydata
done

# Prepare dpkg to use eatmydata
systemd-nspawn_exec dpkg-divert --divert /usr/bin/dpkg-eatmydata --rename --add /usr/bin/dpkg

cat > ${work_dir}/usr/bin/dpkg << EOF
#!/bin/sh
if [ -e /usr/lib/${lib_arch}/libeatmydata.so ]; then
    [ -n "\${LD_PRELOAD}" ] && LD_PRELOAD="\$LD_PRELOAD:"
    LD_PRELOAD="\$LD_PRELOAD\$so"
fi
for so in /usr/lib/${lib_arch}/libeatmydata.so; do
    [ -n "\$LD_PRELOAD" ] && LD_PRELOAD="\$LD_PRELOAD:"
    LD_PRELOAD="\$LD_PRELOAD\$so"
done
export LD_PRELOAD
exec "\$0-eatmydata" --force-unsafe-io "\$@"
EOF
chmod 755 ${work_dir}/usr/bin/dpkg

# debootstrap second stage
systemd-nspawn_exec eatmydata /debootstrap/debootstrap --second-stage

cat << EOF > ${work_dir}/etc/apt/sources.list
deb ${mirror} ${suite} ${components//,/ }
#deb-src ${mirror} ${suite} ${components//,/ }
EOF

# Set hostname
echo "${hostname}" > ${work_dir}/etc/hostname

# So X doesn't complain, we add kali to hosts
cat << EOF > ${work_dir}/etc/hosts
127.0.0.1       ${hostname}    localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF

# Disable IPv6
cat << EOF > ${work_dir}/etc/modprobe.d/ipv6.conf
# Don't load ipv6 by default
alias net-pf-10 off
EOF

cat << EOF > ${work_dir}/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
EOF

# Copy directory bsp into build dir.
cp -rp bsp ${work_dir}

export MALLOC_CHECK_=0 # workaround for LP: #520465

# Enable the use of http proxy in third-stage in case it is enabled.
if [ -n "$proxy_url" ]; then
  echo "Acquire::http { Proxy \"$proxy_url\" };" > ${work_dir}/etc/apt/apt.conf.d/66proxy
fi


# Third stage
#  Third stage is where the magic happens
# This is where all the additional packages are installed and other changes made
cat << EOF >  ${work_dir}/third-stage
#!/bin/bash -e
export DEBIAN_FRONTEND=noninteractive

eatmydata apt-get update

eatmydata apt-get -y install binutils ca-certificates cmake console-common git initramfs-tools less locales nano u-boot-tools

# Create kali user with kali password... but first, we need to manually make some groups because they don't yet exist...
# This mirrors what we have on a pre-installed VM, until the script works properly to allow end users to set up their own... user.
# However we leave off floppy, because who a) still uses them, and b) attaches them to an SBC!?
# And since a lot of these have serial devices of some sort, dialout is added as well.
# scanner, lpadmin and bluetooth have to be added manually because they don't
# yet exist in /etc/group at this point.
groupadd -r -g 118 bluetooth
groupadd -r -g 113 lpadmin
groupadd -r -g 122 scanner
groupadd -g 1000 osint

useradd -m -u 1000 -g 1000 -G sudo,audio,bluetooth,cdrom,dialout,dip,lpadmin,netdev,plugdev,scanner,video,osint -s /bin/bash osint
echo "osint:osint" | chpasswd

aptops="--allow-change-held-packages -o dpkg::options::=--force-confnew -o Acquire::Retries=3"

eatmydata apt-get install -y \$aptops ${packages} || eatmydata apt-get --yes --fix-broken install
eatmydata apt-get install -y \$aptops ${packages} || eatmydata apt-get --yes --fix-broken install
eatmydata apt-get install -y \$aptops ${desktop} ${extras} || eatmydata apt-get --yes --fix-broken install
eatmydata apt-get install -y \$aptops ${desktop} ${extras} || eatmydata apt-get --yes --fix-broken install
# We want systemd-timesyncd not sntp which gets pulled in by something in kali-linux-default
eatmydata apt-get install -y \$aptops --autoremove systemd-timesyncd

# Linux console/Keyboard configuration
echo 'console-common console-data/keymap/policy select Select keymap from full list' | debconf-set-selections
echo 'console-common console-data/keymap/full select en-latin1-nodeadkeys' | debconf-set-selections

# Copy all services
cp -p /bsp/services/all/*.service /etc/systemd/system/
cp -p /bsp/services/rpi/*.service /etc/systemd/system/

# Scripts for monitor mode
#install -m755 /bsp/scripts/monstart /usr/bin/
#install -m755 /bsp/scripts/monstop /usr/bin/

# Resize rootfs script
install -m755 /bsp/scripts/rpi-resizerootfs /usr/sbin/

# Add rpi userland to the path (e.g. vcgencmd)
install -m644 /bsp/configs/raspi-userland.conf /etc/ld.so.conf.d/
install -m644 /bsp/configs/vc.sh /etc/profile.d/vc.sh
install -m644 /bsp/udev/99-vchiq-permissions.rules /etc/udev/rules.d/

# Bluetooth enabling
#install -m644 /bsp/bluetooth/rpi/99-com.rules /etc/udev/rules.d/
#install -m644 /bsp/bluetooth/rpi/hciuart.service /etc/systemd/system/
#install -m755 /bsp/bluetooth/rpi/btuart /usr/bin/

# Copy in the bluetooth firmware
#install -m644 /bsp/firmware/rpi/BCM43430A1.hcd -D /lib/firmware/brcm/BCM43430A1.hcd

# Re4son's rpi-tft configurator
wget -q ${githubraw}/Re4son/RPi-Tweaks/master/kalipi-tft-config/kalipi-tft-config -O /usr/bin/kalipi-tft-config
chmod 755 /usr/bin/kalipi-tft-config

# Install the kernel packages
echo "deb http://http.re4son-kernel.com/re4son kali-pi main" > /etc/apt/sources.list.d/re4son.list
wget -qO /etc/apt/trusted.gpg.d/kali_pi-archive-keyring.gpg https://re4son-kernel.com/keys/http/kali_pi-archive-keyring.gpg
eatmydata apt-get update
eatmydata apt-get install --yes --allow-change-held-packages -o dpkg::options::=--force-confnew kalipi-kernel kalipi-bootloader kalipi-re4son-firmware kalipi-kernel-headers

# Regenerated the shared-mime-info database on the first boot
# since it fails to do so properly in a chroot
systemctl enable smi-hack

# Resize filesystem on first boot
systemctl enable rpi-resizerootfs

# Generate SSH host keys on first run
systemctl enable regenerate_ssh_host_keys

# Enable hciuart for bluetooth device
#systemctl enable hciuart

# Enable copying of user wpa_supplicant.conf file
install -m755 /bsp/scripts/copy-user-wpasupplicant.sh /usr/bin
systemctl enable copy-user-wpasupplicant

# Enable... enabling ssh by putting ssh or ssh.txt file in /boot
systemctl enable enable-ssh

# Allow users to use NM over ssh
install -m644 /bsp/polkit/10-NetworkManager.pkla /var/lib/polkit-1/localauthority/50-local.d

cd /root
apt download -o APT::Sandbox::User=root ca-certificates 2>/dev/null

# Attempt to build the raspi userland
cd /root
git clone https://github.com/raspberrypi/userland
cd userland
sed -i 's/-j4/-j2/g' buildme
./buildme --aarch64 2>/dev/null
cd
rm -rf /root/userland

# Copy over the default bashrc
cp /etc/skel/.bashrc /root/.bashrc

# Set a REGDOMAIN.  This needs to be done or wireless doesn't work correctly on the RPi 3B+
sed -i -e 's/REGDOM.*/REGDOMAIN=00/g' /etc/default/crda

# Enable login over serial
echo "T0:23:respawn:/sbin/agetty -L ttyAMA0 115200 vt100" >> /etc/inittab

# Try and make the console a bit nicer
# Set the terminus font for a bit nicer display.
sed -i -e 's/FONTFACE=.*/FONTFACE="Terminus"/' /etc/default/console-setup
sed -i -e 's/FONTSIZE=.*/FONTSIZE="6x12"/' /etc/default/console-setup

# Fix startup time from 5 minutes to 15 secs on raise interface wlan0
sed -i 's/^TimeoutStartSec=5min/TimeoutStartSec=15/g' "/lib/systemd/system/networking.service"

# Clean up dpkg.eatmydata
rm -f /usr/bin/dpkg
dpkg-divert --remove --rename /usr/bin/dpkg


EOF

# Run third stage
chmod 755 ${work_dir}/third-stage
systemd-nspawn_exec /third-stage

# optionally run a fourth stage
# if enabled, this will install the base tools as outlined in 
# install-packages.sh

if [[ $answer == "y" ]]; then
    # copy over bin files that kick off apps
    cp -r bin ${work_dir}/opt/bin  
    
    #copy updater script to root system
    mkdir ${work_dir}/usr/share/updater
    cp updater.sh ${work_dir}/usr/share/updater

     #copy updater icon to desktop
    cp etc/skel/Desktop/Updater.desktop {$work_dir}/home/osint/Desktop/Updater.desktop

    #install additional packages and apps
    cp install-packages.sh ${work_dir}/install-packages.sh
    systemd-nspawn_exec /install-packages.sh
    systemd-nspawn_exec rm -f /install-packages.sh
    # copy over menu files
    cp -R usr/share/applications ${work_dir}/usr/share/
    cp -R usr/share/desktop-directories ${work_dir}/usr/share/
    cp -r etc/xdg/menus/applications-merged ${work_dir}/etc/xdg/menus/
    #copy over firefox bookmarks
    cp -r usr/share/firefox-esr/distribution/* ${work_dir}/usr/share/firefox-esr/distribution

    #copy over background image and config file
    cp usr/share/backgrounds/kali/tracelabs.png ${work_dir}/usr/share/backgrounds/kali/tracelabs.png
    cp etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml ${work_dir}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

   
fi


# Clean system

systemd-nspawn_exec rm -f /0
systemd-nspawn_exec rm -rf /bsp
systemd-nspawn_exec fc-cache -frs
systemd-nspawn_exec rm -rf /tmp/*
systemd-nspawn_exec rm -rf /etc/*-
systemd-nspawn_exec rm -rf /hs_err*
systemd-nspawn_exec rm -rf /third-stage
systemd-nspawn_exec rm -rf /userland
systemd-nspawn_exec rm -rf /opt/vc/src
systemd-nspawn_exec rm -f /etc/ssh/ssh_host_*
systemd-nspawn_exec rm -rf /var/lib/dpkg/*-old
systemd-nspawn_exec rm -rf /var/lib/apt/lists/*
systemd-nspawn_exec rm -rf /var/cache/apt/*.bin
systemd-nspawn_exec rm -rf /var/cache/apt/archives/*
systemd-nspawn_exec rm -rf /var/cache/debconf/*.data-old
systemd-nspawn_exec rm -f /fourth-stage
#systemd-nspawn_exec "for logs in $(find /var/log -type f); do > $logs; done"
#systemd-nspawn_exec history -c


# Define DNS server after last running systemd-nspawn.
echo "nameserver 8.8.8.8" > ${work_dir}/etc/resolv.conf

# Disable the use of http proxy in case it is enabled.
if [ -n "$proxy_url" ]; then
  unset http_proxy
  rm -rf ${work_dir}/etc/apt/apt.conf.d/66proxy
fi

# Mirror & suite replacement
if [[ ! -z "${4}" || ! -z "${5}" ]]; then
  mirror=${4}
  suite=${5}
fi

# Define sources.list
cat << EOF > ${work_dir}/etc/apt/sources.list
deb ${mirror} ${suite} ${components//,/ }
#deb-src ${mirror} ${suite} ${components//,/ }
EOF

# Create cmdline.txt file
cat << EOF > ${work_dir}/boot/cmdline.txt
dwc_otg.fiq_fix_enable=2 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=$fstype rootwait rootflags=noload net.ifnames=0
EOF

# systemd doesn't seem to be generating the fstab properly for some people, so
# let's create one.
cat << EOF > ${work_dir}/etc/fstab
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    defaults          0       2
/dev/mmcblk0p2  /               $fstype    defaults,noatime  0       1
EOF

# Copy a default config, with everything commented out so people find it when
# they go to add something when they are following instructions on a website.
cp ./bsp/firmware/rpi/config.txt ${work_dir}/boot/config.txt
# Remove repeat conditional filters [all] in config.txt
sed -i "59,66d" ${work_dir}/boot/config.txt

# To boot 64bit, these lines *have* to be in config.txt
cat << EOF >> ${work_dir}/boot/config.txt

[pi2]
# Pi2 is 64bit only on v1.2+
# 64bit kernel for Raspberry Pi 2 is called kernel8 (armv8a)
kernel=kernel8-alt.img
[pi3]
# 64bit kernel for Raspberry Pi 3 is called kernel8 (armv8a)
kernel=kernel8-alt.img
[pi4]
# Enable DRM VC4 V3D driver on top of the dispmanx display stack
#dtoverlay=vc4-fkms-v3d
#max_framebuffers=2
# 64bit kernel for Raspberry Pi 4 is called kernel8l (armv8a)
kernel=kernel8l-alt.img
[all]
#dtoverlay=vc4-fkms-v3d
# Tell firmware to go 64bit mode.
arm_64bit=1
EOF

cd ${current_dir}

# Calculate the space to create the image.
root_size=$(du -s -B1 ${work_dir} --exclude=${work_dir}/boot | cut -f1)
echo $root_size
root_extra=$((${root_size}/1024/1000*5*1024/5))
echo $root_extra
raw_size=$(($((${free_space}*1024))+${root_extra}+$((${bootsize}*1024))+4096))
echo $raw_size

# Create the disk and partition it
echo "Creating image file ${imagename}.img"
fallocate -l $(echo ${raw_size}Ki | numfmt --from=iec-i --to=si) ${current_dir}/${imagename}.img
echo "Partitioning ${imagename}.img"
parted -s ${current_dir}/${imagename}.img mklabel msdos
parted -s ${current_dir}/${imagename}.img mkpart primary fat32 1MiB ${bootsize}MiB
parted -s -a minimal ${current_dir}/${imagename}.img mkpart primary $fstype ${bootsize}MiB 100%

# Set the partition variables
loopdevice=$(losetup --show -fP "${current_dir}/${imagename}.img")
bootp="${loopdevice}p1"
rootp="${loopdevice}p2"

# Create file systems
mkfs.vfat -n BOOT -F 32 -v ${bootp}
if [[ $fstype == ext4 ]]; then
  features="-O ^64bit,^metadata_csum"
elif [[ $fstype == ext3 ]]; then
  features="-O ^64bit"
fi
mkfs $features -t $fstype -L ROOTFS ${rootp}

# Create the dirs for the partitions and mount them
mkdir -p ${basedir}/root/
mount ${rootp} ${basedir}/root
mkdir -p ${basedir}/root/boot
mount ${bootp} ${basedir}/root/boot

echo "Rsyncing rootfs into image file"
rsync -HPavz -q --exclude boot ${work_dir}/ ${basedir}/root/
rsync -rtx -q ${work_dir}/boot ${basedir}/root
sync

# Make sure to enable ssh on the device by default
touch "${basedir}"/root/boot/ssh

sync
# Unmount filesystems
umount -l ${bootp}
umount -l ${rootp}

# Remove loop devices
losetup -d ${loopdevice}

# Limite use cpu function
limit_cpu (){
  rand=$(tr -cd 'A-Za-z0-9' < /dev/urandom | head -c4 ; echo) # Randowm name group
  cgcreate -g cpu:/cpulimit-${rand} # Name of group cpulimit
  cgset -r cpu.shares=800 cpulimit-${rand} # Max 1024
  cgset -r cpu.cfs_quota_us=80000 cpulimit-${rand} # Max 100000
  # Retry command
  local n=1; local max=5; local delay=2
  while true; do
    cgexec -g cpu:cpulimit-${rand} "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo -e "\e[31m Command failed. Attempt $n/$max \033[0m"
        sleep $delay;
      else
        echo "The command has failed after $n attempts."
        break
      fi
    }
  done
}

if [ $compress = xz ]; then
  if [ $(arch) == 'x86_64' ]; then
    echo "Compressing ${imagename}.img"
    [ $(nproc) \< 3 ] || cpu_cores=3 # cpu_cores = Number of cores to use
    limit_cpu pixz -p ${cpu_cores:-2} ${current_dir}/${imagename}.img # -p Nº cpu cores use
    chmod 644 ${current_dir}/${imagename}.img.xz
  fi
else
  chmod 644 ${current_dir}/${imagename}.img
fi

# Clean up all the temporary build stuff and remove the directories.
# Comment this out to keep things around if you want to see what may have gone wrong.
echo "Cleaning up the temporary build files..."
rm -rf "${basedir}"
