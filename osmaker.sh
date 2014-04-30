#!/bin/bash

##Default configuration

BASE_DIR=$(pwd)
IMAGE=out.img
IMAGE_SIZE=100
FS_TYPE=ext2
FS_OPTS=
MOUNT_OPTS=
DL_DIR=
ARCH=$(uname -m)
SAVE=yes
NOTARGET=no
VERSIONFILE=
MINKERNEL=
JOBS=$(nproc)
SRC_DIR=

V=1.0

if [ "$1" == "options" ] ; then
	echo "OSMAKER v$V"
	echo "Options:"
	echo " BASE_DIR    -- directory where the image will be stored   [defualt: here    ]"
	echo " IMAGE       -- name of the image (inclduing suffix)       [default: out.img ]"
	echo " IMAGE_SIZE  -- size in megabytes of the image             [default: 100     ]"
	echo " FS_TYPE     -- file system to create on the image         [default: ext2    ]"
	echo " FS_OPTS     -- options to pass to mkfs                    [default:         ]"
	echo " MOUNT_OPTS  -- options to pass to mount                   [default:         ]"
	echo " DL_DIR      -- download directory (inside image if blank) [default:         ]"
	echo " ARCH        -- architecture                               [default: current ]"
	echo " SAVE        -- save image if interrupted                  [default: yes     ]"
	echo " NOTARGET    -- stop after installing toolchain            [default: no      ]"
	echo " VERSIONFILE -- version override file                      [default:         ]"
	echo " JOBS        -- number of make jobs                        [default: nproc   ]"
	echo " SRC_DIR     -- build directory                            [default: in img  ]"
	exit
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

##Load config

if [ $1 ] ; then
	if [ -e $1 ] ; then
		. $1
	else
		echo "Config file ($1) not found"
		exit 1
	fi
fi

##Launch main scripts

env - \
BASE_DIR=$BASE_DIR \
IMAGE=$IMAGE \
IMAGE_SIZE=$IMAGE_SIZE \
FS_TYPE=$FS_TYPE \
FS_OPTS=$FS_OPTS \
DL_DIR=$DL_DIR \
ARCH=$ARCH \
SAVE=$SAVE \
NOTARGET=$NOTARGET \
VERSIONFILE=$VERSIONFILE \
MINKERNEL=$MINKERNEL \
JOBS=$JOBS \
SRC_DIR=$SRC_DIR \
scripts/main.sh