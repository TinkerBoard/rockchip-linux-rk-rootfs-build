#!/bin/bash
aplay=/usr/bin/aplay

echo "=== Audio Stress Test ==="

while true
do
	$aplay -D hw:OnBoard,2 /home/linaro/Desktop/Test_tool/BurnIn_test/rockchip_test/src/LR.wav &
	sleep 6
done

echo "========== End =========="

