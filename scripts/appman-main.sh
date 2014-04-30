cd scripts
SCRIPT_DIR=$(pwd)
VKFSMOUNTED=0

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
	
	if [ "$VKFSMOUNTED" == "1" ] ; then
		echo "umount-vkfs" > $SCRIPT_DIR/tmp/supipei
		read code < $SCRIPT_DIR/tmp/supipeo
	fi
	if [ -n "$(mount | grep -o $IMAGE)" ] ; then
		#umount -v $IMAGE_DIR
		echo "umount" > $SCRIPT_DIR/tmp/supipei
		read code < $SCRIPT_DIR/tmp/supipeo
	fi
	if [ $IMAGE_DIR -a -e $IMAGE_DIR ] ; then
		rmdir -v $IMAGE_DIR
	fi
	if [ -n $MAINSU_PID ] ; then
		echo "exit" > $SCRIPT_DIR/tmp/supipei
		wait $MAINSU_PID
	fi
	if [ -e $SCRIPT_DIR/tmp/supipei ] ; then
		rm -v $SCRIPT_DIR/tmp/supipe*
	fi
	
	if [ $ERROR ] ; then
		if [ -e $IMAGE ] ; then
			mv -v $IMAGE $IMAGE.fail
			echo "Failed image $IMAGE.fail is in $BASE_DIR"
			echo "--- FAILED ---"
		fi
	else
		echo "Updated image $IMAGE is in $BASE_DIR"
		echo "--- DONE ---"
	fi
}

trap "cleanup ; exit" EXIT

## Target application install script

echo "--- APPMAN ---"

mkfifo tmp/supipei tmp/supipeo
checkerr

echo "Acquiring root permissions:"
su -c "./main-su.sh&"
checkerr
MAINSU_PID=$!

cd $BASE_DIR

if [ ! -e $IMAGE ] ; then
	echo "Image $IMAGE not found in $BASE_DIR"
	ERROR=1
	exit 1
fi

if [ "$BACKUP" == "yes" ] ; then
	cp -v $IMAGE $IMAGE.bkup
fi

IMAGE_DIR=$(sed 's/[\.][a-zA-Z0-9.]*$//' <<< $IMAGE)
mkdir -v $IMAGE_DIR

echo "mount" > $SCRIPT_DIR/tmp/supipei
read code < $SCRIPT_DIR/tmp/supipeo
if [ $code -ne 0 ] ; then
	MAINSU_PID=
	false
	checkerr
fi

set +h
umask 022

echo "mount-vkfs" > $SCRIPT_DIR/tmp/supipei
read code < $SCRIPT_DIR/tmp/supipeo
if [ $code -ne 0 ] ; then
	ERROR=1
	exit 1
fi
VKFSMOUNTED=1

mkdir -pv $IMAGE_DIR/sources

mkdir -pv $IMAGE_DIR/tools/pkgs

cp -v $SCRIPT_DIR/pkgs/versions $IMAGE_DIR/tools/pkgs
cp -rv $SCRIPT_DIR/pkgs/target/* $IMAGE_DIR/tools/pkgs
cp -rv $SCRIPT_DIR/pkgs/misc $IMAGE_DIR/tools/pkgs
cp -v $SCRIPT_DIR/pkg.sh $IMAGE_DIR/tools/pkgs/pkg.sh

if [ -f $SCRIPT_DIR/../$PACKAGE ] ; then
	awk '($0 !~ /^#/) {print;}' $SCRIPT_DIR/../$PACKAGE > $IMAGE_DIR/tools/pkgs/.install
else
	echo $PACKAGE > $IMAGE_DIR/tools/pkgs/.install
fi

echo "$JOBS" > $IMAGE_DIR/tools/njobs

cp -v $SCRIPT_DIR/appman-installer.sh $IMAGE_DIR/tools/installer.sh

echo "chroot" > $SCRIPT_DIR/tmp/supipei
read code < $SCRIPT_DIR/tmp/supipeo
if [ $code -ne 0 ] ; then
	ERROR=1
	exit 1
fi
