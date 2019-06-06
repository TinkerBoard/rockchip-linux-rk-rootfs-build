#!/bin/bash

RES_FILE=./log.txt

usage() {
    echo " "
    echo "USAGE: atcmd.sh [options]"
    echo "options:"
    echo "  imsi         :    Check IMSI of SIM card."
    echo "  imei         :    Check IMEI of DUT."
    echo "  cfun <para2> :    Set or query functionality in modem."
    echo " "
}

function Sned_CMD() {
    echo "ATE0Q0V1" > /dev/ttyUSB2
    sleep 0.2
    echo "ATS0=0" > /dev/ttyUSB2
    sleep 0.2

    cat /dev/ttyUSB2 > $RES_FILE &
    pid=$!
    sleep 1

    atCmd="at+$1"
    echo "Cmd = $atCmd"
    echo $atCmd > /dev/ttyUSB2
    sleep 1.5

    kill -9 %1 >/dev/null 2>&1
    sleep 0.5
}

function Res_IMSI() {
    echo "Start read file..."

    while read line; do
        #echo $line
        if [[ $line =~ ^[0-9]+$ ]] || [[ $line == *"ERROR"* ]]; then
            break
        fi
    done < $RES_FILE

    if [[ $line == *"ERROR"* ]]; then
        echo "no SIM: $line"
    elif [[ $line =~ ^[0-9]+$ ]]; then
        echo "SIM IMSI: $line"
    else
        echo "no SIM: others ERROR: $line"
    fi
}

function Res_IMEI() {
    echo "Start read file..."

    while read line; do
        #echo $line
        if [[ $line =~ ^[0-9]+$ ]] || [[ $line == *"ERROR"* ]]; then
            break
        fi
    done < $RES_FILE

    if [[ $line == *"ERROR"* ]]; then
        echo "no IMEI: $line"
    elif [[ $line =~ ^[0-9]+$ ]]; then
        echo "IMEI: $line"
    else
        echo "no IMEI: others ERROR: $line"
    fi
}

function Res_normal() {
    echo "Start read file..."
    while read line; do
        echo $line
    done < $RES_FILE
}


if [ ! -n "$1" ]; then
    usage
    exit 1
else
    option="$1"
fi


if [ "$option" == "imsi" -o "$option" == "IMSI" ]; then
    Sned_CMD "CIMI"
    Res_IMSI
elif [ "$option" == "imei" -o "$option" == "IMEI" ]; then
    Sned_CMD "CGSN"
    Res_IMEI
elif [ "$option" == "cfun" -o "$option" == "CFUN" ]; then
    if [ ! -n "$2" ]; then
        usage
        exit 1
    else
        PARA="$2"
    fi
    Sned_CMD "CFUN=$PARA"
    Res_normal
else
    echo "Cmd = $option . Maybe not support."
    Sned_CMD "$option"
    Res_normal
fi

exit 0
