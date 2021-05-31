#!/bin/bash

version=1.6

log()
{
	logfile=$LOG_PATH/BurnIn.txt
	logfile2="/dev/kmsg"
	echo $1 | tee -a $logfile | sudo tee $logfile2
	logger -t BurnIn "$1"
}

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
	echo "7. Network download/upload stress test"
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
	logfile=$LOG_PATH/cpu.txt
	time=2592000 # 30 days = 60 * 60 * 24 * 30
	sudo bash $path/rockchip_test/cpu_freq_stress_test.sh $time 10 $logfile > /dev/null 2>&1 &
}

npu_test()
{
	logfile=$LOG_PATH/npu.txt
	ProcNum=$(ps aux | grep npu_transfer_proxy | grep -v 'grep' | wc -l)
	if [ "$ProcNum" == 0 ]; then
		echo "Start npu_transfer_proxy"
		/usr/bin/npu_transfer_proxy &
	fi
	bash $path/rockchip_test/npu_stress.sh
}

gpu_test()
{
	logfile=$LOG_PATH/gpu.txt
	sudo bash $path/rockchip_test/gpu_stress.sh $source
}

ddr_test()
{
	logfile=$LOG_PATH/ddr.txt
	sudo memtester $1 > $logfile 2>&1 &
}

emmc_stress_test()
{
	logfile=$LOG_PATH/emmc.txt
	sudo bash $path/rockchip_test/emmc_stress_test.sh $path $logfile
}

sd_card_stress_test()
{
	logfile=$LOG_PATH/sd.txt
	sudo bash $path/rockchip_test/sd_card_stress_test.sh $path $logfile
}

network_stress_test()
{
	logfile=$LOG_PATH/network.txt
	sudo bash $path/rockchip_test/network_stress_test.sh $logfile
}

CPU="stressapptest"
NPU="npu_stress.sh"
GPU="glmark2-es2"
DDR="memtester"
EMMC="emmc_stress_test.sh"
SD="sd_card_stress_test.sh"
Network="network_stress_test.sh"

check_status()
{
	Flag=$( ps aux | grep "$2" | grep -v "grep")
	if [ "$Flag" == ""  ]
	then
		log "$1 stress test : stop "
	else
		log "$1 stress test : running "
	fi
}

check_all_status()
{
	check_status CPU $CPU
	check_status NPU $NPU
	check_status GPU $GPU
	check_status DDR $DDR
	check_status EMMC $EMMC
	check_status SD $SD
	check_status Network $Network
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
LOG_PATH=/var/log/burnin_test/$now
high_performance

case $test_item in
	1)
		check_system_status=true
		info_view CPU
		cpu_freq_stress_test
		;;
	2)
		check_system_status=false
		info_view NPU
		npu_test
		pause 'Test stop, press any key to exit...'
		;;
	3)
		check_system_status=true
		info_view GPU
		gpu_test
		;;
	4)
		check_system_status=true
		info_view DDR
		ddr_test 256M
		;;
	5)
		info_view eMMC_RW
		emmc_stress_test
		;;
	6)
		info_view SD_RW
		sd_card_stress_test
		;;
	7)
		info_view Network
		network_stress_test
		;;
	*)
		check_system_status=true
		logfile="$path/$now"_BurnIn.txt
		info_view BurnIn
		cpu_freq_stress_test
		npu_test > /dev/null 2>&1 &
		gpu_test
		ddr_test 128M
		emmc_stress_test > /dev/null 2>&1 &
		sd_card_stress_test > /dev/null 2>&1 &
		network_stress_test > /dev/null 2>&1 &
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

	log ""
	log "============================================"
	log "$(date)"
	log "CPU Usage		= $cpu_usage"
	log "GPU Usage		= $gpu_usage"
	log "CPU temp		= $cpu_temp"
	log "GPU temp		= $gpu_temp"
	log "CPU big core freq	= $cur_freq4 GHz"
	log "CPU small core freq	= $cur_freq0 GHz"
	log "GPU freq		= $gpu_freq MHz"
	log "DDR freq		= $ddr_freq MHz"
	log ""
	log "Test Status"
	check_all_status
	log "============================================"
	log ""
	sleep 6
done
