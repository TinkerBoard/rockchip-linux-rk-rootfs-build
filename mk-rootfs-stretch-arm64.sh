#!/bin/bash -e

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

if [ ! $PACKAGE ]; then
	PACKAGE='local'
fi

if [ ! $ARCH ]; then
	ARCH='arm64'
fi

if [ ! $VERSION ]; then
	VERSION="debug"
fi

if [ ! -e linaro-stretch-alip-*.tar.gz ]; then
	echo "\033[36m Run mk-base-debian.sh first \033[0m"
fi

finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR

if [ -e $TARGET_ROOTFS_DIR ]; then
    echo "Found the directory $TARGET_ROOTFS_DIR. Remove it now."
    sudo rm -rf $TARGET_ROOTFS_DIR
fi

echo -e "\033[36m Extract image \033[0m"
sudo tar -xpf linaro-stretch-alip-*.tar.gz

echo -e "\033[36m Copy overlay to rootfs \033[0m"
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rf packages/$ARCH/* $TARGET_ROOTFS_DIR/packages

if [ "$PACKAGE" == "local" ]; then
sudo mkdir -p $TARGET_ROOTFS_DIR/packages/local_packages
sudo cp -rf local_packages-$VERSION/* $TARGET_ROOTFS_DIR/packages/local_packages
fi

# some configs
sudo cp -rf overlay/* $TARGET_ROOTFS_DIR/
if [ "$ARCH" == "arm64"  ]; then
    sudo cp overlay-firmware/usr/bin/brcm_patchram_plus1_64 $TARGET_ROOTFS_DIR/usr/bin/brcm_patchram_plus1
    sudo cp overlay-firmware/usr/bin/rk_wifi_init_64 $TARGET_ROOTFS_DIR/usr/bin/rk_wifi_init
fi

# bt,wifi,audio firmware
sudo mkdir -p $TARGET_ROOTFS_DIR/system/lib/modules/
sudo find ../kernel/drivers/net/wireless/rockchip_wlan/*  -name "*.ko" | \
    xargs -n1 -i sudo cp {} $TARGET_ROOTFS_DIR/system/lib/modules/

sudo cp -rf overlay-firmware/* $TARGET_ROOTFS_DIR/
if [ "$VERSION" == "debug" ] || [ "$VERSION" == "jenkins" ]; then
	# adb, video, camera  test file
	sudo cp -rf overlay-debug/* $TARGET_ROOTFS_DIR/
fi

# adb
if [ "$ARCH" == "arm64"  ]; then
    sudo cp -rf overlay-debug/usr/local/share/adb/adbd-64 $TARGET_ROOTFS_DIR/usr/local/bin/adbd
fi

# glmark2
if [ "$ARCH" == "arm64" ]; then
sudo rm -rf $TARGET_ROOTFS_DIR/usr/local/share/glmark2
sudo mkdir -p $TARGET_ROOTFS_DIR/usr/local/share/glmark2
sudo cp -rf overlay-debug/usr/local/share/glmark2/aarch64/share/* $TARGET_ROOTFS_DIR/usr/local/share/glmark2
sudo cp overlay-debug/usr/local/share/glmark2/aarch64/bin/glmark2-es2 $TARGET_ROOTFS_DIR/usr/local/bin/glmark2-es2
fi


if [ "$VERSION" == "jenkins" ]; then
	# network
	sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
fi

echo -e "\033[36m Change root.....................\033[0m"
sudo cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper

if [ "$PACKAGE" == "local" ]; then
#dpkg -i -G -B /packages/packages-local/*.deb
dpkg -i /packages/local_packages/*.deb
fi

if [ "$PACKAGE" == "update" ]; then
apt-get update
# The package blueman is included in the base system.
#apt-get install -y blueman:arm64
#echo exit 101 > /usr/sbin/policy-rc.d
#chmod +x /usr/sbin/policy-rc.d
#apt-get install -y blueman:arm64
#rm -f /usr/sbin/policy-rc.d
fi

#---------------conflict workaround --------------
# The package xserver-xorg-input-evdev is removed from the base system.
#apt-get remove -y xserver-xorg-input-evdev

# The following packages are included in the base system.
#apt-get install -y libxfont1 libinput-bin libinput10 libwacom-common libwacom2 libunwind8 xserver-xorg-input-libinput

#---------------Xserver--------------
echo -e "\033[36m Setup Xserver.................... \033[0m"
dpkg -i  /packages/xserver/*

if [ "$PACKAGE" == "update" ]; then
apt-get install -f -y
fi

+#---------------Audio-----------------------
chmod 755 /etc/audio/auto_audio_switch.sh
chmod 666 /etc/audio/audio.conf

#---------------Video--------------
echo -e "\033[36m Setup Video.................... \033[0m"

# The following packages are included in the base system.
#if [ "$PACKAGE" == "update" ]; then
#apt-get install -y gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-alsa \
#	gstreamer1.0-plugins-good  gstreamer1.0-plugins-bad alsa-utils
#fi

dpkg -i  /packages/video/mpp/*.deb
dpkg -i  /packages/video/gstreamer/*.deb

if [ "$PACKAGE" == "update" ]; then
apt-get install -f -y
fi

#------------------libdrm------------
#dpkg -i  /packages/libdrm/*.deb
#apt-get install -f -y

#---------------Qt-Video--------------
dpkg -l | grep lxde
if [ "$?" -eq 0 ]; then
        # The following packages are included in the base system.
	# if target is base, we won't install qt
	#if [ "$PACKAGE" == "update" ]; then
	#apt-get install -y libqt5opengl5 libqt5qml5 libqt5quick5 libqt5widgets5 libqt5gui5 libqt5core5a qml-module-qtquick2 \
	#	libqt5multimedia5 libqt5multimedia5-plugins libqt5multimediaquick-p5
	#fi

	dpkg -i  /packages/video/qt/*

	if [ "$PACKAGE" == "update" ]; then
	apt-get install -f -y
	fi
else
	echo "won't install qt"
fi

#---------------Others--------------
#---------FFmpeg---------
# The following packages are included in the base system.
#if [ "$PACKAGE" == "update" ]; then
#apt-get install -y libsdl2-2.0-0:arm64 libcdio-paranoia1:arm64 libjs-bootstrap:arm64 libjs-jquery:arm64
#fi

dpkg -i  /packages/others/ffmpeg/*
#---------MPV---------
dpkg -i  /packages/others/mpv/*
apt-get install -f -y

#---------------Debug-------------- 
# The following packages are included in the base system.
#if [ "$VERSION" == "debug" ] || [ "$VERSION" == "jenkins" ] ; then
#	apt-get install -y sshfs openssh-server bash-completion
#fi

apt autoremove -y

#---------------Custom Script-------------- 
systemctl enable rockchip.service
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
rm /lib/systemd/system/wpa_supplicant@.service

#---------------get accelerated back for chromium v61--------------
ln -s /usr/lib/aarch64-linux-gnu/libGLESv2.so /usr/lib/chromium/libGLESv2.so
ln -s /usr/lib/aarch64-linux-gnu/libEGL.so /usr/lib/chromium/libEGL.so

echo $VERSION_NUMBER-$VERSION > /etc/version

#---------------Clean-------------- 
rm -rf /var/lib/apt/lists/*

EOF

sudo umount $TARGET_ROOTFS_DIR/dev
