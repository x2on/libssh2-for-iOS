This is a tutorial for using self-compiled builds of the libssh2-library for iOS. You can build apps with XCode and the official SDK from Apple with this. I also made a small example-app for using the libraries with XCode and the iPhone/iPhone-Simulator.

@see: http://www.x2on.de/2011/02/02/libssh2-for-ios-iphone-and-ipad-example-app-with-ssh-connection/

The example uses libssh2 to make an ssh connection to an ssh server. Then you can execute commands on the server and get the output in your app.

You can build the libssh2 library with openssl or with libgcrypt!

libssh2 with openssl:
```bash
./build-all.sh openssl
```
libssh2 with libgcrypt:
```bash
./build-all.sh libgcrypt
```
## Changelog:

**2013-03-02**: OpenSSL 1.0.1e

**2013-01-01**: libssh 1.4.3

**2012-05-29**: OpenSSL 1.0.1c + libssh 1.4.2

**2011-02-08**: OpenSSL 1.0.0d
