#!/bin/bash

#read -p "input source path:" src
#read -p "input destination path:" dest
TAG=EMMC
src="$1/rockchip_test/src"
dest="$1/rockchip_test/dest"
logfile=$2

log()
{
	echo "$(date +'%Y%m%d_%H.%M.%S') $TAG $@"  | tee -a $logfile
}
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

