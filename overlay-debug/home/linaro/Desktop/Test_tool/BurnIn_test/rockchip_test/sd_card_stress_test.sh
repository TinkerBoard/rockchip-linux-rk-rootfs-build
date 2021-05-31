#!/bin/bash

#read -p "input source path:" src
#read -p "input destination path:" dest

TAG=SD
logfile=$2
log()
{
	echo "$(date +'%Y%m%d_%H.%M.%S') $TAG $@"  | tee -a $logfile
}


sd_path=$(grep mmcblk0 /proc/mounts | cut -d ' ' -f 2)
dev_name=$(grep mmcblk0 /proc/mounts | cut -d ' ' -f 1)
if [ -z $sd_path ]; then
	log "SD card not detect, exit test!!"
	exit
fi

umount "$dev_name"
rm -rf /media/linaro/sd
mkdir /media/linaro/sd
mount -o rw "$dev_name" /media/linaro/sd
sd_path=$(grep mmcblk0 /proc/mounts | cut -d ' ' -f 2)

if [ $sd_path != "/media/linaro/sd" ]; then
	log "SD card mount fail, exit test!!"
	exit
fi

src=/$sd_path/src
dest=/$sd_path/dest
emmc_src="$1/rockchip_test/src"

cp -vr $emmc_src /$sd_path/src

while [ 1 != 2 ]
do
    if [ -e ${dest} ]; then
        log "the file is existed and remove it" && rm -vrf ${dest}
	sleep 1
    else
        cp -vr ${src} ${dest}
	sleep 1
    fi
done

