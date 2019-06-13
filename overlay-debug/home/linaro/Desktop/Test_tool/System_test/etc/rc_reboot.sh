#!/bin/bash

echo "Stress Test of Reboot."

times=$(grep -r "reboot_times" /etc/reboot_times.txt | awk '{print $3}')

cat /etc/debian_version | grep "9.9"
if [ "$?" == "0" ]; then
	echo "Debian Version 9.9."
	echo "########## Reboot device from test_Reboot.sh ##########"
	((times+=1))
	echo "reboot_times = "$times > /etc/reboot_times.txt
	systemctl reboot
else
	echo "Detect wrong debian version."
	echo "########## Stop Reboot test ##########"
	((times+=1))
	echo "Detect wrong debian version." >> /etc/reboot_times.txt
	echo "Reboot fail in the "$times" time." >> /etc/reboot_times.txt
fi
