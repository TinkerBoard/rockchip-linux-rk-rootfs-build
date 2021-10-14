#!/bin/bash

source /etc/audio/audio.conf
echo "Auto switch audio output path : ${auto_switch_audio_output_path}"
echo "Default audio output path : ${default_audio_output_path}"

if [ "$1" == "in" ] || [ "$1" == "boot-in" ]; then
	echo "Audio Jack Plug In"
	amixer -c rockchiprk809 cset numid=1 6
	amixer -c rockchiprk809 cset numid=2 2
	sleep 0.5
	if [ "${auto_switch_audio_output_path}" == "on" ]; then
		if [ "$1" == "boot-in" ]; then
			sleep 4
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-sink-proplist alsa_output.platform-hdmi-dp-sound.stereo-fallback device.description="HDMI_DP-Sound-Output"
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-sink-proplist alsa_output.platform-rk809-sound.stereo-fallback device.description="Headset-Sound-Output"
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-sink-proplist alsa_output.platform-spdif-sound.stereo-fallback device.description="SPDIF-Sound-Output"
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-source-proplist alsa_input.platform-rk809-sound.stereo-fallback device.description="Headset-Sound-Input"
			sound_ext_card_name=`sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd list-cards | grep -A 10 alsa_card.platform-sound-ext-card | grep alsa.card_name`
			sound_ext_alsa_card_name=$(echo $sound_ext_card_name | cut -d" " -f 3)
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-sink-proplist alsa_output.platform-sound-ext-card.stereo-fallback device.description=$sound_ext_alsa_card_name
		fi
		echo "Switch audio output path : alsa_output.platform-rk809-sound.stereo-fallback (Headset)"
		sudo -u linaro DISPLAY=:0.0 notify-send -t 3000 "Audio Jack Plug-In"
		sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd set-default-sink alsa_output.platform-rk809-sound.stereo-fallback
		sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd list-sink-inputs | grep index | while read line
		do
		sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd move-sink-input `echo $line | cut -f2 -d' '` "alsa_output.platform-rk809-sound.stereo-fallback"
		done
	fi
fi

if [ "$1" == "out" ] || [ "$1" == "boot-out" ]; then
	echo "Audio Jack Plug Out"
	amixer -c rockchiprk809 cset numid=1 0
	amixer -c rockchiprk809 cset numid=2 0
	sleep 0.5
	if [ "${auto_switch_audio_output_path}" == "on" ]; then
		if [ "$1" == "boot-out" ]; then
			sleep 4
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-sink-proplist alsa_output.platform-hdmi-dp-sound.stereo-fallback device.description="HDMI_DP-Sound-Output"
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-sink-proplist alsa_output.platform-rk809-sound.stereo-fallback device.description="Headset-Sound-Output"
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-sink-proplist alsa_output.platform-spdif-sound.stereo-fallback device.description="SPDIF-Sound-Output"
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-source-proplist alsa_input.platform-rk809-sound.stereo-fallback device.description="Headset-Sound-Input"
			sound_ext_card_name=`sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd list-cards | grep -A 10 alsa_card.platform-sound-ext-card | grep alsa.card_name`
			sound_ext_alsa_card_name=$(echo $sound_ext_card_name | cut -d" " -f 3)
			sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd update-sink-proplist alsa_output.platform-sound-ext-card.stereo-fallback device.description=$sound_ext_alsa_card_name
		fi
		echo "Switch audio output path : ${default_audio_output_path} (Default)"
		sudo -u linaro DISPLAY=:0.0 notify-send -t 3000 "Audio Jack Plug-Out"
		sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd set-default-sink ${default_audio_output_path}
		sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd list-sink-inputs | grep index | while read line
		do
		sudo -u linaro PULSE_RUNTIME_PATH=/run/user/1000/pulse pacmd move-sink-input `echo $line | cut -f2 -d' '` ${default_audio_output_path}
		done
	fi
fi
