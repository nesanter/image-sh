chgrp install /{bin,sbin,lib,etc{,/opt},var{,/opt,/lib},opt}
chmod ug=rwx,o=rxt /{bin,sbin,lib,etc{,/opt},var{,/opt,/lib},opt}
chgrp install /usr/{,local/}{bin,include,lib,sbin}
chmod ug=rwx,o=rxt /usr/{,local/}{bin,include,lib,sbin}
chgrp install /usr/{,local/}share/{doc,info,locale,man,i18n}
chmod ug=rwx,o=rxt /usr/{,local/}share/{doc,info,locale,man,i18n}
chgrp install /usr/{,local/}share/{misc,terminfo,zoneinfo}
chmod ug=rwx,o=rxt /usr/{,local/}share/{misc,terminfo,zoneinfo}
chgrp install /usr/{,local/}share/man/man{1..8}
chmod ug=rwx,o=rxt /usr/{,local/}share/man/man{1..8}
chgrp install /var/{lib/{misc,locale},opt,local}
chmod ug=rwx,o=rxt /var/{lib/{misc,locale},opt,local}

chmod u=rwx,g=x,o= /bin/upkg-ldconfig-helper
chown root:install /bin/upkg-ldconfig-helper

for dir in usr usr/local ; do
	ln -sv share/{man,doc,info} $dir
done

case $(uname -m) in
	x86_64) ln -sv /lib /lib64 && ln -sv /lib /usr/lib64 && ln -sv /lib /usr/local/lib64 ;;
esac

ln -sv /run /var/run
ln -sv /run/lock /var/lock

ln -sv /tools/bin/{sh,cat,echo,pwd,stty,bash} /bin
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib

sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la

ln -sv /proc/self/mounts /etc/mtab

install -dv -m 0750 $IMAGE_DIR/root
install -dv -m 1777 $IAMGE_DIR/tmp $IMAGE_DIR/var/tmp
chown -v root:2 $IMAGE_DIR/var/log/lastlog
chmod -v 644 $IMAGE_DIR/var/log/lastlog
chmod -v 600 $IMAGE_DIR/var/log/btmp