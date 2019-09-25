#!/bin/bash

version=1.4

select_test_item()
{
	echo "*******************************************"
	echo
	echo                "Burn In Test v_$version"
	echo
	echo "*******************************************"
	echo
	echo "0. (Default) All"
	echo "1. CPU stress test"
	echo "2. NPU stress test"
	echo "3. GPU stress test"
	echo "4. DDR stress test"
	echo "5. eMMC stress test"
	echo "6. SD card stress test"
	echo "7. Wi-Fi download/upload stress test"
	read -p "Select test case: " test_item
}
info_view()
{
	echo "*******************************************"
	echo
	echo "          $1 stress test start"
	echo
	echo "*******************************************"
}

pause(){
        read -n 1 -p "$*" INP
        if [ $INP != '' ] ; then
                echo -ne '\b \n'
        fi
}

high_performance()
{
	sudo bash $path/rockchip_test/high_performance.sh > /dev/null 2>&1
}

cpu_freq_stress_test()
{
	sudo bash $path/rockchip_test/cpu_freq_stress_test.sh 864000 10 > /dev/null 2>&1 &
}

npu_test()
{
	ProcNum=$(ps aux | grep npu_transfer_proxy | grep -v 'grep' | wc -l)
	if [ "$ProcNum" == 0 ]; then
            echo "Start npu_transfer_proxy"
	    sudo /usr/bin/npu_transfer_proxy &
	fi
	bash $path/rockchip_test/npu_stress.sh
}

gpu_test()
{
    sudo bash $path/rockchip_test/gpu_stress.sh $source
}

ddr_test()
{
	sudo memtester 1GB > /dev/null 2>&1 &
}

emmc_stress_test()
{
	sudo bash $path/rockchip_test/emmc_stress_test.sh $path
}

sd_card_stress_test()
{
	sudo bash $path/rockchip_test/sd_card_stress_test.sh $path
}

wifi_stress_test()
{
	sudo bash $path/rockchip_test/wifi_stress_test.sh
}

check_system_status=false

if [ $1 ]; then
	test_item=$1
	path=$2
	source=win
else
	select_test_item
	SCRIPT=`realpath $0`
	path=`dirname $SCRIPT`
	source=linux
	chmod 755 $path/rockchip_test/*.sh
fi

now="$(date +'%Y%m%d_%H%M')"
high_performance

case $test_item in
	1)
		check_system_status=true
		logfile="$path/$now"_cpu.txt
		info_view CPU
		cpu_freq_stress_test
		;;
	2)
		check_system_status=false
		logfile="$path/$now"_npu.txt
		info_view NPU
		npu_test
		pause 'Test stop, press any key to exit...'
		;;
	3)
		check_system_status=true
		logfile="$path/$now"_gpu.txt
		info_view GPU
		gpu_test
		;;
	4)
		check_system_status=true
		logfile="$path/$now"_ddr.txt
		info_view DDR
		ddr_test
		;;
	5)
		logfile="$path/$now"_emmc.txt
		info_view eMMC_RW
		emmc_stress_test | tee -a $logfile
		;;
	6)
		logfile="$path/$now"_sd.txt
		info_view SD_RW
		sd_card_stress_test | tee -a $logfile
		;;
	7)
		logfile="$path/$now"_wifi.txt
		info_view Wi-Fi
		wifi_stress_test | tee -a $logfile
		;;
	*)
		check_system_status=true
		logfile="$path/$now"_BurnIn.txt
		info_view BurnIn
		cpu_freq_stress_test
		npu_test > /dev/null 2>&1 &
		gpu_test
		ddr_test
		emmc_stress_test > /dev/null 2>&1 &
		sd_card_stress_test > /dev/null 2>&1 &
		wifi_stress_test > /dev/null 2>&1 &
		;;
esac

while true; do
	if [ $check_system_status == false ]; then
		exit
	fi
	cpu_usage=$(top -b -n2 | grep "Cpu(s)" | awk '{print $2+$4 "%"}' | tail -n1)
	gpu_usage=$(cat /sys/devices/platform/ff9a0000.gpu/utilisation |awk '{print $1 "%"}')
	temp1=$(cat /sys/class/thermal/thermal_zone0/temp)
	temp2=$(cat /sys/class/thermal/thermal_zone1/temp)
	cpu_temp=$(echo "scale=2; $temp1/1000" | bc)
	gpu_temp=$(echo "scale=2; $temp2/1000" | bc)
	cur_freq0=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`
	cur_freq0=$(echo "scale=2; $cur_freq0/1000000" | bc)
	cur_freq4=`cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq`
	cur_freq4=$(echo "scale=2; $cur_freq4/1000000" | bc)
	gpu_freq=`cat /sys/class/devfreq/ff9a0000.gpu/cur_freq`
	gpu_freq=$(echo "scale=2; $gpu_freq/1000000" | bc)
	ddr_freq=$(sudo cat /sys/kernel/debug/clk/clk_summary | grep sclk_ddrc | awk '{print $4}')
	ddr_freq=$(echo "scale=2; $ddr_freq/1000000" | bc)

	echo | tee -a $logfile
	echo "*******************************************" | tee -a $logfile
	date | tee -a $logfile
	echo "CPU Usage		= $cpu_usage" | tee -a $logfile
	echo "GPU Usage		= $gpu_usage" | tee -a $logfile
	echo "CPU temp		= $cpu_temp" | tee -a $logfile
	echo "GPU temp		= $gpu_temp" | tee -a $logfile
	echo "CPU big core freq	= $cur_freq4 GHz" | tee -a $logfile
	echo "CPU small core freq	= $cur_freq0 GHz" | tee -a $logfile
	echo "GPU freq		= $gpu_freq MHz" | tee -a $logfile
	echo "DDR freq		= $ddr_freq MHz" | tee -a $logfile
	echo "*******************************************" | tee -a $logfile
	echo | tee -a $logfile
	sleep 6
done
