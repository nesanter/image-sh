#!/bin/bash


#do not run directly!

SCRIPT_DIR=$(pwd)
IMAGE_DIR=$(echo $IMAGE | sed 's/[\.][a-zA-Z0-9.]*$//')

cd $BASE_DIR

while true ; do
	read cmd < $SCRIPT_DIR/tmp/supipei
	case $cmd in
		exit)
			if [ -h /tools ] ; then
				rm -v /tools
			fi
			exit
			;;
		mount)
			if [ $MOUNT_OPTS ] ; then
				(mount -v -o loop,$MOUNT_OPTS $IMAGE $IMAGE_DIR && chown $(stat -c %u:%g $IMAGE) $IMAGE_DIR && echo "0" > $SCRIPT_DIR/tmp/supipeo) || (echo "1" > $SCRIPT_DIR/tmp/supipeo ; exit)
			else
				(mount -v -o loop $IMAGE $IMAGE_DIR && chown $(stat -c %u:%g $IMAGE) $IMAGE_DIR && echo "0" > $SCRIPT_DIR/tmp/supipeo) || (echo "1" > $SCRIPT_DIR/tmp/supipeo ; exit)
			fi
			;;
		umount)
			(umount -v $IMAGE_DIR && echo "0" > $SCRIPT_DIR/tmp/supipeo) || (echo "1" > $SCRIPT_DIR/tmp/supipeo ; exit)
			;;
		ln-tools)
			(ln -sv $(pwd)/$IMAGE_DIR/tools / && echo "0" > $SCRIPT_DIR/tmp/supipeo) || (echo "1" > $SCRIPT_DIR/tmp/supipeo ; exit)
			;;
		mknod)
			mknod -m 600 $IMAGE_DIR/dev/console c 5 1
			mknod -m 666 $IMAGE_DIR/dev/null c 1 3
			echo "0" > $SCRIPT_DIR/tmp/supipeo
			;;
		final)
			chown -R root:root $IMAGE_DIR/*
			chroot "$IMAGE_DIR" /tools/bin/env -i \
				HOME=/root \
				PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
				/tools/bin/bash /tools/finalizer.sh
			
			rm /tools/finalizer.sh
			
			echo "0" > $SCRIPT_DIR/tmp/supipeo
			;;
		mount-vkfs)
			mount -v --bind /dev $IMAGE_DIR/dev
			mount -vt devpts devpts $IMAGE_DIR/dev/pts -o gid=5,mode=620
			mount -vt proc proc $IMAGE_DIR/proc
			mount -vt sysfs sysfs $IMAGE_DIR/sys
			
			if [ -h $IMAGE_DIR/dev/shm ] ; then
				(link=$(readlink $IMAGE_DIR/dev/shm) && \
				mkdir -pv $IMAGE_DIR/$link && \
				mount -vt tmpfs shm $IMAGE_DIR/$link && \
				unset link && \
				echo "0" > $SCRIPT_DIR/tmp/supipeo) || \
				(echo "1" > $SCRIPT_DIR/tmp/supipeo ; exit)
			else
				(mount -vt tmpfs shm $IMAGE_DIR/dev/shm && \
				echo "0" > $SCRIPT_DIR/tmp/supipeo) || \
				(echo "1" > $SCRIPT_DIR/tmp/supipeo ; exit)
			fi
			;;
		umount-vkfs)
			umount $IMAGE_DIR/dev/shm
			umount $IMAGE_DIR/dev/pts
			umount $IMAGE_DIR/dev
			umount $IMAGE_DIR/proc
			umount $IMAGE_DIR/sys
			echo "0" > $SCRIPT_DIR/tmp/supipeo
			;;
		chroot)
			chroot "$IMAGE_DIR" /tools/bin/env -i \
				HOME=/root \
				PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
				/tools/bin/ash /tools/installer.sh
			if [ $? -ne 0 ] ; then
				echo "1" > $SCRIPT_DIR/tmp/supipeo
				exit
			else
				echo "0" > $SCRIPT_DIR/tmp/supipeo
			fi
			;;
		*)
			echo "Unknown command passed to main-su.sh"
			;;
	esac
done