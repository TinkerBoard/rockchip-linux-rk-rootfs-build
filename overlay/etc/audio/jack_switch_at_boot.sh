#!/bin/bash

board_info=`cat /proc/board_info`
if [ "${board_info}" != "Tinker Board S" ] && [ "${board_info}" != "Tinker R/BR" ]; then
	exit 0
fi

gpio=`cat /sys/class/gpio/gpio220/value`
echo "gpio=${gpio}";

sleep 5
if [ ${gpio} == "1" ]; then
	echo "audio jack plug out at boot";
	/bin/bash /etc/audio/jack_auto_switch.sh "out"
fi

if [ ${gpio} == "0" ]; then
	echo "audio jack plug in at boot";
	/bin/bash /etc/audio/jack_auto_switch.sh "in"
fi
