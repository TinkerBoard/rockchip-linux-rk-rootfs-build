#! /bin/sh
# /etc/profile.d/display.sh
#

HDMI_HOTPLUG_CONFIG="/boot/display/hdmi/hdmi_plug_flag.cfg"
DP_HOTPLUG_CONFIG="/boot/display/dp/dp_plug_flag.cfg"

if [ ! -d /boot/display ]; then
    mkdir /boot/display
	if [ ! -d /boot/display/hdmi ]; then
		mkdir /boot/display/hdmi
	fi

	if [ ! -d /boot/display/dp ]; then
		mkdir /boot/display/dp
	fi
fi

if [ -f $HDMI_HOTPLUG_CONFIG ]; then
	rm -rf $HDMI_HOTPLUG_CONFIG
fi

if [ -f $DP_HOTPLUG_CONFIG ]; then
	rm -rf $DP_HOTPLUG_CONFIG
fi

touch $HDMI_HOTPLUG_CONFIG
touch $DP_HOTPLUG_CONFIG


