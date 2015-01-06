#!/bin/bash

#  Automatic build script for libssh2 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 02.02.11.
#  Copyright 2010-2015 Felix Schulze. All rights reserved.
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
VERSION="1.4.3"
#
###########################################################################
#
# Don't change anything here
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`                                                          
CURRENTPATH=`pwd`
ARCHS="i386 x86_64 armv7 armv7s arm64"
DEVELOPER=`xcode-select -print-path`
##########
set -e
if [ ! -e libssh2-${VERSION}.tar.gz ]; then
	echo "Downloading libssh2-${VERSION}.tar.gz"
    curl -O http://www.libssh2.org/download/libssh2-${VERSION}.tar.gz
else
	echo "Using libssh2-${VERSION}.tar.gz"
fi

echo "Checking file: libssh2-${VERSION}.tar.gz"
md5=`md5 -q libssh2-${VERSION}.tar.gz`
if [ $md5 != "071004c60c5d6f90354ad1b701013a0b" ]
then
	echo "File corrupt, please download again."
	exit 1
else
	echo "Checksum verified."
fi

mkdir -p bin
mkdir -p lib
mkdir -p src

for ARCH in ${ARCHS}
do
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi
	echo "Building libssh2 for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."
	tar zxf libssh2-${VERSION}.tar.gz -C src
	cd src/libssh2-${VERSION}

	export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"
	export LD=${DEVROOT}/usr/bin/ld
	export CC=${DEVELOPER}/usr/bin/gcc
	export CXX=${DEVELOPER}/usr/bin/g++
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
	then
		export AR=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar
		export AS=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/as
		export NM=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm
		export RANLIB=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib
	else
		export AR=${DEVROOT}/usr/bin/ar
		export AS=${DEVROOT}/usr/bin/as
		export NM=${DEVROOT}/usr/bin/nm
		export RANLIB=${DEVROOT}/usr/bin/ranlib
	fi
	export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -L${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib -miphoneos-version-min=7.0"
	export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include -miphoneos-version-min=7.0"
	export CPPFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include -miphoneos-version-min=7.0"

	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-libssh2-${VERSION}.log"
	echo ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk
	
		
	HOST="${ARCH}"
	if [ "${ARCH}" == "arm64" ];
	then
		HOST="aarch64"
	fi
	
	if [ "$1" == "openssl" ];
	then
		./configure --host=${HOST}-apple-darwin --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" --with-openssl --with-libssl-prefix=${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk --disable-shared --enable-static  >> "${LOG}" 2>&1
	else
		./configure --host=${HOST}-apple-darwin --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" --with-libgcrypt --with-libgcrypt-prefix=${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk --disable-shared --enable-static  >> "${LOG}" 2>&1
	fi
	
	make >> "${LOG}" 2>&1
	make install >> "${LOG}" 2>&1
	cd ${CURRENTPATH}
	rm -rf src/libssh2-${VERSION}
	
done

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libssh2.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/lib/libssh2.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libssh2.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/lib/libssh2.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/lib/libssh2.a -output ${CURRENTPATH}/lib/libssh2.a
mkdir -p ${CURRENTPATH}/include/libssh2
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/libssh2* ${CURRENTPATH}/include/libssh2/
echo "Building done."
