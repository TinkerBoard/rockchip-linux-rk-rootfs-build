#!/bin/bash

i=0
ERROR=0
ResultFile="/tmp/Capture_TestResult.txt"
CSI0="/dev/video0"
CSI1="/dev/video5"

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
	gst-launch-1.0 v4l2src device=$CSI0 num-buffers=100 ! video/x-raw,format=NV12,width=1280,height=960,framerate=30/1 ! videoconvert ! rkximagesink

	gst-launch-1.0 v4l2src device=$CSI1 num-buffers=100 ! video/x-raw,format=NV12,width=1920,height=1080,framerate=30/1 ! videoconvert ! rkximagesink
}

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
Remove_TestResult

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

echo 60 > /tmp/flicker_mode

echo -e "Start Preview Test!" | tee -a $ResultFile
Preview_Test

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
gst-launch-1.0 v4l2src device=$CSI0 num-buffers=10 ! video/x-raw,format=NV12,width=2592,height=1944 ! jpegenc ! multifilesink location=/tmp/Capture_ov5647.jpg
sleep 2
gst-launch-1.0 v4l2src device=$CSI1 num-buffers=10 ! video/x-raw,format=NV12,width=3280,height=2464 ! jpegenc ! multifilesink location=/tmp/Capture_imx219.jpg

echo -e "Finished Capture Test!" | tee -a $ResultFile
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
