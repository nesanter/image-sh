#!/bin/bash

##Called like this:
##appman [-c config] image_file package-file|package_name

##Default configuration
BASE_DIR=$(pwd)
ARCH=$(uname -m)
VERSIONFILE=
JOBS=$(nproc)
BACKUP=yes

V=1.0

if [ $# -lt 2 ] ; then
	echo "APPMAN v$V"
	echo "appman [-c config] image_file package_file|package_name"
	exit 1
fi

##Sanity checking

if [ ! -d scripts ] ; then
	echo "Missing scripts directory"
	exit 1
fi

if [ -f scripts/sanity-check.sh ] ; then
	./scripts/sanity-check.sh
	if [ $? -ne 0 ] ; then
		exit 1
	fi
else
	echo "No sanity check found, attempting to continue anyways..."
fi

if [ $1 == "-c" ] ; then
	if [ $# -lt 4 ] ; then
		echo "APPMAN v$V"
		echo "appman [-c config] image_file package_file|package_name"
		exit 1
	fi
	if [ -e $2 ] ; then
		. $2
	else
		echo "Config file ($2) not found"
		exit 1
	fi
	shift 2
fi

env - \
BASE_DIR=$BASE_DIR \
IMAGE=$1 \
ARCH=$ARCH \
VERSIONFILE=$VERSIONFILE \
JOBS=$JOBS \
PACKAGE=$2 \
BACKUP=$BACKUP \
scripts/appman-main.sh