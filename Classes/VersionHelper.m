//
//  VersionHelper.m
//  libssh2-for-iOS
//
//  Created by Schulze Felix on 29.05.12.
//  Copyright 2012 Felix Schulze. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "VersionHelper.h"
#include <openssl/opensslv.h>
#include "libssh2.h"
#include "gcrypt.h"

@implementation VersionHelper

+ (NSString *) opensslVersion {
    return [NSString stringWithCString:OPENSSL_VERSION_TEXT encoding:NSUTF8StringEncoding];
}

+ (NSString *) libssh2Version {
    return [NSString stringWithCString:LIBSSH2_VERSION encoding:NSUTF8StringEncoding];
}

+ (NSString *) libgpgerrorVersion {
    return @"1.10";
}

+ (NSString *) libgcryptVersion {
    return [NSString stringWithCString:GCRYPT_VERSION encoding:NSUTF8StringEncoding];
}

@end
