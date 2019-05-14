#!/bin/bash -e

TARGET_ROOTFS_DIR="binary"
TARGET_LOCAL_PACKAGE_DIR="local_packages"

if [ -e $TARGET_ROOTFS_DIR ]; then
    echo "Found the directory $TARGET_ROOTFS_DIR. Remove it now."
    sudo rm -rf $TARGET_ROOTFS_DIR
fi
if [ -e $TARGET_LOCAL_PACKAGE_DIR ]; then
    echo "Found the directory $TARGET_LOCAL_PACKAGE_DIR. Remove it now."
    sudo rm -rf $TARGET_LOCAL_PACKAGE_DIR
fi

PACKAGE=update ./mk-rootfs-stretch-arm64.sh

mkdir -p $TARGET_LOCAL_PACKAGE_DIR
cp -rf $TARGET_ROOTFS_DIR/var/cache/apt/archives/*.deb $TARGET_LOCAL_PACKAGE_DIR
