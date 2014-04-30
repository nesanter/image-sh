#!/bin/bash

cd scripts
SCRIPT_DIR=$(pwd)

checkerr ()
{
	if [ $? -ne 0 ] ; then
		echo "Error: cannot continue"
		ERROR=1
		exit 1
	fi
}

cleanup ()
{
	cd $SCRIPT_DIR
	cd $BASE_DIR
	
	if [ -n "$(mount | grep -o $IMAGE)" ] ; then
		#umount -v $IMAGE_DIR
		echo "umount" > $SCRIPT_DIR/tmp/supipei
		read code < $SCRIPT_DIR/tmp/supipeo
	fi
	if [ $IMAGE_DIR -a -e $IMAGE_DIR ] ; then
		rmdir -v $IMAGE_DIR
	fi
	if [ -n "$MAINSU_PID" ] ; then
		echo "exit" > $SCRIPT_DIR/tmp/supipei
		wait $MAINSU_PID
	fi
	if [ -e $SCRIPT_DIR/tmp/supipei ] ; then
		rm -v $SCRIPT_DIR/tmp/supipe*
	fi
	
	if [ $ERROR ] ; then
		if [ -e $IMAGE ] ; then
			if [ "$SAVE" == "yes" ] ; then
				mv -v $IMAGE $IMAGE.fail
				echo "Failed image $IMAGE.fail is in $BASE_DIR"
			else
				rm -v $IMAGE
			fi
			echo "--- FAILED ---"
		fi
	else
		if [ $DONE ] ; then
			echo "Final image $IMAGE is in $BASE_DIR"
			echo "--- DONE ---"
		else
			if [ "$SAVE" == "yes" ] ; then
				echo "Incomplete image $IMAGE is in $BASE_DIR"
			else
				echo "Removing incomplete image"
				rm -v $IMAGE
			fi
		fi
	fi
}

trap "cleanup ; exit" EXIT

## Main build script

echo "--- OS MAKER ---"

mkfifo tmp/supipei tmp/supipeo
checkerr

echo "Acquiring root permissions:"
su -c "./main-su.sh tmp/supipe&"
checkerr
MAINSU_PID=$!

mkdir -pv $BASE_DIR
checkerr

if [ ! $PV ] ; then
	PV=$(command -v pv)
fi

KBYTES=$(($IMAGE_SIZE * 1000))
BYTES=$(($KBYTES * 1000))

cd $BASE_DIR

if [ -e $IMAGE ] ; then
	echo "Old image found, attempting to resume"
	OLDIMAGE=1
else
	if [ $(df . | tail -n 1 | awk '{print $4}') -lt $KBYTES ] ; then
		echo "Not enough space for image"
		ERROR=1
		exit 1
	fi
	
	if [ $PV ] ; then
		dd if=/dev/zero bs=1000000 count=$IMAGE_SIZE | pv -s $BYTES | dd of=$IMAGE
	else
		dd if=/dev/zero bs=1000000 count=$IMAGE_SIZE of=$IMAGE
	fi
	checkerr
	
	mkfs -t $FS_TYPE $FS_OPTS $IMAGE
	checkerr
fi

IMAGE_DIR=$(sed 's/[\.][a-zA-Z0-9.]*$//' <<< $IMAGE)
mkdir -v $IMAGE_DIR
checkerr

echo "mount" > $SCRIPT_DIR/tmp/supipei
read code < $SCRIPT_DIR/tmp/supipeo
if [ $code -ne 0 ] ; then
	MAINSU_PID=
	false
	checkerr
fi

cd $IMAGE_DIR

if [ -f .resume ] ; then
	echo "Resume file found"
else
	mkdir -v tools
	if [ -z "$SRC_DIR" ] ; then
		mkdir -v sources
	else
		mkdir -pv $SRC_DIR
	fi
	checkerr
fi

echo "ln-tools" > $SCRIPT_DIR/tmp/supipei
read code < $SCRIPT_DIR/tmp/supipeo
if [ $code -ne 0 ] ; then
	MAINSU_PID=
	false
	checkerr
fi

set +h
umask 022

##Install tools

if [ -z $MINKERNEL ] ; then
	MINKERNEL=$(awk '/^linux-headers-tools\.pkg/ {print $2}' $SCRIPT_DIR/pkgs/versions)
