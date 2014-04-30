#!/bin/bash

## download sources specified in package

if [ $? -eq 1 ] ; then
	echo "Syntax: dl.sh package-name"
	exit 1
fi

if [ ! -e $1 ] ; then
	echo "Package $1 not found"
	exit 1
fi

. $1

F1=$(mktemp)
F2=$(mktemp)

awk 'BEGIN {RS=","; ORS="\n"} {print;}' > $F1 <<< $sources
awk 'BEGIN {RS=","; ORS="\n"} {print;}' > $F2 <<< $urls

while read SRC <&7 ; do
	read URL <&8
	if [ -n "$URL" ] ; then
		wget $URL$SRC
	fi
done 7<$F1 8<$F2

rm $F1 $F2