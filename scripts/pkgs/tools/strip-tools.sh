strip --strip-debug /tools/lib/*
strip --strip-unneeded /tools/{,s}bin/*
strip --strip-debug /tools/libexec/gcc/x86_64-alt-linux-gnu/$GCCVER/*
strip --strip-debug /tools/libexec/gcc/x86_64-unknown-linux-gnu/$GCCVER/*