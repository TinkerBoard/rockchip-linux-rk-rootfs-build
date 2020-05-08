#!/bin/bash

i=0
ERROR=0
ResultFile="/tmp/Record_TestResult.txt"
CSI0="/dev/video0"
CSI1="/dev/video5"
output="/home/linaro/Desktop"

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

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
Remove_TestResult

if [ ! -n "$1" ];then
	echo -e "Set to default record time: 12 hr(s)" | tee -a $ResultFile
	time=$[12*1]
else
	echo -e "Set to default record time: $1 hr(s)" | tee -a $ResultFile
	time=$[$1*1]
fi

echo $time

echo 60 > /tmp/flicker_mode
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[fmt:SBGGR8_1X8/1296x972]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[crop:(0,0)/1296x972]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[fmt:YUYV8_2X8/1296x972]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[crop:(0,0)/1296x972]'
media-ctl -d /dev/media0 --set-v4l2 '"m00_b_ov5647 1-0036":0[fmt:SBGGR8_1X8/1296x972]'
v4l2-ctl -d /dev/video0 --set-fmt-video=width=1296,height=972,pixelformat=NV12 --set-crop=top=0,left=0,width=1296,height=972

media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":0[fmt:SRGGB10_1X10/1920x1080]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":0[crop:(0,0)/1920x1080]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":2[fmt:YUYV8_2X8/1920x1080]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":2[crop:(0,0)/1920x1080]'
media-ctl -d /dev/media1 --set-v4l2 '"m00_b_imx219 2-0010":0[fmt:SRGGB10_1X10/1920x1080]'
v4l2-ctl -d /dev/video5 --set-fmt-video=width=1920,height=1080,pixelformat=NV12 --set-crop=top=0,left=0,width=1920,height=1080

echo -e "Start Record Test!" | tee -a $ResultFile
while [ $i != $time ]; do
	i=$(($i+1))
	rm -rf $output/Record_ov5647.avi
	echo -e "$(date): Start record ov5647 $i time(s)" | tee -a $ResultFile
	gst-launch-1.0 v4l2src device=$CSI0 ! video/x-raw,width=640,height=480,framerate=30/1 ! tee name=t t. ! queue ! rkximagesink sync=false t. ! queue ! videorate ! video/x-raw,width=640,height=480,framerate=30/1 ! mpph264enc ! queue ! h264parse ! avimux ! filesink location=$output/Record_ov5647.avi &
	var=$!
	sleep 3600
	kill -9 $var
    echo -e "$(date): Camera record $i time(s)" | tee -a $ResultFile
done

i=0
while [ $i != $time ]; do
    i=$(($i+1))
    rm -rf $output/Record_imx219.avi
	echo -e "$(date): Start record imx219 $i time(s)" | tee -a $ResultFile
    gst-launch-1.0 v4l2src device=$CSI1 ! video/x-raw,width=640,height=480,framerate=30/1 ! tee name=t t. ! queue ! rkximagesink sync=false t. ! queue ! videorate ! video/x-raw,width=640,height=480,framerate=30/1 ! mpph264enc ! queue ! h264parse ! avimux ! filesink location=$output/Record_imx219.avi &
    var=$!
    sleep 3600
    kill -9 $var
    echo -e "$(date): Camera record $i time(s)" | tee -a $ResultFile
done


echo -e "Finished Record Test!" | tee -a $ResultFile
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
