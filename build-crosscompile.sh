#!/bin/sh

set -e
set -u

cd `dirname $0`
ENV_ROOT=`pwd`
. ./env.source

rm -rf "$BUILD_DIR" "$TARGET_DIR"
mkdir -p "$BUILD_DIR" "$TARGET_DIR"

# NOTE: this is a fetchurl parameter, nothing to do with the current script
#export TARGET_DIR_DIR="$BUILD_DIR"

echo "#### FFmpeg static build, by STVS SA ####"
cd $BUILD_DIR
../fetchurl "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz"
../fetchurl "http://libav.org/releases/libav-9.8.tar.gz"
../fetchurl "http://zlib.net/zlib-1.2.8.tar.gz"
../fetchurl "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz"
../fetchurl "http://download.sourceforge.net/libpng/libpng-1.6.2.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/ogg/libogg-1.3.0.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2"
../fetchurl "http://webm.googlecode.com/files/libvpx-v1.1.0.tar.bz2"
# ../fetchurl "http://downloads.sourceforge.net/project/faac/faac-src/faac-1.28/faac-1.28.tar.bz2?use_mirror=auto"
../fetchurl "http://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-0.1.0.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fopencore-amr%2Ffiles%2Ffdk-aac%2F&ts=1352301762&use_mirror=iweb"
../fetchurl "ftp://ftp.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-20130501-2245.tar.bz2"
../fetchurl "http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.gz"
../fetchurl "http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz?use_mirror=auto"
../fetchurl "http://ffmpeg.org/releases/ffmpeg-2.0.tar.gz"


echo "*** Building yasm ***"
cd "$BUILD_DIR/yasm-1.2.0"
./configure --prefix=$TARGET_DIR
make -j 4 && make install

echo "*** Building zlib ***"
cd "$BUILD_DIR/zlib-1.2.8"
./configure --prefix=$TARGET_DIR
make -j 4 && make install

echo "*** Building bzip2 ***"
cd "$BUILD_DIR/bzip2-1.0.6"
make
make install PREFIX=$TARGET_DIR

echo "*** Building libpng ***"
cd "$BUILD_DIR/libpng-1.6.2"
./configure --prefix=$TARGET_DIR --host=x86_64-apple-darwin10 --with-sysroot=/SDKs/MacOSX.platform/MacOSX10.6.sdk --enable-static --disable-shared
make -j 4 && make install

# Ogg before vorbis
echo "*** Building libogg ***"
cd "$BUILD_DIR/libogg-1.3.0"
./configure --prefix=$TARGET_DIR --host=x86_64-apple-darwin10 --with-sysroot=/SDKs/MacOSX.platform/MacOSX10.6.sdk --enable-static --disable-shared
make -j 4 && make install

# Vorbis before theora
echo "*** Building libvorbis ***"
cd "$BUILD_DIR/libvorbis-1.3.3"
./configure --prefix=$TARGET_DIR --target=x86_64-darwin10 --host=x86_64-apple-darwin10 --enable-static --disable-shared
make -j 4 && make install

echo "*** Building libtheora ***"
cd "$BUILD_DIR/libtheora-1.1.1"
./configure --prefix=$TARGET_DIR --target=x86_64-darwin10 --host=x86_64-apple-darwin10 --enable-static --disable-shared
make -j 4 && make install

echo "*** Building livpx ***"
cd "$BUILD_DIR/libvpx-v1.1.0"
./configure --prefix=$TARGET_DIR --target=x86_64-darwin10-gcc --sdk-path=/SDKs/MacOSX.platform/MacOSX10.6.sdk --enable-runtime-cpu-detect --enable-static --disable-shared
make -j 4 && make install

# echo "*** Building faac ***"
# cd "$BUILD_DIR/faac-1.28"
# ./configure --prefix=$TARGET_DIR --enable-static --disable-shared
# FIXME: gcc incompatibility, does not work with log()
# sed -i -e "s|^char \*strcasestr.*|//\0|" common/mp4v2/mpeg4ip.h
# make -j 4 && make install

echo "*** Building fdk-aac ***"
cd "$BUILD_DIR/fdk-aac-0.1.0"
./configure --prefix=$TARGET_DIR --host=x86_64-apple-darwin10 --with-sysroot=/SDKs/MacOSX.platform/MacOSX10.6.sdk --enable-static --disable-shared
make -j 4 && make install

cd "$BUILD_DIR/libav-9.8"
./configure --prefix=$TARGET_DIR/lavf --arch=x86_64 --target-os=darwin --sysroot=/SDKs/MacOSX.platform/MacOSX10.6.sdk --enable-cross-compile --enable-gpl --disable-debug --enable-runtime-cpudetect
make -j 4 && make install

echo "*** Building x264 ***"
cd "$BUILD_DIR/x264-snapshot-20130501-2245"
CFLAGS="-I$TARGET_DIR/lavf/include -mmacosx-version-min=10.6" LDFLAGS="-L$TARGET_DIR/lavf/lib -framework CoreFoundation -framework CoreVideo -framework VideoDecodeAcceleration" ./configure --prefix=$TARGET_DIR --host=x86_64-apple-darwin10 --enable-static --disable-asm --sysroot=/SDKs/MacOSX.platform/MacOSX10.6.sdk
make -j 4 && make install

echo "*** Building xvidcore ***"
cd "$BUILD_DIR/xvidcore/build/generic"
./configure --prefix=$TARGET_DIR --host=x86_64-apple-darwin10 --enable-static --disable-shared
make -j 4 && make install
#rm $TARGET_DIR/lib/libxvidcore.so.*

echo "*** Building lame ***"
cd "$BUILD_DIR/lame-3.99.5"
./configure --prefix=$TARGET_DIR --host=x86_64-apple-darwin10 --enable-static --disable-shared
make -j 4 && make install

# FIXME: only OS-sepcific
#rm -f "$TARGET_DIR/lib/*.dylib"
#rm -f "$TARGET_DIR/lib/*.so"

# FFMpeg
echo "*** Building FFmpeg ***"
cd "$BUILD_DIR/ffmpeg-2.0"
# --enable-libvpx 
CFLAGS="-I$TARGET_DIR/include -mmacosx-version-min=10.6" LDFLAGS="-L$TARGET_DIR/lib -lm" ./configure --arch=x86_64 --target-os=darwin --sysroot=/SDKs/MacOSX.platform/MacOSX10.6.sdk --enable-cross-compile --cc=clang --prefix=${OUTPUT_DIR:-$TARGET_DIR} --extra-version=static --disable-debug --disable-shared --enable-static --extra-cflags=--static --disable-ffplay --disable-ffserver --disable-doc --enable-gpl --enable-pthreads --enable-postproc --enable-gray --enable-runtime-cpudetect --enable-libfdk-aac --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-bzlib --enable-zlib --enable-nonfree --enable-version3 --disable-devices
make -j 4 && make install