#!/bin/bash

#  Automatic build script for libssh2 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 01.02.11.
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
if [ "$1" == "openssl" ];
then
	echo "Building openssl:"
	./openssl/build-libssl.sh $2
	./openssl/create-openssl-framework.sh
	echo "Build libssh2:"
	./build-libssh2.sh openssl
elif [ "$1" == "libgcrypt" ];
then
	echo "Build libgpg-error:"
	./libgcrypt-for-ios/build-libgpg-error.sh
	echo "Build libgcrypt:"
	./libgcrypt-for-ios/build-libgcrypt.sh
	echo "Build libssh2:"
	./build-libssh2.sh libgcrypt
else
	echo "Usage: ./build-all.sh openssl | libgcrypt"
fi