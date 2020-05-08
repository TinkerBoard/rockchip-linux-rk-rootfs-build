#!/bin/bash

i=0
ERROR=0
ResultFile="/tmp/Capture_TestResult.txt"
CSI0="/dev/video0"
CSI1="/dev/video5"
output="/tmp"

function Remove_TestResult()
{
    if [ -f $ResultFile ]; then
		echo "$ResultFile EXIST, Revmove $ResultFile!"
		rm -rf $ResultFile
	fi
	
	rm -rf /tmp//*.jpg
}

function END()
{
    exit $ERROR
}

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
Remove_TestResult

if [ ! -n "$1" ];then
	echo -e "Set to default capture 3000 shots" | tee -a $ResultFile
	count=$((3000))
else
	echo -e "Set to capture $1 shots" | tee -a $ResultFile
	count=$(($1))
fi

echo -e "Start Capture Stress Test!" | tee -a $ResultFile
echo 60 > /tmp/flicker_mode
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[fmt:SBGGR8_1X8/2592x1944]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[crop:(0,0)/2592x1944]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[fmt:YUYV8_2X8/2592x1944]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[crop:(0,0)/2592x1944]'
media-ctl -d /dev/media0 --set-v4l2 '"m00_b_ov5647 1-0036":0[fmt:SBGGR8_1X8/2592x1944]'
v4l2-ctl -d /dev/video0 --set-fmt-video=width=2592,height=1944,pixelformat=NV12 --set-crop=top=0,left=0,width=2592,height=1944

media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":0[fmt:SRGGB10_1X10/3280x2464]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":0[crop:(0,0)/3280x2464]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":2[fmt:YUYV8_2X8/3280x2464]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":2[crop:(0,0)/3280x2464]'
media-ctl -d /dev/media1 --set-v4l2 '"m00_b_imx219 2-0010":0[fmt:SRGGB10_1X10/3280x2464]'
v4l2-ctl -d /dev/video5 --set-fmt-video=width=3280,height=2464,pixelformat=NV12 --set-crop=top=0,left=0,width=3280,height=2464

echo -e "Start Capture Test!" | tee -a $ResultFile
while [ $i != $count ]; do
    i=$(($i+1))

	gst-launch-1.0 v4l2src device=$CSI0 num-buffers=10 ! video/x-raw,format=NV12,width=2592,height=1944 ! jpegenc ! multifilesink location=$output/ov5647_$i.jpg &
	sleep 4
	
	gst-launch-1.0 v4l2src device=$CSI1 num-buffers=10 ! video/x-raw,format=NV12,width=3280,height=2464 ! jpegenc ! multifilesink location=$output/imx219_$i.jpg &
	sleep 4
	
	echo -e "$(date): Camera capture $i time(s)" | tee -a $ResultFile
			
done
echo -e "Finished Capture Test!" | tee -a $ResultFile
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
