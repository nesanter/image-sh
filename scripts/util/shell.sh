#!/bin/bash

## Open a shell inside an image
## Run as root

if [ $# -eq 0 ] ; then
	echo "Syntax: shell image"
	exit
fi

if [ $UID -ne 0 ] ; then
	echo "Must be run as root"
	exit 1
fi

if [ ! -e $1 ] ; then
	echo "Image not found"
	exit 1
fi

IMAGE_DIR=$(basename $1 | sed 's/\.[^\.]*//')

if [ -z "$IMAGE_DIR" ] ; then
	echo "Cannot extract directory from $1"
	exit 1
fi

mkdir $IMAGE_DIR || exit 1

if [ "$2" == "-o" ] ; then
	if [ -z "$3" ] ; then
		echo "-o without options"
		exit 1
	fi
	mount -o loop,$3 $1 $IMAGE_DIR || exit 1
	shift 3
else
	mount -o loop $1 $IMAGE_DIR || exit 1
	shift 1
fi

(mount --bind /dev $IMAGE_DIR/dev && \
mount -t devpts devpts $IMAGE_DIR/dev/pts && \
mount -t proc proc $IMAGE_DIR/proc && \
mount -t sysfs sysfs $IMAGE_DIR/sys && \
mount -t tmpfs tmpfs $IMAGE_DIR/tmp) || \
exit 1

if [ -h $IMAGE_DIR/dev/shm ] ; then
	(link=$(readlink $IMAGE_DIR/dev/shm) && \
	mkdir -p $IMAGE_DIR/$link && \
	mount -t tmpfs shm $IMAGE_DIR/$link && \
	unset link) || exit 1
else
	(mount -t tmpfs shm $IMAGE_DIR/dev/shm) || \
	exit 1
fi

if [ -f $IMAGE_DIR/usr/pkg/bind-dl ] ; then
	mkdir -p $IMAGE_DIR/sources
	mount --bind $(cat $IMAGE_DIR/usr/pkg/bind-dl) $IMAGE_DIR/sources
fi

if [ -z "$1" ] ; then
	chroot "$IMAGE_DIR" /tools/bin/env -i \
		HOME=/root \
		PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin:/tools/sbin \
		/tools/bin/bash
else
	chroot "$IMAGE_DIR" /tools/bin/env -i \
		HOME=/root \
		PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin:/tools/sbin \
		/tools/bin/bash $1
fi

if [ -f $IMAGE_DIR/usr/pkg/bind-dl ] ; then
	umount $IMAGE_DIR/sources
fi

umount $IMAGE_DIR/dev/shm
umount $IMAGE_DIR/dev/pts
umount $IMAGE_DIR/dev
umount $IMAGE_DIR/proc
umount $IMAGE_DIR/sys
umount $IMAGE_DIR/tmp

umount $IMAGE_DIR

rmdir $IMAGE_DIR
