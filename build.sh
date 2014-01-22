#!/bin/sh

set -e
set -u

usage() { echo "Usage: $0 [-f]" 1>&2; echo; exit 1; }
free=""

while getopts "f" o; do
    case "${o}" in
        f)
            free=1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

jval=4
if [[ $free == "1" ]]; then
	freeopts=""
else
	freeopts="--enable-nonfree --enable-libfdk-aac"
fi

cd `dirname $0`
ENV_ROOT="$PWD"
BUILD_DIR="${ENV_ROOT}/build"
TARGET_DIR="${ENV_ROOT}/target"

rm -rf "$BUILD_DIR" "$TARGET_DIR"
mkdir -p "$BUILD_DIR" "$TARGET_DIR"

# NOTE: this is a fetchurl parameter, nothing to do with the current script
#export TARGET_DIR_DIR="$BUILD_DIR"

export LDFLAGS="-L${TARGET_DIR}/lib"
export DYLD_LIBRARY_PATH="${TARGET_DIR}/lib"
export PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig"
export CFLAGS="-I${TARGET_DIR}/include -mmacosx-version-min=10.6 $LDFLAGS"
export PATH="${TARGET_DIR}/bin:${PATH}"

echo "#### FFmpeg static build, by STVS SA ####"
cd $BUILD_DIR
../fetchurl "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz"
../fetchurl "http://zlib.net/zlib-1.2.8.tar.gz"
../fetchurl "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz"
../fetchurl "http://downloads.sf.net/project/libpng/libpng15/older-releases/1.5.14/libpng-1.5.14.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/ogg/libogg-1.3.1.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2"
../fetchurl "http://webm.googlecode.com/files/libvpx-v1.1.0.tar.bz2"
../fetchurl "http://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-0.1.0.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fopencore-amr%2Ffiles%2Ffdk-aac%2F&ts=1352301762&use_mirror=iweb"
../fetchurl "ftp://ftp.videolan.org/pub/x264/snapshots/last_x264.tar.bz2"
../fetchurl "http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.gz"
../fetchurl "http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz"
../fetchurl "http://www.ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2"

echo "*** Building yasm ***"
cd $BUILD_DIR/yasm*
./configure --prefix=${TARGET_DIR} && \
make -j $jval && \
make install

echo "*** Building zlib ***"
cd $BUILD_DIR/zlib*
./configure --prefix=${TARGET_DIR} && \
make -j $jval && \
make install

echo "*** Building bzip2 ***"
cd $BUILD_DIR/bzip2*
make && \
make install PREFIX=${TARGET_DIR}

echo "*** Building libpng ***"
cd $BUILD_DIR/libpng*
./configure --prefix=${TARGET_DIR} --enable-static --disable-shared && \
make -j $jval && \
make install

# Ogg before vorbis
echo "*** Building libogg ***"
cd $BUILD_DIR/libogg*
./configure --prefix=${TARGET_DIR} --enable-static --disable-shared && \
make -j $jval && \
make install

# Vorbis before theora
echo "*** Building libvorbis ***"
cd $BUILD_DIR/libvorbis*
./configure --prefix=${TARGET_DIR} --with-ogg-libraries=${TARGET_DIR}/lib --with-ogg-includes=${TARGET_DIR}/include/ --enable-static --disable-shared && \
make -j $jval && \
make install

echo "*** Building libtheora ***"
cd $BUILD_DIR/libtheora*
./configure --prefix=${TARGET_DIR} --with-ogg-libraries=${TARGET_DIR}/lib --with-ogg-includes=${TARGET_DIR}/include/ --with-vorbis-libraries=${TARGET_DIR}/lib --with-vorbis-includes=${TARGET_DIR}/include/ --enable-static --disable-shared && \
make -j $jval && \
make install

echo "*** Building livpx ***"
cd $BUILD_DIR/libvpx*
./configure --prefix=${TARGET_DIR} --disable-unit-tests --disable-shared && \
make -j $jval && \
make install

if [[ $free == "" ]]; then
	echo "*** Building fdk-aac ***"
	cd "$BUILD_DIR/fdk-aac-0.1.0"
	./configure --prefix=${TARGET_DIR} --enable-static --disable-shared && \
	make -j 4 && \
	make install
fi

echo "*** Building x264 ***"
cd $BUILD_DIR/x264*
./configure --prefix=${TARGET_DIR} --enable-static --disable-shared && \
make -j $jval && \
make install

echo "*** Building xvidcore ***"
cd "$BUILD_DIR/xvidcore/build/generic"
./configure --prefix=${TARGET_DIR} --enable-static --disable-shared && \
make -j $jval && \
make install
#rm ${TARGET_DIR}/lib/libxvidcore.so.*

echo "*** Building lame ***"
cd $BUILD_DIR/lame*
./configure --prefix=${TARGET_DIR} --enable-static --disable-shared && \
make -j $jval && \
make install

echo "*** Building opus ***"
cd $BUILD_DIR/opus*
./configure --prefix=${TARGET_DIR} --enable-static --disable-shared && \
make -j $jval && \
make install

rm -f "${TARGET_DIR}/lib/*.dylib"
rm -f "${TARGET_DIR}/lib/*.so"

# FFMpeg
echo "*** Building FFmpeg ***"
cd $BUILD_DIR/ffmpeg*
export LDFLAGS="-L${TARGET_DIR}/lib" 
export CFLAGS="-I${TARGET_DIR}/include" 
./configure --prefix=${TARGET_DIR} --arch=x86_64 --disable-debug --disable-shared --enable-static --enable-runtime-cpudetect --enable-gpl --enable-version3 \
--disable-ffplay --disable-ffserver --disable-doc  --enable-pthreads --enable-postproc \
--enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-bzlib --enable-zlib --enable-libvpx $freeopts && \
make -j $jval && \
make install

echo "*** Building x264 ***"
cd $BUILD_DIR/x264*
make distclean
CFLAGS="-I${TARGET_DIR}/include" LDFLAGS="-L${TARGET_DIR}/lib -framework CoreFoundation -framework CoreVideo -framework VideoDecodeAcceleration" ./configure --prefix=${TARGET_DIR} --enable-static --disable-shared --disable-avs --disable-opencl && \
make -j $jval && \
make install