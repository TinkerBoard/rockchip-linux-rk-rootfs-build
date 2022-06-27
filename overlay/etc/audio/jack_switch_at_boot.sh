#!/bin/bash

projectid=`cat /proc/projectid`
boardid=`cat /proc/boardid`
echo project=${projectid};
echo boardid=${boardid};

sound_ext_card_name=`sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd list-cards | grep -A 10 alsa_card.platform-sound-ext-card | grep alsa.card_name`
sound_ext_alsa_card_name=$(echo $sound_ext_card_name | cut -d" " -f 3)
sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-sink-proplist alsa_output.platform-sound-ext-card.stereo-fallback device.description=$sound_ext_alsa_card_name

if [ "${projectid}" == "7" ]; then
	if [ "${boardid}" == "0" ]; then
		exit 0
	elif [ "${boardid}" == "1" ]; then
		exit 0
	elif [ "${boardid}" == "2" ]; then
		exit 0
	fi
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
