#!/bin/bash

function pause(){
	read -n 1 -p "$*" INP
	if [ $INP != '' ] ; then
		echo -ne '\b \n'
	fi
}

sudo apt-get update
sudo apt-get install cmake gcc g++ libprotobuf-dev protobuf-compiler
sudo apt-get install liblapack-dev libjpeg-dev zlib1g-dev
sudo apt-get install python3-dev python3-pip python3-scipy
pip3 install --upgrade pip
pip3 install wheel setuptools
sudo apt-get build-dep python3-h5py
pip3 install h5py
wget https://github.com/rockchip-linux/rknn-toolkit/releases/download/v1.3.2/rknn-toolkit-v1.3.2-packages.zip
unzip ./rknn-toolkit-v1.3.2-packages.zip
pip3 install ./packages/required-packages-for-arm64-debian9-python35/tensorflow-1.11.0-cp35-none-linux_aarch64.whl --user
pip3 install ./packages/required-packages-for-arm64-debian9-python35/opencv_python_headless-4.0.1.23-cp35-cp35m-linux_aarch64.whl
pip3 install ./packages/rknn_toolkit-1.3.2-cp35-cp35m-linux_aarch64.whl --user

pause 'Press any key to continue...'
