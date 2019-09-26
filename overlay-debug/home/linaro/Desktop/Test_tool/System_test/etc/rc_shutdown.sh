#!/bin/bash

echo "Stress Test of Shutdown."

times=$(grep -r "shutdown_times" /etc/shutdown_times.txt | awk '{print $3}')

cat /etc/debian_version | grep "9.9"
if [ "$?" == "0" ]; then
	echo "Debian Version 9.9."
	echo "########## Shutdown device from test_shutdown.sh ##########"
	((times+=1))
	echo "shutdown_times = "$times > /etc/shutdown_times.txt
	echo +20 > /sys/class/rtc/rtc0/wakealarm
	systemctl poweroff
else
	echo "Detect wrong debian version."
	echo "########## Stop shutdown test ##########"
	((times+=1))
	echo "Detect wrong debian version." >> /etc/shutdown_times.txt
	echo "Shutdown fail in the "$times" time." >> /etc/shutdown_times.txt
fi
