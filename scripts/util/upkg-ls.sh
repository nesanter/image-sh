#!/bin/bash

if [ ! -e /usr/pkg/manifest ] ; then
	echo "Manifest file not found"
	exit 1
fi

case "$1" in
	"-q")	awk 'BEGIN {FS=":"} {print $1}' /usr/pkg/manifest ;;
	"-c")	cat /usr/pkg/manifest | wc -l ;;
	"-f")	awk 'BEGIN {FS=":"} {print $1}' /usr/pkg/manifest | while read PKG ; do
			FILES=$(find / -user $PKG | wc -l)
			echo "$PKG: $FILES files"
		done
		;;
	"")	awk 'BEGIN {FS=":"} {if ($3 == "") { $3="none";  }; print $1 " (version " $2 " required by " $3 ")"}' /usr/pkg/manifest ;;
	*)	echo "Syntax: upkg-ls [-q|-c|-f]" ;;
esac