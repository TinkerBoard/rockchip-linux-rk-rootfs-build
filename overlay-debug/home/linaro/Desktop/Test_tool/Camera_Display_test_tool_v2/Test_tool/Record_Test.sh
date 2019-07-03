#!/bin/bash

i=0
ERROR=0
ResultFile="/tmp/Record_TestResult.txt"
function Remove_TestResult()
{
    if [ -f $ResultFile ]; then
		echo "ResultFile EXIST, Revmove ResultFile!"
		rm -rf $ResultFile
	fi
}

function END()
{
    exit $ERROR
}

function Preview_Test()
{
	gst-launch-1.0 v4l2src device=$dev ! video/x-raw,width=1920,height=1080,framerate=30/1 ! videoconvert ! tee name="splitter" ! queue ! kmssink sync=false splitter. ! queue ! mpph264enc ! avimux ! filesink location=/tmp/test.avi &
	var=$!
	sleep 3
	process=$(ps -A | grep gst-launch-1.0 | awk '{print $1}' | xargs)
	if [ $var == $process ];then
		kill -9 $var
	fi

	gst-launch-1.0 v4l2src device=$dev ! video/x-raw,width=1920,height=1080,framerate=30/1 ! videoconvert ! tee name="splitter" ! queue ! kmssink sync=false splitter. ! queue ! mpph264enc ! avimux ! filesink location=/tmp/test.avi &
	var=$!
	sleep 3
	process=$(ps -A | grep gst-launch-1.0 | awk '{print $1}' | xargs)
	if [ $var == $process ];then
		kill -9 $var
	else
		echo -e "gst-launch-1.0 is not running, Preview Test Fail!" | tee -a $ResultFile
		#echo -e "Please check camera is already connected to the device." | tee -a $ResultFile
		if [ -f "/tmp/test.avi" ]; then
			rm -rf /tmp/test.avi
		fi
		END
	fi

	if [ -f "/tmp/test.avi" ]; then
		echo -e "Preview Test Success!" | tee -a $ResultFile
		rm -rf /tmp/test.avi
	fi
}

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
Remove_TestResult

if [ "$1" == "c0" ];then
	echo -e "Set to use Camera0 OV5647" | tee -a $ResultFile
	dev="/dev/video0"
elif [ "$1" == "c1" ];then
	echo -e "Set to use Camera1 MX219" | tee -a $ResultFile
	dev="/dev/video5"
else
	echo -e "Cannot find camera device, please set camera device!" | tee -a $ResultFile
	echo -e "c0 : OV5647" | tee -a $ResultFile
	echo -e "c1 : MX219" | tee -a $ResultFile
	END
fi


if [ ! -n "$2" ];then
	echo -e "Set to default record time: 12 hr(s)" | tee -a $ResultFile
	time=12
else
	echo -e "Set to default record time: $2 hr(s)" | tee -a $ResultFile
	time=$2
fi

echo -e "Start Preview Record Test!" | tee -a $ResultFile
# Preview_Test

echo -e "Start Record Test!" | tee -a $ResultFile
while [ $i != $time ]; do
	i=$(($i+1))
	#gst-launch-1.0 v4l2src device=$dev ! video/x-raw,width=1920,height=1080,framerate=30/1 ! videoconvert ! tee name="splitter" ! queue ! kmssink sync=false splitter. ! queue ! mpph264enc ! avimux ! filesink location=/tmp/Record.avi &
	gst-launch-1.0 rkv4l2src device=$dev ! video/x-raw,width=1920,height=1080,framerate=30/1 ! videoconvert ! tee name="splitter" ! queue ! kmssink sync=false splitter. ! queue ! mpph264enc ! avimux ! filesink location=/tmp/Record_$i.avi &
	var=$!
	sleep 1h
	kill -9 $var
	#echo -e "$(date): Camera record $i hour(s)" | tee -a $ResultFile
done
echo -e "Finished Record Test!" | tee -a $ResultFile
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
