#!/bin/bash

#  Automatic build script for libgcrypt 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 31.01.11.
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Change values here
#
VERSION="1.5.0"
SDKVERSION="6.1"
#
###########################################################################
#
# Don't change anything here
CURRENTPATH=`pwd`
ARCHS="i386 armv7 armv7s"
DEVELOPER=`xcode-select -print-path`
##########
set -e
if [ ! -e libgcrypt-${VERSION}.tar.gz ]; then
	echo "Downloading libgcrypt-${VERSION}.tar.gz"
    curl -O ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-${VERSION}.tar.gz
else
	echo "Using libgcrypt-${VERSION}.tar.gz"
fi

if [ -f ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libgpg-error.a ];
then 
  echo "Using libgpg-error"
else
  echo "Please build libgpg-error first"
  exit 1
fi

mkdir -p bin
mkdir -p lib
mkdir -p src

for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi
	echo "Building libgcrypt for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."
	tar zxf libgcrypt-${VERSION}.tar.gz -C src
	cd src/libgcrypt-${VERSION}
	
	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-libgcrypt-${VERSION}.log"

	echo "Patching libgcrypt to compile with iOS-SDK..."
	echo "@see http://www.telesphoreo.org/browser/trunk/data/gcrypt/armasm.diff"
	patch -p0 < ../../armasm.diff >> "${LOG}" 2>&1
	echo "Patching done."

	export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"
	export CC=${DEVROOT}/usr/bin/gcc
	export LD=${DEVROOT}/usr/bin/ld
	export CPP=${DEVROOT}/usr/bin/llvm-cpp-4.2
	export CXX=${DEVROOT}/usr/bin/g++
	export AR=${DEVROOT}/usr/bin/ar
	export AS=${DEVROOT}/usr/bin/as
	export NM=${DEVROOT}/usr/bin/nm
	export CXXCPP=$DEVROOT/usr/bin/llvm-cpp-4.2
	export RANLIB=$DEVROOT/usr/bin/ranlib
	export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -L${CURRENTPATH}/lib"
	export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/include"
	export CXXFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/include"

	./configure --host=${ARCH}-apple-darwin --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" --disable-shared --enable-static --with-gpg-error-prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" >> "${LOG}" 2>&1

	make >> "${LOG}" 2>&1
	make install >> "${LOG}" 2>&1
	cd ${CURRENTPATH}
	rm -rf src/libgcrypt-${VERSION}
	
done

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libgcrypt.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libgcrypt.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/lib/libgcrypt.a -output ${CURRENTPATH}/lib/libgcrypt.a
mkdir -p ${CURRENTPATH}/include/libgcrypt
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/gcrypt* ${CURRENTPATH}/include/libgcrypt/
echo "Building done."