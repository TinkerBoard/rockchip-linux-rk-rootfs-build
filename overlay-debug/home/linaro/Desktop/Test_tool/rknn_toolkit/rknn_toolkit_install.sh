#!/bin/bash

sudo apt-get update
pip3 install ./whls/*.whl --user
sudo apt-get build-dep -y python3-h5py
pip3 install h5py --user --no-index --find-links=/home/linaro/Desktop/Test_tool/rknn_toolkit/whls/
pip3 install tensorflow-1.11.0-cp35-none-linux_aarch64.whl --user --no-index --find-links=/home/linaro/Desktop/Test_tool/rknn_toolkit/whls/
pip3 install opencv_python_headless-4.0.1.23-cp35-cp35m-linux_aarch64.whl --user --no-index --find-links=/home/linaro/Desktop/Test_tool/rknn_toolkit/whls/
pip3 install rknn_toolkit-1.0.3b1-cp35-cp35m-linux_aarch64.whl --user --no-index --find-links=/home/linaro/Desktop/Test_tool/rknn_toolkit/whls/
