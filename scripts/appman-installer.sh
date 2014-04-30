#!/tools/bin/ash

PV=
SOURCES=/sources
DL_DIR=/sources

echo "Installing packages:"
cat /tools/pkgs/.install

cat /tools/pkgs/.install | while read PKG ; do
	if [ ! -f /tools/pkgs/$PKG ] ; then
		echo "Package $PKG not found"
		exit 1
	fi
	
	if [ -n "$(grep '^$PKG$' /usr/pkg/manifest)" ] ; then
		echo "$PKG already installed"
	else
		echo "Installing $PKG"
		
		grep '^deps=' /tools/pkgs/$PKG | sed 's/^deps=//' | awk 'BEGIN {RS=","; ORS="\n"} {print;}' | while read DEP ; do
			if [ -n "$DEP" ] ; then
				if [ -z "$(grep '^$DEP$' /usr/pkg/manifest)" ] ; then
					echo "Missing dependency: $DEP"
					exit 1
				else
					echo "Dependency $DEP installed"
				fi
			fi
		done
		
		unset PKGVER
		if [ $VERSIONFILE ] ; then
			PKGVER=$(awk '/^'$PKG'/ {print $2}' $VERSIONFILE)
		fi
		if [ ! $PKGVER ] ; then
			PKGVER=$(awk '/^'$PKG'/ {print $2}' /tools/pkgs/versions)
		fi
		
		. /tools/pkgs/pkg.sh /tools/pkgs/$PKG
		
		echo $PKG >> /usr/pkg/manifest
	fi
done