fi

export ROOT=$(pwd)
if [ -z "$SRC_DIR" ] ; then
	SOURCES=$(pwd)/sources
else
	SOURCES=$SRC_DIR
fi
export SOURCES
export TGT=$ARCH-alt-linux-gnu
export LC_ALL=POSIX
export PATH=/tools/bin:/bin:/usr/bin

if [ ! -f .resume ] ; then
	if [ $OLDIMAGE ] ; then
		echo "Oops: old image found without resume information"
		ERROR=1
		exit 1
	fi
	cat $SCRIPT_DIR/pkgs/tools/manifest > .resume
fi
MANIFEST=$(pwd)/.resume

awk '($0 !~ /^#/) {print;}' $MANIFEST | while read PKG ; do
	echo "Parsing package $PKG"
	case $(sed 's/.*\.\([^\.]*\)$/\1/' <<< $PKG) in
		pkg)
			unset PKGVER
			if [ $VERSIONFILE ] ; then
				PKGVER=$(awk '/^'$PKG'/ {print $2}' $VERSIONFILE)
			fi
			if [ ! $PKGVER ] ; then
				PKGVER=$(awk '/^'$PKG'/ {print $2}' $SCRIPT_DIR/pkgs/versions)
			fi
			
			. $SCRIPT_DIR/pkg.sh $SCRIPT_DIR/pkgs/tools/$PKG
			if [ "$ERROR" == "1" ] ; then
				exit 1
			fi
			;;
		sh)
			. $SCRIPT_DIR/pkgs/tools/$PKG
			if [ "$ERROR" == "1" ] ; then
				exit 1
			fi
			;;
	esac
	sed -i '/^'$PKG'$/d' $MANIFEST
done

if [ -e $SCRIPT_DIR/tmp/error ] ; then
	ERROR = 1
fi

if [ "$ERROR" == "1" ] ; then
	exit 1
fi

echo "Installation of host tools is complete"

##Final details

cd $BASE_DIR

if [ -e $IMAGE_DIR/usr/pkg/manifest ] ; then
	echo "Finalization appears to have already run"
	echo "If this is incorrect remove /usr/pkg/manifest"
	echo "from the image."
else
	mkdir -pv $IMAGE_DIR/{dev,proc,sys}
	echo "mknod" > $SCRIPT_DIR/tmp/supipei
	read code < $SCRIPT_DIR/tmp/supipeo
	
	cd $IMAGE_DIR
	
	mkdir -p {bin,boot,etc/{opt,sysconfig},home,lib,mnt,run,opt}
	mkdir -p {media/{floppy,cdrom},sbin,srv,var}
	mkdir -p usr/{,local/}{bin,include,lib,sbin,src,pkg{,/scripts}}
	mkdir -p usr/{,local/}share/{doc,info,locale,man,i18n}
	mkdir -p usr/{,local/}share/{misc,terminfo,zoneinfo}
	mkdir -p usr/{,local/}share/man/man{1..8}
	mkdir -p var/{log,mail,spool}
	mkdir -p var/{opt,cache,lib/{misc,locale},local}
	
	echo "root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false" > etc/passwd
	
	echo "root:x:0:root
bin:x:1:root
utmp:x:2:
install:x:3:root" > etc/group
	
	touch var/log/{btmp,lastlog,wtmp}
	touch usr/pkg/manifest
	echo "1000" > usr/pkg/pkgid
	echo $DL_DIR > usr/pkg/bind-dl
	cp -r $SCRIPT_DIR/util/skel usr/pkg
	
	cp $SCRIPT_DIR/finalizer.sh /tools/finalizer.sh
	cp $SCRIPT_DIR/util/upkg.sh bin/upkg
	cp $SCRIPT_DIR/util/upkg-install.sh bin/upkg-install
	cp $SCRIPT_DIR/util/upkg-rm.sh bin/upkg-rm
	cp $SCRIPT_DIR/util/upkg-ldconfig-helper.sh bin/upkg-ldconfig-helper
	
	echo "final" > $SCRIPT_DIR/tmp/supipei
	read code < $SCRIPT_DIR/tmp/supipeo

	echo "Initial setup complete"
fi

##Done!

DONE=1