#!/bin/bash

i=0
ERROR=0
ResultFile="/tmp/Capture_TestResult.txt"
function Remove_TestResult()
{
    if [ -f $ResultFile ]; then
		echo "$ResultFile EXIST, Revmove $ResultFile!"
		rm -rf $ResultFile
	fi
}

function END()
{
    exit $ERROR
}

function Preview_Test()
{
	gst-launch-1.0 v4l2src device=$dev num-buffers=10 ! video/x-raw,format=NV12,width=1920,height=1080, framerate=30/1 ! jpegenc ! multifilesink location=/tmp/ov5647_test.jpg

	gst-launch-1.0 v4l2src device=$dev num-buffers=10 ! video/x-raw,format=NV12,width=1920,height=1080, framerate=30/1 ! jpegenc ! multifilesink location=/tmp/ov5647_test.jpg
	if [ -f "/tmp/ov5647_test.jpg" ]; then
		echo -e "Preview Test Success!" | tee -a $ResultFile
		rm -rf /tmp/ov5647_test.jpg
	else
		echo -e "Cannot find test file, Preview Test Fail!" | tee -a $ResultFile
		#echo -e "Please check camera is already connected to the device." | tee -a $ResultFile
		END
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
	echo -e "Set to default capture time: 12 hr(s)" | tee -a $ResultFile
	time=$((12*360))
elif [ "$2" == "0" ]; then
	echo -e "Take single shot" | tee -a $ResultFile
	time=$((1))
else
	echo -e "Set to default catpture time: $2 hr(s)" | tee -a $ResultFile
	time=$(($2*360))
fi

echo -e "Start Preview Capture Test!" | tee -a $ResultFile
# Preview_Test

echo -e "Start Capture Test!" | tee -a $ResultFile
while [ $i != $time ]; do
    i=$(($i+1))
	#gst-launch-1.0 v4l2src device=$dev num-buffers=10 ! video/x-raw,format=NV12,width=1920,height=1080, framerate=30/1 ! jpegenc ! multifilesink location=/tmp/Capture.jpg &
	gst-launch-1.0 rkv4l2src device=$dev num-buffers=10 ! video/x-raw,format=NV12,width=1920,height=1080, framerate=30/1 ! jpegenc ! multifilesink location=/tmp/Capture_$i.jpg &
	#echo -e "$(date): Camera capture $i time(s)" | tee -a $ResultFile
	sleep 10

done
echo -e "Finished Capture Test!" | tee -a $ResultFile
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
