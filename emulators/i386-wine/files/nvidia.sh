#!/bin/sh
# Copyright 2010 to 2015 David Naylor <dbn@FreeBSD.org>
# Copyright 2012 Jan Beich <jbeich@tormail.org>
# Copyright 2020 Lorenzo Salvadore <salvadore@FreeBSD.org>
#       All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#
#   2. Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the documentation
#      and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY David Naylor ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL David Naylor OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing official
# policies, either expressed or implied, of David Naylor.

set -e

PORTSDIR=${PORTSDIR:-/usr/ports}
PREFIX=${PREFIX:-/usr/local}
DISTDIR=${DISTDIR:-${PORTSDIR}/distfiles}

if [ -d $DISTDIR ]
then
  cd $DISTDIR
  NO_REMOVE_NVIDIA="yes"
else
  cd /tmp/
fi

terminate() {

  echo "!!! $2 !!!"
  echo "Terminating..."
  exit $1

}

args=`getopt dn $*`
if [ $? -ne 0 ]
then
  echo "Usage: $0 [-n]"
  exit 7
fi
set -- $args
while true
do
  case $1 in
    -d)
      rm -f ${PREFIX}/lib32/libGL.so.1 
      rm -f ${PREFIX}/lib32/libGLcore.so.1 ${PREFIX}/lib32/libnvidia-tls.so.1 
      rm -f ${PREFIX}/lib32/libnvidia-glcore.so.1 ${PREFIX}/lib32/libnvidia-tls.so.1
      rm -rf  ${PREFIX}/lib32/.nvidia/
      exit 0
      ;;
    -n)
      NO_FETCH=yes
      ;;
    --)
      shift
      break
      ;;
  esac
  shift
done

version() {
  local ret pkg="$1"
  if [ -f "/usr/local/sbin/pkg" ]
  then
    ret=`pkg query -g '%v' "$pkg" || true`
  fi

  # installed manually or failed to register
  if [ -z "$ret" ] && [ "$pkg" = "nvidia-driver*" ]
  then
    ret=`sed -n "s/.*Version: //p" 2> /dev/null \
      $PREFIX/share/doc/NVIDIA_GLX-1.0/README || true`
  fi
  echo "$ret"
}

[ `whoami` = root ] \
  || terminate 254 "This script should be run as root"

echo "===> Patching i386-wine to work with x11/nvidia-driver:"

if [ -z "${WINE}" ]
then
  WINE=`version 'i386-wine*'`
fi
[ -n "$WINE" ] \
  || terminate 255 "Unable to detect i386-wine, please install first"
echo "=> Detected i386-wine: ${WINE}"

NV=`version 'nvidia-driver*'`
[ -n "$NV" ] \
  || terminate 1 "Unable to detect nvidia-driver, please install first"
echo "=> Detected nvidia-driver: ${NV}"

NVIDIA=${NV}
NV=`echo ${NV} | cut -f 1 -d _ | cut -f 1 -d ,`
NVmajor=`echo $NV | sed -E 's/([0-9]+)\.[0-9]+/\1/'`

# nvidia-driver v390.132 was the last one shipping 
# 32-bit library package, after that only x86_64 is shipped containing 
# both 32-bit and 64-bit GL libraries
if [ ${NVmajor} -gt 390 ] ; then
    downloadFilename=NVIDIA-FreeBSD-x86_64-${NV}.tar.gz  
    downloadDirectory=FreeBSD-x86_64
else
    downloadFilename=NVIDIA-FreeBSD-x86-${NV}.tar.gz
    downloadDirectory=FreeBSD-x86
fi

if [ ! "$(pkg version -t ${NV} 440.59)" == "<" ]
then
  terminate 0 "nvidia-driver 440.59+ already includes 32-bit drivers: nothing to do"
fi

if [ ! -f NVIDIA-FreeBSD-x86-${NV}.tar.gz ] || !(tar -tf NVIDIA-FreeBSD-x86-${NV}.tar.gz > /dev/null 2>&1)
then
  [ -n "$NO_FETCH" ] \
    && terminate 8 "${downloadFilename} unavailable"
  echo "=> Downloading ${downloadFilename} from https://download.nvidia.com..."
  rm -f ${downloadFilename}
  fetch -aRr https://download.nvidia.com/XFree86/${downloadDirectory}/${NV}/${downloadFilename} \
    || terminate 2 "Failed to download ${downloadFilename}"
  echo "=> Downloaded ${downloadFilename}"
  echo "Please check the following information against /usr/ports/x11/nvidia-driver/distinfo"
  sha256 ${downloadFilename}
  echo "SIZE (${downloadFilename}) = `stat -f "%z" ${downloadFilename}`"
fi

echo "=> Extracting ${downloadFilename} to $PREFIX/lib32..."
EXTRACT_LIST="libGL.so.1"
case $NV in
  195*|173*|96*|71*)
    EXTRACT_LIST="$EXTRACT_LIST libGLcore.so.1 libnvidia-tls.so.1"
    ;;
  *)
    EXTRACT_LIST="$EXTRACT_LIST libnvidia-glcore.so.1 libnvidia-tls.so.1"
    ;;
esac

EXTRACT_ARGS="--no-same-owner --no-same-permissions --strip-components 2 -C $PREFIX/lib32"
for i in $EXTRACT_LIST
do
  if [ ${NVmajor} -ge 390 ] ; then
      if [ $i == "libGL.so.1" ] ; then	
          EXTRACT_ARGS="$EXTRACT_ARGS --include NVIDIA-FreeBSD-x86_64-${NV}/obj/libglvnd/32/$i"
      else   
          EXTRACT_ARGS="$EXTRACT_ARGS --include NVIDIA-FreeBSD-x86_64-${NV}/obj/32/$i"
      fi
  else
          EXTRACT_ARGS="$EXTRACT_ARGS --include NVIDIA-FreeBSD-x86-${NV}/obj/$i"
  fi 
done
umask 0333
tar $EXTRACT_ARGS -xvf ${downloadFilename} \
  || terminate 3 "Failed to extract ${downloadFilename}"
mkdir -m 0755 -p ${PREFIX}/lib32/.nvidia \
  || terminate 9 "Failed to create .nvidia shadow directory"
mv ${PREFIX}/lib32/libGL.so.1 ${PREFIX}/lib32/.nvidia/ \
  || terminate 10 "Failed to move libGL.so.1 to .nvidia/ shadow directory"
ln -s .nvidia/libGL.so.1 ${PREFIX}/lib32/libGL.so.1 \
  || terminate 11 "Failed to link to .nvidia/libGL.so.1 in the shadow directory" 

echo "=> Cleaning up..."
[ -n "$NO_REMOVE_NVIDIA" ] || rm -vf ${downloadFilename} \
  || terminate 6 "Failed to remove files"

echo "===> i386-wine-${WINE} successfully patched for nvidia-driver-${NVIDIA}"
