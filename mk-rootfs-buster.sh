#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

if [ -e $TARGET_ROOTFS_DIR ]; then
	sudo rm -rf $TARGET_ROOTFS_DIR
fi

if [ "$ARCH" == "armhf" ]; then
	ARCH='armhf'
elif [ "$ARCH" == "arm64" ]; then
	ARCH='arm64'
else
    echo -e "\033[36m please input is: armhf or arm64...... \033[0m"
fi

if [ ! $VERSION ]; then
	VERSION="debug"
fi

if [ ! -e linaro-buster-alip-*.tar.gz ]; then
	echo "\033[36m Run mk-base-debian.sh first \033[0m"
fi

finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR

echo -e "\033[36m Extract image \033[0m"
sudo tar -xpf linaro-buster-alip-*.tar.gz

# packages folder
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rf packages/$ARCH/* $TARGET_ROOTFS_DIR/packages

<<<<<<< HEAD:mk-rootfs-stretch.sh
# Tinker Edge R: gpio_lib_python and gpio_lib_c
if [ "$ARCH" == "arm64" ]; then
	sudo rm -rf $TARGET_ROOTFS_DIR/usr/local/share/gpio_lib_c_rk3399PRO
	sudo rm -rf $TARGET_ROOTFS_DIR/usr/local/share/gpio_lib_python_rk3399PRO
	sudo rm -rf $TARGET_ROOTFS_DIR/usr/local/share/gpio_lib_scratch
	sudo cp -rf overlay-debug/usr/local/share/gpio_lib_c_rk3399PRO $TARGET_ROOTFS_DIR/usr/local/share/gpio_lib_c_rk3399PRO
	sudo cp -rf overlay-debug/usr/local/share/gpio_lib_python_rk3399PRO $TARGET_ROOTFS_DIR/usr/local/share/gpio_lib_python_rk3399PRO
	sudo cp -rf overlay-debug/usr/local/share/gpio_lib_scratch $TARGET_ROOTFS_DIR/usr/local/share/gpio_lib_scratch
fi

# copy overlay to target
=======
# overlay folder
>>>>>>> asus/rk3399pro_linux_release_v1.4.1_20201203:mk-rootfs-buster.sh
sudo cp -rf overlay/* $TARGET_ROOTFS_DIR/

# overlay-firmware folder
sudo cp -rf overlay-firmware/* $TARGET_ROOTFS_DIR/

# overlay-debug folder
# adb, video, camera  test file
sudo cp -rf overlay-debug/* $TARGET_ROOTFS_DIR/

## hack the serial
sudo cp -f overlay/usr/lib/systemd/system/serial-getty@.service $TARGET_ROOTFS_DIR/lib/systemd/system/serial-getty@.service

# adb
if [ "$ARCH" == "armhf" ] && [ "$VERSION" == "debug" ]; then
	sudo cp -rf overlay-debug/usr/local/share/adb/adbd-32 $TARGET_ROOTFS_DIR/usr/local/bin/adbd
elif [ "$ARCH" == "arm64"  ]; then
	sudo cp -rf overlay-debug/usr/local/share/adb/adbd-64 $TARGET_ROOTFS_DIR/usr/local/bin/adbd
fi

# bt/wifi firmware
if [ "$ARCH" == "armhf" ]; then
    sudo cp overlay-firmware/usr/bin/brcm_patchram_plus1_32 $TARGET_ROOTFS_DIR/usr/bin/brcm_patchram_plus1
    sudo cp overlay-firmware/usr/bin/rk_wifi_init_32 $TARGET_ROOTFS_DIR/usr/bin/rk_wifi_init
elif [ "$ARCH" == "arm64" ]; then
    sudo cp overlay-firmware/usr/bin/brcm_patchram_plus1_64 $TARGET_ROOTFS_DIR/usr/bin/brcm_patchram_plus1
    sudo cp overlay-firmware/usr/bin/rk_wifi_init_64 $TARGET_ROOTFS_DIR/usr/bin/rk_wifi_init
fi
sudo mkdir -p $TARGET_ROOTFS_DIR/system/lib/modules/
sudo find ../kernel/drivers/net/wireless/rockchip_wlan/*  -name "*.ko" | \
    xargs -n1 -i sudo cp {} $TARGET_ROOTFS_DIR/system/lib/modules/

# adb
if [ "$ARCH" == "armhf" ] && [ "$VERSION" == "debug" ]; then
	sudo cp -rf overlay-debug/usr/local/share/adb/adbd-32 $TARGET_ROOTFS_DIR/usr/local/bin/adbd
elif [ "$ARCH" == "arm64"  ]; then
	sudo cp -rf overlay-debug/usr/local/share/adb/adbd-64 $TARGET_ROOTFS_DIR/usr/local/bin/adbd
fi

# glmark2
sudo rm -rf $TARGET_ROOTFS_DIR/usr/local/share/glmark2
sudo mkdir -p $TARGET_ROOTFS_DIR/usr/local/share/glmark2
if [ "$ARCH" == "armhf" ] && [ "$VERSION" == "debug" ]; then
	sudo cp -rf overlay-debug/usr/local/share/glmark2/armhf/share/* $TARGET_ROOTFS_DIR/usr/local/share/glmark2
	sudo cp overlay-debug/usr/local/share/glmark2/armhf/bin/glmark2-es2 $TARGET_ROOTFS_DIR/usr/local/bin/glmark2-es2
elif [ "$ARCH" == "arm64" ] && [ "$VERSION" == "debug" ]; then
	sudo cp -rf overlay-debug/usr/local/share/glmark2/aarch64/share/* $TARGET_ROOTFS_DIR/usr/local/share/glmark2
	sudo cp overlay-debug/usr/local/share/glmark2/aarch64/bin/glmark2-es2 $TARGET_ROOTFS_DIR/usr/local/bin/glmark2-es2
fi

if [ "$VERSION" == "release" ]; then
	# install rknn toolkit script
	mkdir -p $TARGET_ROOTFS_DIR/home/linaro/Desktop
	sudo cp -rf overlay-debug/home/linaro/Desktop/install-rknn-toolkit-v1.6.0.sh $TARGET_ROOTFS_DIR/home/linaro/Desktop/install-rknn-toolkit-v1.6.0.sh
fi

echo -e "\033[36m Change root.....................\033[0m"
if [ "$ARCH" == "armhf" ]; then
	sudo cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
elif [ "$ARCH" == "arm64"  ]; then
	sudo cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
fi
sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

apt-get update

<<<<<<< HEAD:mk-rootfs-stretch.sh
# Tinker Edge R: Build ASUS GPIO libraries
# For gpio wiring c library
chmod a+x /usr/local/share/gpio_lib_c_rk3399PRO
cd /usr/local/share/gpio_lib_c_rk3399PRO
./build
# For gpio python library
cd /usr/local/share/gpio_lib_python_rk3399PRO/
python setup.py install
# For gpio python scratch
cd /usr/local/share/gpio_lib_scratch
sh ./setup.sh
cd /

# Tinker Edge R: Audio
chmod 755 /etc/audio/auto_audio_switch.sh
chmod 666 /etc/audio/audio.conf
chmod 755 /usr/lib/pm-utils/sleep.d/02pulseaudio-suspend

if [ "$VERSION" == "release" ]; then
	# change owner and permission for install rknn toolkit script
	chown -R linaro:linaro /home/linaro/Desktop/
	chmod a+x /home/linaro/Desktop/install-rknn-toolkit-v1.6.0.sh
fi
=======
chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod +x /etc/rc.local
>>>>>>> asus/rk3399pro_linux_release_v1.4.1_20201203:mk-rootfs-buster.sh

#---------------power management --------------
# The following packages are included in the base system.
#apt-get install -y busybox pm-utils triggerhappy
cp /etc/Powermanager/triggerhappy.service  /lib/systemd/system/triggerhappy.service

#---------------system--------------
apt-get install -y git fakeroot devscripts cmake binfmt-support dh-make dh-exec pkg-kde-tools device-tree-compiler \
bc cpio parted dosfstools mtools libssl-dev dpkg-dev isc-dhcp-client-ddns
apt-get install -f -y

#---------------Rga--------------
dpkg -i /packages/rga/*.deb

<<<<<<< HEAD:mk-rootfs-stretch.sh
#---------------Video--------------
# The following packages are included in the base system.
#echo -e "\033[36m Setup Video.................... \033[0m"
#apt-get install -y gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-alsa gstreamer1.0-plugins-base-apps
=======
echo -e "\033[36m Setup Video.................... \033[0m"
apt-get install -y gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-alsa \
gstreamer1.0-plugins-base-apps qtmultimedia5-examples
apt-get install -f -y
>>>>>>> asus/rk3399pro_linux_release_v1.4.1_20201203:mk-rootfs-buster.sh

dpkg -i  /packages/mpp/*
dpkg -i  /packages/gst-rkmpp/*.deb
#apt-mark hold gstreamer1.0-x
apt-get install -f -y

#---------Camera---------
<<<<<<< HEAD:mk-rootfs-stretch.sh
# The following packages are included in the base system.
#apt-get install cheese v4l-utils -y
dpkg -i  /packages/others/camera/*.deb
if [ "$ARCH" == "armhf" ]; then
       cp /packages/others/camera/libv4l-mplane.so /usr/lib/arm-linux-gnueabihf/libv4l/plugins/
elif [ "$ARCH" == "arm64" ]; then
       cp /packages/others/camera/libv4l-mplane.so /usr/lib/aarch64-linux-gnu/libv4l/plugins/
fi
cp /packages/others/camera/librkisp.so /usr/lib/

apt-get remove -y libgl1-mesa-dri:$ARCH xserver-xorg-input-evdev:$ARCH
# The following packages are included in the base system.
#apt-get install -y libxfont1:$ARCH libinput-bin:$ARCH libinput10:$ARCH libwacom2:$ARCH libunwind8:$ARCH xserver-xorg-input-libinput:$ARCH libxml2-dev:$ARCH libglib2.0-dev:$ARCH libpango1.0-dev:$ARCH libimlib2-dev:$ARCH librsvg2-dev:$ARCH libxcursor-dev:$ARCH g++ make libdmx-dev:$ARCH libxcb-xv0-dev:$ARCH libxfont-dev:$ARCH libxkbfile-dev:$ARCH libpciaccess-dev:$ARCH mesa-common-dev:$ARCH libpixman-1-dev:$ARCH

#---------------Xserver--------------
echo "deb http://http.debian.net/debian/ buster main contrib non-free" >> /etc/apt/sources.list
apt-get update

apt-get install -f -y x11proto-dev=2018.4-4 libxcb-xf86dri0-dev:$ARCH qtmultimedia5-examples:$ARCH

#---------update chromium-----
yes|apt-get install chromium -f -y
cp -f /packages/others/chromium/etc/chromium.d/default-flags /etc/chromium.d/
=======
echo -e "\033[36m Install camera.................... \033[0m"
apt-get install cheese v4l-utils -y
dpkg -i  /packages/rkisp/*.deb
dpkg -i  /packages/libv4l/*.deb

#---------Xserver---------
echo -e "\033[36m Install Xserver.................... \033[0m"
#apt-get build-dep -y xorg-server-source
apt-get install -y libgl1-mesa-dev libgles1 libgles1 libegl1-mesa-dev libc-dev-bin libc6-dev libfontenc-dev libfreetype6-dev \
libpciaccess-dev libpng-dev libpng-tools libxfont-dev libxkbfile-dev linux-libc-dev manpages manpages-dev xserver-common zlib1g-dev \
libdmx1 libpixman-1-dev libxcb-xf86dri0 libxcb-xv0
apt-get install -f -y
>>>>>>> asus/rk3399pro_linux_release_v1.4.1_20201203:mk-rootfs-buster.sh

dpkg -i /packages/xserver/*.deb
apt-get install -f -y
# apt-mark hold xserver-common xserver-xorg-core xserver-xorg-legacy

#---------------Openbox--------------
echo -e "\033[36m Install openbox.................... \033[0m"
apt-get install -y openbox
dpkg -i  /packages/openbox/*.deb
apt-get install -f -y

#------------------pcmanfm------------
echo -e "\033[36m Install pcmanfm.................... \033[0m"
apt-get install -y pcmanfm
dpkg -i  /packages/pcmanfm/*.deb
apt-get install -f -y

#------------------ffmpeg------------
echo -e "\033[36m Install ffmpeg.................... \033[0m"
apt-get install -y ffmpeg
dpkg -i  /packages/ffmpeg/*.deb
apt-get install -f -y

#------------------mpv------------
echo -e "\033[36m Install mpv.................... \033[0m"
apt-get install -y libmpv1 mpv
dpkg -i  /packages/mpv/*.deb
apt-get install -f -y

#---------update chromium-----
apt-get install -y chromium
apt-get install -f -y /packages/chromium/*.deb

<<<<<<< HEAD:mk-rootfs-stretch.sh
#---------MPV---------
#dpkg -i  /packages/mpv/*.deb
#apt-get install -f -y

#---------------Debug--------------
# The following packages are included in the base system.
#if [ "$VERSION" == "debug" ] || [ "$VERSION" == "jenkins" ] ; then
#	apt-get install -y sshfs openssh-server bash-completion
#fi
=======
#------------------libdrm------------
echo -e "\033[36m Install libdrm.................... \033[0m"
dpkg -i  /packages/libdrm/*.deb
apt-get install -f -y

# mark package to hold
# apt-mark hold libv4l-0 libv4l2rds0 libv4lconvert0 libv4l-dev v4l-utils
#apt-mark hold librockchip-mpp1 librockchip-mpp-static librockchip-vpu0 rockchip-mpp-demos
#apt-mark hold xserver-common xserver-xorg-core xserver-xorg-legacy
#apt-mark hold libegl-mesa0 libgbm1 libgles1 alsa-utils
#apt-get install -f -y
>>>>>>> asus/rk3399pro_linux_release_v1.4.1_20201203:mk-rootfs-buster.sh

#---------------Custom Script--------------
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
rm /lib/systemd/system/wpa_supplicant@.service

# Tinker Edge R: Remove packages which are not needed
apt-get install -f -y
apt autoremove -y

# Tinker Edge R
cp /etc/Powermanager/systemd-suspend.service  /lib/systemd/system/systemd-suspend.service

# Tinker Edge R
if [ "$VERSION" == "debug" ] || [ "$VERSION" == "jenkins" ] ; then
	systemctl enable test.service
fi

# Tinker Edge R: Mount partition p7
systemctl enable mountboot.service

# Tinker Edge R: blueman
bash /etc/init.d/blueman.sh
rm /etc/init.d/blueman.sh

# Tinker Edge R
echo $VERSION_NUMBER-$VERSION > /etc/version

#---------------Clean--------------
rm -rf /var/lib/apt/lists/*

EOF

sudo umount $TARGET_ROOTFS_DIR/dev
