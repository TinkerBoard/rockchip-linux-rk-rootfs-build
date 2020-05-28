#!/bin/bash

cd /home/linaro/Desktop/Test_tool/npu_simple_test/rknn_toolkit_v1.3.2_wheels
sudo apt-get update
sudo apt --fix-broken install -y
sudo apt-get upgrade -y
sudo apt-get install -y cmake gcc g++ libprotobuf-dev protobuf-compiler liblapack-dev libjpeg-dev zlib1g-dev python3-dev python3-pip python3-scipy python-pip libfreetype6-dev pkg-config libpng-dev
sudo apt-get build-dep -y python3-h5py
pip3 install --upgrade pip
export PATH=/home/linaro/.local/bin:$PATH
pip3 install enum34 futures --user
pip3 install --no-index --find-links=/home/linaro/Desktop/Test_tool/npu_simple_test/rknn_toolkit_v1.3.2_wheels/ wheel setuptools h5py gluoncv --user
pip3 install --no-index --find-links=/home/linaro/Desktop/Test_tool/npu_simple_test/rknn_toolkit_v1.3.2_wheels/ ./tensorflow-1.11.0-cp35-none-linux_aarch64.whl --user
pip3 install --no-index --find-links=/home/linaro/Desktop/Test_tool/npu_simple_test/rknn_toolkit_v1.3.2_wheels/ ./opencv_python_headless-4.0.1.23-cp35-cp35m-linux_aarch64.whl --user
pip3 install --no-index --find-links=/home/linaro/Desktop/Test_tool/npu_simple_test/rknn_toolkit_v1.3.2_wheels/ ./rknn_toolkit-1.3.2-cp35-cp35m-linux_aarch64.whl --user
