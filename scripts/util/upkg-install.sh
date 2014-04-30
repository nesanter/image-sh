if [ $UID -eq 0 ] ; then
	echo "This script should not be run as root"
	exit 1
fi

. pkg.sh

cd src

# Extract

for SRC in $(awk 'BEGIN {RS=","; ORS="\n"} {print;}' <<< $sources) ; do
	if [ -n "$(grep \.tar <<< $SRC)" ] ; then
		tar -xf $SRC
	fi
done

PRIMARYSRC=$(sed 's/,.*//;s/\.tar\(\.bz2\|\.gz\|\.xz\|\.lzma\)\?$//' <<< $sources)

if [ -d $PRIMARYSRC ] ; then
	cd $PRIMARYSRC
fi

export JOBS=$(echo "$(mpstat | sed -n 's/.*(\([0-9]\?\) CPU).*/\1/p') 2 * p" | dc)
echo "Building with -j$JOBS"

( (pkgscript || touch fail) > >(tee ~/out | \
awk 'BEGIN {ORS=""} {print "."} NR%10==0 {fflush()}') ) \
2> >(tee ~/out-err | awk 'BEGIN {ORS=""} {print "!"; fflush()}')

echo ""

if [ -e fail ] ; then
	echo "Package script has exited with non-zero status"
	exit 1
fi

if [ -e /sbin/ldconfig ] ; then
	echo "Running ldconfig helper"
	upkg-ldconfig-helper
fi