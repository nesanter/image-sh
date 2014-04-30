#!/bin/bash

## upkg install system

if [ $# -eq 0 ] ; then
	echo "Syntax: upkg package-name"
	exit 1
fi

if [ ! -e /usr/pkg/scripts/$1.pkg ] ; then
	if [ -e $1 ] ; then
		PKG=$1
	else
		echo "Package $1 not found"
		exit 1
	fi
else
	PKG=/usr/pkg/scripts/$1.pkg
fi

if [ $UID -ne 0 ] ; then
	echo "Must be run as root"
	exit 1
fi

. $PKG

if [ -z "$pkgname" ] ; then
	echo "Package file is missing pkgname"
	exit 1
fi

## Check dependencies

echo "Installing package $pkgname..."

if [ -n "$deps" ] ; then
	echo "Checking for dependencies"
	echo $deps | awk 'BEGIN {RS=","; ORS="\n"} {print;}' | while read DEP ; do
		if [ -n "$DEP" ] ; then
			echo -ne "$DEP......"
			if [ -z "$(grep $DEP /usr/pkg/manifest)" ] ; then
				echo "MISSING"
				exit 1
			fi
			echo "OK"
		fi
	done || exit 1
fi

## Check for sources

echo "Checking for sources"
echo $sources | awk 'BEGIN {RS=","; ORS="\n"} {print;}' | while read SRC ; do
	if [ -n "$SRC" ] ; then
		echo -ne "$SRC......"
		if [ ! -e /sources/$SRC ] ; then
			echo "MISSING"
			exit 1
		fi
		echo "OK"
	fi
done || exit 1

echo "Setting up package user"

## Create package user

if [ -z "$(grep ^$group: /etc/group)" ] ; then
	echo "Package attempting to install under unauthorized group"
	echo "Please add $group to /etc/group to continue"
	exit 1
fi

GROUPID=$(sed -n '/^'$group':/ s/.*:x:\([0-9]*\):.*/\1/p' /etc/group)

if [ -n "$(grep $pkgname: /etc/passwd)" ] ; then
	echo "Package user already exists"
	echo "Enter 'y' to update package:"
	read yesno
	if [ ! $yesno == "y" ] ; then
		echo "Aborting"
		exit 1
	fi
	UPDATE=1
else
	NEWUID=$(cat /usr/pkg/pkgid)
	echo "$pkgname:x:$NEWUID:$GROUPID:$pkgname:/usr/pkg/$pkgname:/bin/bash" >> /etc/passwd
	sed -i '/^install:/ s/\(.*\)/\1,'$pkgname'/' /etc/group
	if [ -z "$(sed -n 's/^'$group':x:[0-9]*://p' /etc/group)" ] ; then
		sed -i '/^'$group':/ s/\(.*\)/\1'$pkgname'/' /etc/group
	else
		sed -i '/^'$group':/ s/\(.*\)/\1,'$pkgname'/' /etc/group
	fi
	cp -r /usr/pkg/skel /usr/pkg/$pkgname
	chown -R $pkgname:$group /usr/pkg/$pkgname
	chmod u=rwx,g=rx,o= /usr/pkg/$pkgname
	echo "$NEWUID 1 + p" | dc > /usr/pkg/pkgid
	UPDATE=0
fi

## Setup

cp $PKG /usr/pkg/$pkgname/pkg.sh
chown $pkgname:$group /usr/pkg/$pkgname/pkg.sh

mount -t tmpfs tmpfs /usr/pkg/$pkgname/src

echo $sources | awk 'BEGIN {RS=","; ORS="\n"} {print;}' | while read SRC ; do
	if [ -n "$SRC" ] ; then
		cp /sources/$SRC /usr/pkg/$pkgname/src
	fi
done

## Switch to package user

echo "Running install script"

su $pkgname -c "cd; upkg-install"

if [ $? -ne 0 ] ; then
	echo "Error: cannot continue"
	echo "Cleanup using upkg-rm $1"
	umount /usr/pkg/$pkgname/src
	exit 1
fi

echo "Updating permissions"

chmod g+w $(find / -user $NEWUID -type d)

echo "Running postscript"

postscript
if [ $? -ne 0 ] ; then
	echo "Postscript has exited with non-zero status"
	echo "Error: cannot continue"
	echo "Cleanup using upkg-rm $1"
	umount /usr/pkg/$pkgname/src
	exit 1
fi

echo "Updating manifest"

if [ $UPDATE -eq 1 ] ; then
	sed -i '/^'$pkgname':/ s/:.*:/:'$version':/' /usr/pkg/manifest
else
	echo "$pkgname:$version:" >> /usr/pkg/manifest
fi

if [ $UPDATE -eq 1 ] ; then
	sed -i 's/\(.*:.*:.*\)\(,'$pkgname'\|'$pkgname'$\|'$pkgname',\)\(.*\)/\1\3/' /usr/pkg/manifest
fi

if [ -n "$deps" ] ; then
	echo $deps | awk 'BEGIN {RS=","; ORS="\n"} {print;}' | while read DEP ; do
		if [ -n "$DEP" ] ; then
			if [ -z "$(sed -n 's/^'$DEP':.*://p' /etc/group)" ] ; then
				sed -i '/^'$DEP':/ s/\(.*\)/\1'$pkgname'/' /usr/pkg/manifest
			else
				sed -i '/^'$DEP':/ s/\(.*\)/\1,'$pkgname'/' /usr/pkg/manifest
			fi
		fi
	done
fi

umount /usr/pkg/$pkgname/src

echo "Done."