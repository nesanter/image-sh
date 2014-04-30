image-sh
===
Scripts to create a Linux image by compiling all sources from scratch

Once the initial image is created, packages can be added through the rudimentary package manager system

The created image is designed to be booted via PXE (e.g. using pxelinux) and to be very light-weight

Customization can be performed by passing an initial configuration file, creating target or tools packages, or modifying the scripts

An example configuration script is provided, although without a script the image maker falls back to sane defaults