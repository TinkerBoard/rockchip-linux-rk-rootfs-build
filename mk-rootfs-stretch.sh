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

# Initialized to "eng", however this should be set in build.sh
if [ ! $VERSION_NUMBER ]; then
	VERSION_NUMBER="eng"
fi

if [ ! -e linaro-stretch-alip-*.tar.gz ]; then
	echo "\033[36m Run mk-base-debian.sh first \033[0m"
fi

finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR

echo -e "\033[36m Extract image \033[0m"
sudo tar -xpf linaro-stretch-alip-*.tar.gz

echo -e "\033[36m Copy overlay to rootfs \033[0m"
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rf packages/$ARCH/* $TARGET_ROOTFS_DIR/packages

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
sudo cp -rf overlay/* $TARGET_ROOTFS_DIR/
sudo cp -rf overlay-firmware/* $TARGET_ROOTFS_DIR/
if [ "$VERSION" == "debug" ] || [ "$VERSION" == "jenkins" ]; then
	sudo cp -rf overlay-debug/* $TARGET_ROOTFS_DIR/
fi

if [ "$VERSION" == "jenkins" ]; then
	# network
	sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
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

if [ "$VERSION" == "debug" ]; then
	echo -e "\033[36m Enable adb/glmark2 for debug \033[0m"
fi

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
    sudo cp -rf overlay-debug/home/linaro/Desktop/rknn_toolkit_v1.6.0 $TARGET_ROOTFS_DIR/home/linaro/Desktop/rknn_toolkit_v1.6.0
    sudo cp -f overlay-debug/home/linaro/Desktop/install-rknn-toolkit-v1.6.0.sh $TARGET_ROOTFS_DIR/home/linaro/Desktop/
fi

echo -e "\033[36m Change root.....................\033[0m"
if [ "$ARCH" == "armhf" ]; then
	sudo cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
elif [ "$ARCH" == "arm64"  ]; then
	sudo cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
fi

# Utilize the nameserver configuration from the host.
# This will be reset back to the original one in the end.
sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
apt-get update

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

# Tinker Edge R: rknn-toolkit
# change owner and permission for install rknn toolkit script
chown -R linaro:linaro /home/linaro/Desktop/
chmod a+x /home/linaro/Desktop/install-rknn-toolkit-v1.6.0.sh
# Tinker Edge R: rknn-toolkit

#---------------power management --------------
# The following packages are included in the base system.
#apt-get install -y busybox pm-utils triggerhappy
cp /etc/Powermanager/triggerhappy.service  /lib/systemd/system/triggerhappy.service

#---------------Rga--------------
dpkg -i /packages/rga/*.deb

#---------------Video--------------
# The following packages are included in the base system.
#echo -e "\033[36m Setup Video.................... \033[0m"
#apt-get install -y gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-alsa gstreamer1.0-plugins-base-apps

dpkg -i  /packages/mpp/*
dpkg -i  /packages/gst-rkmpp/*.deb
dpkg -i  /packages/gst-base/*.deb
apt-mark hold gstreamer1.0-x
apt-get install -f -y

#---------------Others--------------
#---------Camera---------
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

sed -i '/buster/'d /etc/apt/sources.list
apt-get update

echo -e "\033[36m Setup Xserver.................... \033[0m"
dpkg -i  /packages/xserver/*
#---------------Openbox--------------
echo -e "\033[36m Install openbox.................... \033[0m"
dpkg -i  /packages/openbox/*.deb

#------------------pcmanfm------------
dpkg -i  /packages/pcmanfm/*.deb
apt-get install -f -y

#------------------libdrm------------
dpkg -i  /packages/libdrm/*.deb
apt-get install -f -y

#---------kmssink---------
dpkg -i  /packages/gst-bad/*.deb
apt-get install -f -y

#---------FFmpeg---------
dpkg -i  /packages/ffmpeg/*.deb
apt-get install -f -y

#---------MPV---------
#dpkg -i  /packages/mpv/*.deb
#apt-get install -f -y

#---------------Debug--------------
# The following packages are included in the base system.
#if [ "$VERSION" == "debug" ] || [ "$VERSION" == "jenkins" ] ; then
#	apt-get install -y sshfs openssh-server bash-completion
#fi

#---------------Custom Script--------------
systemctl enable rockchip.service
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service
rm /lib/systemd/system/wpa_supplicant@.service

#-------ASUS customization start-------
# Remove packages which are not needed.
apt autoremove -y

bash /etc/init.d/blueman.sh
rm /etc/init.d/blueman.sh

# Tinker Edge R
cp /etc/Powermanager/systemd-suspend.service  /lib/systemd/system/systemd-suspend.service

# mount partition p7
systemctl enable mountboot.service

if [ "$VERSION" == "debug" ] ; then
    # Enable test.service to change the owner for the test tools.
    systemctl enable test.service
fi

echo $VERSION_NUMBER > /etc/version
#-------ASUS customization end-------

#---------------Clean--------------
rm -rf /var/lib/apt/lists/*

EOF

sudo umount $TARGET_ROOTFS_DIR/dev

# Reset resolve.conf to the original one.
sudo mv $TARGET_ROOTFS_DIR/etc/resolv.conf~ $TARGET_ROOTFS_DIR/etc/resolv.conf
