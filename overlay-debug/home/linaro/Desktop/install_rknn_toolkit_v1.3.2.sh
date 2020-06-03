#!/bin/bash

sudo apt-get update
sudo apt --fix-broken install -y
sudo apt-get upgrade -y
sudo apt-get install -y cmake gcc g++ libprotobuf-dev protobuf-compiler liblapack-dev libjpeg-dev zlib1g-dev python3-dev python3-pip python3-scipy python-pip libfreetype6-dev pkg-config libpng-dev wget unzip 
sudo apt-get build-dep -y python3-h5py
pip3 install --upgrade pip
export PATH=/home/linaro/.local/bin:$PATH
pip3 install wheel setuptools h5py gluoncv enum34 futures --user
wget https://github.com/rockchip-linux/rknn-toolkit/releases/download/v1.3.2/rknn-toolkit-v1.3.2-packages.zip
unzip ./rknn-toolkit-v1.3.2-packages.zip -d ~/Downloads/rknn-toolkit-v1.3.2-packages/
cd ~/Downloads/rknn-toolkit-v1.3.2-packages/packages/required-packages-for-arm64-debian9-python35
pip3 install ./tensorflow-1.11.0-cp35-none-linux_aarch64.whl --user
pip3 install ./opencv_python_headless-4.0.1.23-cp35-cp35m-linux_aarch64.whl --user
cd ~/Downloads/rknn-toolkit-v1.3.2-packages/packages/
pip3 install ./rknn_toolkit-1.3.2-cp35-cp35m-linux_aarch64.whl --user

