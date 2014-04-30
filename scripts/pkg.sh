#!/bin/sh

cd $SOURCES

. $1

echo "Full package:    $package"
echo "URL:             $url"

if [ ! $package ] ; then
	echo Package not specified, aborting
	ERROR=1
	exit 1
fi
if [ $url ] ; then
	if [ $DL_DIR ] ; then
		if [ ! -e $DL_DIR/$package ] ; then
			wget -P $DL_DIR $url$package
		fi
		cp -v $DL_DIR/$package .
	else
		wget $url$package
	fi
else
	echo "Searching locally"
	if [ $DL_DIR -a -e $DL_DIR/$package ] ; then
		cp -v $DL_DIR/$package .
	else
		echo "URL not specified and package not found locally, aborting"
		ERROR=1
		exit 1
	fi
fi

if [ $? -ne 0 ] ; then
	echo "Download error: cannot continue"
	ERROR=1
	exit 1
fi

if [ $PV ] ; then
	
	echo "extension = $(echo $package | grep -o '[\.][a-zA-Z0-9]*$')"
	
	case $(echo $package | grep -o '[\.][a-zA-Z0-9]*$') in
		.tar)
			pv $package | tar x
			;;
		.xz)
			pv $package | tar xJ
			;;
		.bz2)
			pv $package | tar xj
			;;
		.gz)
			pv $package | tar xz
			;;
		.lzma)
			pv $package | tar x --lzma
			;;
		*)
			echo "Unknown file extension: $package"
			ERROR=1
			exit 1
			;;
	esac
else
	tar -xf $package
fi

if [ $? -ne 0 ] ; then
	echo "Error: cannot continue"
	ERROR=1
	rm -v $package
	exit 1
fi

PKGRAW=$(echo $package | sed 's/\.tar\(\.bz2\|\.xz\|\.gz\|\.lzma\)\?$//')
cd $PKGRAW

if [ ! "$dummy" == "yes" ] ; then
	PKGDIR=$(pwd)
	
	prescript
	if [ $? -ne 0 ] ; then
		echo "Error in prescript: cannot continue"
		rm -v $SOURCES/$package
		rm -r $SOURCES/$PKGRAW
		ERROR=1
		exit 1
	fi
	
	if [ "$builddir" == "yes" ] ; then
		mkdir -pv ../$PKGRAW-build
		cd ../$PKGRAW-build
	fi
	
	( (body || touch fail) > >(tee ../$PKG-out | awk 'BEGIN {ORS=""} {print "."} NR%10==0 {fflush()}') ) 2> >(tee ../$PKG-out-err | awk 'BEGIN {ORS=""} {print "!"; fflush()}')
	if [ $? -ne 0 ] ; then
		echo "Error in body: cannot continue"
		rm -v $SOURCES/$package
		rm -r $SOURCES/$PKGRAW
		ERROR=1
		exit 1
	fi
	
	postscript
	if [ $? -ne 0 ] ; then
		echo "Error in postscript: cannot continue"
		rm -v $SOURCES/$package
		rm -r $SOURCES/$PKGRAW
		ERROR=1
		exit 1
	fi
fi

if [ ! "$keep" == "yes" ] ; then
	echo "Cleaning $PKG"
	rm -v $SOURCES/$package
	rm -r $SOURCES/$PKGRAW
	if [ $builddir == "yes" ] ; then
		rm -r $SOURCES/$PKGRAW-build
	fi
fi

unset package
unset url
unset builddir
unset dummy
unset keep

echo "$PKG complete"