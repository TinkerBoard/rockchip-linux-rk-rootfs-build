#!/bin/bash

path=$(pwd)
path="$path/npu_test.py"
#echo "npu_test : $path"

ProcNum=$(ps aux | grep npu_transfer_proxy | grep -v 'grep' | wc -l)
if [ "$ProcNum" == 0 ]; then
    echo "Start npu_transfer_proxy"
    /usr/bin/npu_transfer_proxy &
fi

python3 $path
