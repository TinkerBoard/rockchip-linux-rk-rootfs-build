#!/bin/bash -e

if [ ! $VERSION ]; then
	VERSION="debug"
fi

if [ ! $PACKAGE ]; then
	PACKAGE='debian'
fi

TARGET_ROOTFS_DIR="binary"
TARGET_LOCAL_PACKAGE_DIR="local_packages-$VERSION/$PACKAGE"

if [ -e $TARGET_ROOTFS_DIR ]; then
	echo "Found the directory $TARGET_ROOTFS_DIR. Remove it now."
	sudo rm -rf $TARGET_ROOTFS_DIR
fi

if [ -e $TARGET_LOCAL_PACKAGE_DIR ]; then
	echo "Found the directory $TARGET_LOCAL_PACKAGE_DIR. Remove it now."
	sudo rm -rf $TARGET_LOCAL_PACKAGE_DIR
fi

VERSION=$VERSION PACKAGE=$PACKAGE ARCH=$ARCH ./mk-rootfs-stretch.sh

if [ "$PACKAGE" == "debian" ]; then
	mkdir -p $TARGET_LOCAL_PACKAGE_DIR
	cp -rf $TARGET_ROOTFS_DIR/var/cache/apt/archives/*.deb $TARGET_LOCAL_PACKAGE_DIR
fi

if [ "$PACKAGE" == "python" ]; then
        mkdir -p $TARGET_LOCAL_PACKAGE_DIR
        cp -rf $TARGET_ROOTFS_DIR/var/cache/python/*.whl $TARGET_LOCAL_PACKAGE_DIR
fi
