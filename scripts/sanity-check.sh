#!/bin/bash

if [ ! -f scripts/main.sh ] ; then
	echo "Missing key script (main.sh)"
	exit 1
fi

if [ ! -f scripts/main-su.sh ] ; then
	echo "Missing key script (main-su.sh)"
	exit 1
fi

if [ ! -f scripts/pkg.sh ] ; then
	echo "Missing key script (pkg.sh)"
	exit 1
fi

if [ ! -f scripts/appman-main.sh ] ; then
	echo "Missing key script (appman-main.sh)"
fi

if [ ! -f scripts/pkgs/tools/manifest ] ; then
	echo "Missing manifest file"
	exit 1
fi

if [ ! -d scripts/tmp ] ; then
	echo "Non-critical error: Missing tmp directory"
	mkdir -v scripts/tmp
fi

if [ ! -d scripts/pkgs ] ; then
	echo "Missing pkgs directory"
	exit 1
fi

if [ ! -d scripts/pkgs/tools ] ; then
	echo "Missing pkgs/tools directory"
	exit 1
fi

if [ ! -d scripts/pkgs/target ] ; then
	echo "Missing pkgs/target directory"
	exit 1
fi

awk '($0 !~ /^#/) {print;}' scripts/pkgs/tools/manifest | while read $PKG ; do
	if [ $PKG ] ; then
		if [ ! -f scripts/pkgs/tools/$PKG ] ; then
			echo "Missing package ($PKG)"
			exit 1
		fi
	fi
done