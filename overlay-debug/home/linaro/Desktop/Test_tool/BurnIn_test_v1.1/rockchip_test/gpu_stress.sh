#!/bin/sh

echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo "performance" > /sys/devices/system/cpu/cpu5/cpufreq/scaling_governor

if [ $1 == "win" ]; then
	#stop lightdm which uses xserver
	systemctl stop lightdm

	#assign display
	export DISPLAY=:0

	#start xserver
	Xorg -novtswitch > /dev/null 2>&1 &
	sleep 5
fi

#run glmark2-es2, benchmark - refract
for i in {1..6};
do
    glmark2-es2 --benchmark refract --run-forever > /dev/null &
    sleep 1
done