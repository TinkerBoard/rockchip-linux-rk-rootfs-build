#!/bin/bash

logfile=$1

if ping -c1 -w5 8.8.8.8 >/dev/null 2>&1
then
    echo "Ping responded; Start network test!" | tee -a $logfile
else
    echo "Ping did not respond; " >&2
	echo "Please make sure Wi-Fi connected and device can access internet, then restart test again" | tee -a $logfile
	exit
fi

while [ 1 != 2 ]
do
	curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python - | tee -a $logfile
done

