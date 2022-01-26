#!/bin/bash

function pause(){
	read -n 1 -p "$*" INP
	echo -ne '\b \n'
}

sudo apt-get update
sudo apt-get install -y cmake gcc g++ libprotobuf-dev protobuf-compiler
sudo apt-get install -y liblapack-dev libjpeg-dev zlib1g-dev libpng-dev
sudo apt-get install -y python3-dev python3-pip python3-scipy libqt4-dev libqtgui4 libqt4-test
sudo apt-get build-dep -y python3-h5py
sudo dpkg -i /home/linaro/Desktop/debian10_rknn_toolkit_v1.7.1/libpng12-0_1.2.54-1ubuntu1_arm64.deb

python3 -m pip install --upgrade pip
python3 -m pip install --user wheel setuptools
python3 -m pip install --user /home/linaro/Desktop/debian10_rknn_toolkit_v1.7.1/opencv_python-4.4.0.46-cp37-cp37m-linux_aarch64.whl
python3 -m pip install --user /home/linaro/Desktop/debian10_rknn_toolkit_v1.7.1/tensorflow-2.0.0-cp37-none-linux_aarch64.whl
python3 -m pip install --user /home/linaro/Desktop/debian10_rknn_toolkit_v1.7.1/rknn_toolkit-1.7.1-cp37-cp37m-linux_aarch64.whl

pause 'Press any key to continue...'
