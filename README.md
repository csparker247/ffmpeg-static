FFmpeg static build
===================

Three scripts to make a static build of ffmpeg with all the latest codecs (webm + h264).

Just follow the instructions below. Once you have the build dependencies,
just run ./build.sh, wait and you should get the ffmpeg binary in target/bin

Build dependencies
------------------
 * Xcode and the Command Line Utilities
 * pkg-config (Install using Homebrew)

Build & "install"
-----------------

    $ ./build.sh or build-ubuntu.sh
    # ... wait ...
    # binaries can be found in ./target/bin/

NOTE: If you're going to use the h264 presets, make sure to copy them along the binaries. For ease, you can put them in your home folder like this:

    $ mkdir ~/.ffmpeg
    $ cp ./target/share/ffmpeg/*.ffpreset ~/.ffmpeg


Remaining links
---------------

I'm not sure it's a good idea to statically link those, but it probably
means the executable won't work across distributions or even across releases.

    # On Ubuntu 10.04:
    $ ldd ./target/bin/ffmpeg 
	not a dynamic executable

    # on OSX 10.6.4:
    $ otool -L ffmpeg 
	ffmpeg:
		/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 125.2.0)
 
