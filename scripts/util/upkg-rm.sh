#!/bin/bash

## Remove a package

if [ $# -eq 0 ] ; then
	echo "Syntax: upkg-rm package-name"
	exit 1
fi

MANIFEST=$(grep ^$1: /usr/pkg/manifest)

if [ -z "$MANIFEST" ] ; then
	echo "Package not found in manifest"
	echo "Enter 'y' to continue"
	read YESNO
	if [ ! "$YESNO" == "y" ] ; then
		exit 1
	fi
fi

if [ -z "$(grep ^$1: /etc/passwd)" ] ; then
	echo "Package user not found, perhaps the package has been installed manually"
	exit 1
fi

DEPS=$(sed 's/^.*:.*://' <<< $MANIFEST)

if [ -n "$DEPCOUNT" ] ; then
	echo "Package has installed dependencies: "
	sed 's/,/\n/g' <<< $DEPS
	exit 1
fi

if [ -e /usr/pkg/$1/misc.lst ] ; then
	echo "The following files may need to be manually removed:"
	cat /usr/pkg/$1/misc.lst
fi

find / -user $1 -delete

sed -i '/^'$1':/d' /usr/pkg/manifest
sed -i 's/\(.*:.*:.*\)\(,'$1'\|'$1'$\|'$1',\)\(.*\)/\1\3/' /usr/pkg/manifest
sed -i '/^'$1':/d' /etc/passwd
sed -i 's/,'$1'$//;s/,'$1',/,/' /etc/group

echo "Done."