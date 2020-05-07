#!/bin/bash
if [ -z "$ARCH" ] ; then
u=`uname`
ARCH=cygwin
if [ $u = Linux ] ; then
 ARCH=linux
fi
if [ $u = SunOS ] ; then
 ARCH=solaris
fi
if [ $u = Darwin ] ; then
 ARCH=macosx
fi
fi
echo ARCH set to $ARCH
