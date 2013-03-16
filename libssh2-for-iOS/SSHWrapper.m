//
//  SSHWrapper.m
//  libssh2-for-iOS
//
//  Created by Felix Schulze on 01.02.11.
//  Copyright 2010 Felix Schulze. All rights reserved.
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
//
//  @see: http://www.libssh2.org/examples/ssh2_exec.html

#import "SSHWrapper.h"

#include "libssh2.h"
#include "libssh2_config.h"
#include "libssh2_sftp.h"
#include <sys/socket.h>
#include <arpa/inet.h>




static int waitsocket(int socket_fd, LIBSSH2_SESSION *session)
{
    struct timeval timeout;
    int rc;
    fd_set fd;
    fd_set *writefd = NULL;
    fd_set *readfd = NULL;
    int dir;

    timeout.tv_sec = 10;
    timeout.tv_usec = 0;

    FD_ZERO(&fd);

    FD_SET(socket_fd, &fd);

    /* now make sure we wait in the correct direction */
    dir = libssh2_session_block_directions(session);

    if(dir & LIBSSH2_SESSION_BLOCK_INBOUND)
        readfd = &fd;

    if(dir & LIBSSH2_SESSION_BLOCK_OUTBOUND)
        writefd = &fd;

    rc = select(socket_fd + 1, readfd, writefd, NULL, &timeout);

    return rc;
}

@implementation SSHWrapper {
    int sock;
    LIBSSH2_SESSION *session;
    LIBSSH2_CHANNEL *channel;
    int rc;
}

- (void)dealloc {
    [self closeConnection];
    session = nil;
    channel = nil;
}


- (void)connectToHost:(NSString *)host port:(int)port user:(NSString *)user password:(NSString *)password error:(NSError **)error {
    if (host.length == 0) {
        *error = [NSError errorWithDomain:@"de.felixschulze.sshwrapper" code:300 userInfo:@{NSLocalizedDescriptionKey:@"No host"}];
        return;
    }
	const char* hostChar = [host cStringUsingEncoding:NSUTF8StringEncoding];
	const char* userChar = [user cStringUsingEncoding:NSUTF8StringEncoding];
	const char* passwordChar = [password cStringUsingEncoding:NSUTF8StringEncoding];
    struct sockaddr_in sock_serv_addr;
    unsigned long hostaddr = inet_addr(hostChar);

    sock = socket(AF_INET, SOCK_STREAM, 0);
    sock_serv_addr.sin_family = AF_INET;
    sock_serv_addr.sin_port = htons(port);
    sock_serv_addr.sin_addr.s_addr = hostaddr;
    if (connect(sock, (struct sockaddr *) (&sock_serv_addr), sizeof(sock_serv_addr)) != 0) {
        *error = [NSError errorWithDomain:@"de.felixschulze.sshwrapper" code:400 userInfo:@{NSLocalizedDescriptionKey:@"Failed to connect"}];
        return;
    }
	
    /* Create a session instance */
    session = libssh2_session_init();
    if (!session) {
        *error = [NSError errorWithDomain:@"de.felixschulze.sshwrapper" code:401 userInfo:@{NSLocalizedDescriptionKey : @"Create session failed"}];
        return;
    }
	
    /* tell libssh2 we want it all done non-blocking */
    libssh2_session_set_blocking(session, 0);
	
    /* ... start it up. This will trade welcome banners, exchange keys,
     * and setup crypto, compression, and MAC layers
     */
    while ((rc = libssh2_session_startup(session, sock)) ==
           LIBSSH2_ERROR_EAGAIN);
    if (rc) {
        *error = [NSError errorWithDomain:@"de.felixschulze.sshwrapper" code:402 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Failure establishing SSH session: %d", rc]}];
        return;
    }

    if ( strlen(passwordChar) != 0 ) {
		/* We could authenticate via password */
        while ((rc = libssh2_userauth_password(session, userChar, passwordChar)) == LIBSSH2_ERROR_EAGAIN);
		if (rc) {
            *error = [NSError errorWithDomain:@"de.felixschulze.sshwrapper" code:403 userInfo:@{NSLocalizedDescriptionKey : @"Authentication by password failed."}];
            return;
		}
	}
}

- (NSString *)executeCommand:(NSString *)command error:(NSError **)error {
	const char* commandChar = [command cStringUsingEncoding:NSUTF8StringEncoding];

	NSString *result = nil;
	
    /* Exec non-blocking on the remove host */
    while( (channel = libssh2_channel_open_session(session)) == NULL &&
		  libssh2_session_last_error(session,NULL,NULL,0) == LIBSSH2_ERROR_EAGAIN )
    {
        waitsocket(sock, session);
    }
    if( channel == NULL )
    {
        *error = [NSError errorWithDomain:@"de.felixschulze.sshwrapper" code:501 userInfo:@{NSLocalizedDescriptionKey : @"No channel found."}];
        return nil;
    }
    while( (rc = libssh2_channel_exec(channel, commandChar)) == LIBSSH2_ERROR_EAGAIN )
    {
        waitsocket(sock, session);
    }
    if( rc != 0 )
    {
        *error = [NSError errorWithDomain:@"de.felixschulze.sshwrapper" code:502 userInfo:@{NSLocalizedDescriptionKey : @"Error while exec command."}];
        return nil;
    }
    for( ;; )
    {
        /* loop until we block */
        int rc1;
        do
        {
            char buffer[0x2000];
            rc1 = libssh2_channel_read( channel, buffer, sizeof(buffer) );
            if( rc1 > 0 )
            {
				result = @(buffer);
            }
        }
        while( rc1 > 0 );
		
        /* this is due to blocking that would occur otherwise so we loop on
		 this condition */
        if( rc1 == LIBSSH2_ERROR_EAGAIN )
        {
            waitsocket(sock, session);
        }
        else
            break;
    }
    while( (rc = libssh2_channel_close(channel)) == LIBSSH2_ERROR_EAGAIN )
        waitsocket(sock, session);
	
    libssh2_channel_free(channel);
    channel = NULL;
	
    return result;
	
}


- (void)closeConnection {
    if (session) {
        libssh2_session_disconnect(session, "Normal Shutdown, Thank you for playing");
        libssh2_session_free(session);
        session = nil;
    }
    close(sock);
}

@end
