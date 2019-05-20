#!/bin/bash


# Make the working directory
mkdir curl-android-build
cd curl-android-build
ROOT_DIR=`pwd -P`
echo Building curl for Android in $ROOT_DIR

OUTPUT_DIR=$ROOT_DIR/output
mkdir $OUTPUT_DIR


echo "Starting..."
echo "==================================================="


OUTPUT_DIR=$ROOT_DIR/libcurl-android
mkdir $OUTPUT_DIR

# Download and build zlib
mkdir -p $OUTPUT_DIR/zlib/lib/armeabi-v7a
mkdir -p $OUTPUT_DIR/zlib/include
ZLIB_DIR=$ROOT_DIR/zlib-1.2.8


if [ ! -e "zlib-1.2.8" ]; then

echo "downloading ZLIB..."
wget http://zlib.net/fossils/zlib-1.2.8.tar.gz
tar -xvzf zlib-1.2.8.tar.gz

else
echo "SKIPping downloading zlib. already exists."
fi

cd $ZLIB_DIR
./configure --static
make

# Copy zlib lib and includes to output directory
echo output directory=${OUTPUT_DIR}/zlib
cp libz.a $OUTPUT_DIR/zlib/lib/armeabi-v7a/
cp zconf.h $OUTPUT_DIR/zlib/include/ 
cp zlib.h $OUTPUT_DIR/zlib/include/
cd ..


echo "zLib build COMPLETE"
echo "==================================================="

# Download NDK

NDK_NAME="crystax-ndk-10.3.0"

if [ ! -e $NDK_NAME ]; then

echo "downloading NDK..."

wget https://www.crystax.net/download/crystax-ndk-10.3.0-linux-x86_64.tar.xz
tar -xvf crystax-ndk-10.3.0-linux-x86_64.tar.xz

else
echo "skipping downloading NDK. already exists."
fi


# NDK environment variables

export NDK_ROOT=$ROOT_DIR/$NDK_NAME
export PATH=$PATH:$NDK_ROOT

# Create standalone toolchain for cross-compiling
$NDK_ROOT/build/tools/make-standalone-toolchain.sh --arch=arm --system=linux-x86_64 --platform=android-9 --install-dir=ndk-standalone-toolchain
TOOLCHAIN=$ROOT_DIR/ndk-standalone-toolchain

echo "NDK build COMPLETE"
echo "==================================================="

# Download and build openssl

if [ ! -e "openssl-1.0.2d" ]; then

echo "downloading OpenSSL..."
wget https://www.openssl.org/source/old/1.0.2/openssl-1.0.2d.tar.gz
tar -xvf openssl-1.0.2d.tar.gz 

else
echo "SKIPping downloading openssl. already exists."
fi

# Setup cross-compile environment
# export CROSS_COMPILE="arm-linux-androideabi-"

: << 'no_'

export CC=arm-linux-androideabi-gcc
export CXX=arm-linux-androideabi-g++
export AR=arm-linux-androideabi-ar
export AS=arm-linux-androideabi-as
export LD=arm-linux-androideabi-ld
export RANLIB=arm-linux-androideabi-ranlib
export NM=arm-linux-androideabi-nm
export STRIP=arm-linux-androideabi-strip
export CHOST="arm-linux-androideabi"

export CXXFLAGS="-std=libc++14"
export CPPFLAGS="-mthumb -mfloat-abi=softfp -mfpu=vfp -march=${ARCH}  -DANDROID"

no_

export CC=$TOOLCHAIN/bin/arm-linux-androideabi-gcc
export SYSROOT=$TOOLCHAIN/sysroot
export PATH=$PATH:$TOOLCHAIN/bin:$TOOLCHAIN/arm-linux-androideabi/bin
export ARCH=armv7

ls $TOOLCHAIN/bin

echo "Cross Compiler environment setup COMPLETE"
echo "==================================================="

# : << 'COMMENT'

cd openssl-1.0.2d/
./Configure android-armv7 no-asm -mfloat-abi=softfp --sysroot=$NDK_ROOT/platforms/android-9/arch-arm --with-zlib-include=${ZLIB_DIR}/include --with-zlib-lib=${ZLIB_DIR}/lib
make build_crypto build_ssl

echo "---------------------------- SSL and CRYPTO build complete----------------------"

# Copy openssl lib and includes to output directory
mkdir -p $OUTPUT_DIR/openssl/lib/armeabi-v7a
mkdir $OUTPUT_DIR/openssl/include
cp libssl.a $OUTPUT_DIR/openssl/lib/armeabi-v7a
cp libcrypto.a $OUTPUT_DIR/openssl/lib/armeabi-v7a
cp -LR include/openssl $OUTPUT_DIR/openssl/include
cd ..
OPENSSL_DIR=$ROOT_DIR/openssl-1.0.2d

# COMMENT


echo "OpenSSL build COMPLETE"
echo "==================================================="


# Download and build libcurl
if [ ! -e "curl-7.45.0" ]; then

echo "downloading cURL..."
wget -nc http://curl.haxx.se/download/curl-7.45.0.tar.gz
tar -xvf curl-7.45.0.tar.gz 

else
echo "skipping downloading crul. already exists."

fi

cd curl-7.45.0
export CFLAGS="-v --sysroot=$SYSROOT -mandroid -march=$ARCH -mfloat-abi=softfp -mfpu=vfp -mthumb"
export CPPFLAGS="$CFLAGS -DANDROID -DCURL_STATICLIB -mthumb -mfloat-abi=softfp -mfpu=vfp -march=$ARCH -I${OPENSSL_DIR}/include/ -I${TOOLCHAIN}/include"
export LDFLAGS="-march=$ARCH -Wl,--fix-cortex-a8 -L${OPENSSL_DIR}"
./configure --host=arm-linux-androideabi --disable-shared --enable-static --disable-dependency-tracking --with-zlib=${ZLIB_DIR} --with-ssl=${OPENSSL_DIR} --without-ca-bundle --without-ca-path --enable-ipv6 --enable-http --enable-ftp --disable-file --disable-ldap --disable-ldaps --disable-rtsp --disable-proxy --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-sspi --disable-manual --target=arm-linux-androideabi --prefix=/opt/curlssl 
make

# Copy libcurl and includes to output directory
mkdir -p $OUTPUT_DIR/curl/lib/armeabi-v7a
mkdir $OUTPUT_DIR/curl/include
cp lib/.libs/libcurl.a $OUTPUT_DIR/curl/lib/armeabi-v7a
cp -LR include/curl $OUTPUT_DIR/curl/include
cd ..

echo "CURL build COMPLETE"
echo "==================================================="


echo Build result saved to $ROOT_DIR/$OUTPUT_DIR


echo "Done"
echo "==================================================="

