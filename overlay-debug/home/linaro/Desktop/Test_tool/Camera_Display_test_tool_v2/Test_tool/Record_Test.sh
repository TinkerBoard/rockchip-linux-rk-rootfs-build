#!/bin/bash

i=0
ERROR=0
ResultFile="/tmp/Record_TestResult.txt"
CSI0="/dev/video0"
CSI1="/dev/video5"

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
time=2
echo 60 > /tmp/flicker_mode
echo -e "Start Record Test!" | tee -a $ResultFile

media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[fmt:SBGGR8_1X8/1296x972]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[crop:(0,0)/1296x972]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[fmt:YUYV8_2X8/1296x972]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[crop:(0,0)/1296x972]'
media-ctl -d /dev/media0 --set-v4l2 '"m00_b_ov5647 1-0036":0[fmt:SBGGR8_1X8/1296x972]'
v4l2-ctl -d /dev/video0 --set-fmt-video=width=1296,height=972,pixelformat=NV12 --set-crop=top=0,left=0,width=1296,height=972

gst-launch-1.0 v4l2src device=$CSI0 ! video/x-raw,width=640,height=480,framerate=30/1 ! tee name=t t. ! queue ! rkximagesink sync=false t. ! queue ! mpph264enc ! queue ! h264parse ! mpegtsmux ! filesink location=/tmp/Record_OV5647_480p.ts &
var=$!
sleep 60
kill -9 $var
echo -e "$(date): Camera record Record_ov5647_480p.ts" | tee -a $ResultFile

gst-launch-1.0 v4l2src device=$CSI0 ! video/x-raw,width=1280,height=720,framerate=30/1 ! tee name=t t. ! queue ! rkximagesink sync=false t. ! queue ! mpph264enc ! queue ! h264parse ! mpegtsmux ! filesink location=/tmp/Record_OV5647_720p.ts &
var=$!
sleep 60
kill -9 $var
echo -e "$(date): Camera record Record_ov5647_720p.ts" | tee -a $ResultFile

media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[fmt:SBGGR8_1X8/2592x1944]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[crop:(0,0)/2592x1944]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[fmt:YUYV8_2X8/2592x1944]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[crop:(0,0)/2592x1944]'
media-ctl -d /dev/media0 --set-v4l2 '"m00_b_ov5647 1-0036":0[fmt:SBGGR8_1X8/2592x1944]'
v4l2-ctl -d /dev/video0 --set-fmt-video=width=2592,height=1944,pixelformat=NV12 --set-crop=top=0,left=0,width=2592,height=1944

gst-launch-1.0 v4l2src device=$CSI0 ! video/x-raw,width=1920,height=1088 ! tee name=t t. ! queue ! rkximagesink sync=false t. ! queue ! mpph264enc ! queue ! h264parse ! mpegtsmux ! filesink location=/tmp/Record_OV5647_1080p.ts &
var=$!
sleep 60
kill -9 $var
echo -e "$(date): Camera record Record_ov5647_1080p.ts" | tee -a $ResultFile

media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":0[fmt:SRGGB10_1X10/1920x1080]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":0[crop:(0,0)/1920x1080]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":2[fmt:YUYV8_2X8/1920x1080]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":2[crop:(0,0)/1920x1080]'
media-ctl -d /dev/media1 --set-v4l2 '"m00_b_imx219 2-0010":0[fmt:SRGGB10_1X10/1920x1080]'
v4l2-ctl -d /dev/video5 --set-fmt-video=width=1920,height=1080,pixelformat=NV12 --set-crop=top=0,left=0,width=1920,height=1080

gst-launch-1.0 v4l2src device=$CSI1 ! video/x-raw,width=640,height=480,framerate=30/1 ! tee name=t t. ! queue ! rkximagesink sync=false t. ! queue ! mpph264enc ! queue ! h264parse ! mpegtsmux ! filesink location=/tmp/Record_IMX219_480p.ts &
var=$!
sleep 60
kill -9 $var
echo -e "$(date): Camera record Record_IMX219_480p.ts" | tee -a $ResultFile

gst-launch-1.0 v4l2src device=$CSI1 ! video/x-raw,width=1280,height=720,framerate=30/1 ! tee name=t t. ! queue ! rkximagesink sync=false t. ! queue ! mpph264enc ! queue ! h264parse ! mpegtsmux ! filesink location=/tmp/Record_IMX219_720p.ts &
var=$!
sleep 60
kill -9 $var
echo -e "$(date): Camera record Record_IMX219_720p.ts" | tee -a $ResultFile

media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":0[fmt:SRGGB10_1X10/3280x2464]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":0[crop:(0,0)/3280x2464]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":2[fmt:YUYV8_2X8/3280x2464]'
media-ctl -d /dev/media1 --set-v4l2 '"rkisp1-isp-subdev":2[crop:(0,0)/3280x2464]'
media-ctl -d /dev/media1 --set-v4l2 '"m00_b_imx219 2-0010":0[fmt:SRGGB10_1X10/3280x2464]'
v4l2-ctl -d /dev/video5 --set-fmt-video=width=3280,height=2464,pixelformat=NV12 --set-crop=top=0,left=0,width=3280,height=2464

gst-launch-1.0 v4l2src device=$CSI1 ! video/x-raw,width=1920,height=1088 ! tee name=t t. ! queue ! rkximagesink sync=false t. ! queue ! mpph264enc ! queue ! h264parse ! mpegtsmux ! filesink location=/tmp/Record_IMX219_1080p.ts &
var=$!
sleep 60
kill -9 $var
echo -e "$(date): Camera record Record_IMX219_1080p.ts" | tee -a $ResultFile

echo -e "Finished Record Test!" | tee -a $ResultFile
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
