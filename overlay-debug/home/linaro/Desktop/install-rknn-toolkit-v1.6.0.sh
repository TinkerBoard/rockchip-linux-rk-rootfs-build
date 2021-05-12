#!/bin/bash

function pause(){
	read -n 1 -p "$*" INP
	echo -ne '\b \n'
}

sudo apt-get update
sudo apt-get install -y cmake gcc g++ libprotobuf-dev protobuf-compiler
sudo apt-get install -y liblapack-dev libjpeg-dev zlib1g-dev
sudo apt-get install -y python3-dev python3-pip python3-scipy
sudo apt-get build-dep -y python3-h5py
python3 -m pip install --upgrade pip
python3 -m pip install wheel setuptools --user
python3 -m pip install h5py --user
cd /home/linaro/Desktop/rknn_toolkit_v1.6.0
python3 -m pip install --user /home/linaro/Desktop/rknn_toolkit_v1.6.0/tensorflow-2.0.0-cp37-none-linux_aarch64.whl
python3 -m pip install --user /home/linaro/Desktop/rknn_toolkit_v1.6.0/opencv_python-4.3.0.38-cp37-cp37m-linux_aarch64.whl
python3 -m pip install --user /home/linaro/Desktop/rknn_toolkit_v1.6.0/rknn_toolkit-1.6.0-cp37-cp37m-linux_aarch64.whl

pause 'Press any key to continue...'
