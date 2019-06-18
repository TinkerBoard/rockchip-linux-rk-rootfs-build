#!/bin/bash

#read -p "input source path:" src
#read -p "input destination path:" dest

sd_path=$(grep mmcblk0 /proc/mounts | cut -d ' ' -f 2)
dev_name=$(grep mmcblk0 /proc/mounts | cut -d ' ' -f 1)
if [ -z $sd_path ]; then
	echo SD card not detect, exit test!!
	exit
fi

umount "$dev_name"
rm -rf /media/linaro/sd
mkdir /media/linaro/sd
mount -o rw "$dev_name" /media/linaro/sd
sd_path=$(grep mmcblk0 /proc/mounts | cut -d ' ' -f 2)

if [ $sd_path != "/media/linaro/sd" ]; then
	echo SD card mount fail, exit test!!
	exit
fi

src=/$sd_path/src
dest=/$sd_path/dest
emmc_src="$1/rockchip_test/src"

cp -vr $emmc_src /$sd_path/src

while [ 1 != 2 ]
do
    if [ -e ${dest} ]; then
        echo "the file is existed and remove it" && rm -vrf ${dest}
	sleep 1
    else
        cp -vr ${src} ${dest}
	sleep 1
    fi
done

