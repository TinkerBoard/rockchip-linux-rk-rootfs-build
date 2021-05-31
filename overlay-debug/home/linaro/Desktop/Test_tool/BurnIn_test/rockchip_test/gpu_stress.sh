#!/bin/sh

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
glmark2-es2 --benchmark refract --run-forever > /dev/null &

for i in {1..2};
do
    glmark2-es2 --benchmark refract --run-forever --off-screen > /dev/null &
    sleep 1
done
