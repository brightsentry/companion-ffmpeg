#!/bin/sh

##############################################################################
# script to build ffmpeg on mac osx for i386, armv7 and armv7s
##############################################################################

#settings
archs=("armv7" "armv7s" "i386")
sdk="6.1"
minsdk="6.0"
##############################################################################

# get the pkg-config utility - this is commented out because it is not seemingly needed in the version of mac osx this
# script was written on (10.7.5),but we include the code to compile here just in case
#  BuildDir=`pwd`
#  git clone git://anongit.freedesktop.org/pkg-config 
#  cd ${BuildDir}/pkg-config
#  ./configure --prefix=${BuildDir}
#  make
#  make install
#  export PKG_CONFIG=${BuildDir}/bin/pkg-config
#  export PKG_CONFIG_PATH=${BuildDir}/lib/pkgconfig

#proceed only if the libs directory is composed of only the README file
if [ `ls libs/* | wc -l` -lt 2 ]
then 

currDir=`pwd`
cd ffmpeg
ffmpegDir=`pwd`

#create directories for different achitectures 
mkdir -p armv7
mkdir -p armv7s
mkdir -p i386

#install the preprocessor if necessary
if [ ! -f /usr/bin/gas-preprocessor.pl ]
then
    echo "installing gas-preprocessor.pl to /usr/bin"
    sudo cp OSXutils/gas-preprocessor.pl /usr/bin/
    sudo chmod 775 /usr/bin/gas-preprocessor.pl
fi

for arch in "${archs[@]}"
do
    #remove existing libs and includes
    rm -rf $arch/*

    #run configure
    echo "running ffmpeg configure for architecture ${arch}"

    if [ "$arch" == "i386" ]
    then
	./configure \
	    --prefix=$arch \
	    --disable-ffmpeg \
	    --disable-ffplay \
	    --disable-ffprobe \
	    --disable-ffserver \
	    --enable-avresample \
	    --enable-cross-compile \
	    --sysroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${sdk}.sdk" \
	    --target-os=darwin \
	    --cc="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/gcc" \
	    --extra-cflags="-arch ${arch}" \
	    --extra-ldflags="-arch ${arch} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${sdk}.sdk" \
	    --arch=$arch \
	    --cpu=$arch \
	    --enable-pic \
	    --disable-asm \
	    
    else
	./configure \
	    --prefix=$arch \
	    --disable-ffmpeg \
	    --disable-ffplay \
	    --disable-ffprobe \
	    --disable-ffserver \
	    --enable-avresample \
	    --enable-cross-compile \
	    --sysroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${sdk}.sdk" \
	    --target-os=darwin \
	    --cc="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc" \
	    --extra-cflags="-arch ${arch} -mfpu=neon -miphoneos-version-min=${minsdk}" \
	    --extra-ldflags="-arch ${arch} -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${sdk}.sdk -miphoneos-version-min=${minsdk}" \
	    --arch=arm \
	    --cpu=cortex-a9 \
	    --enable-pic \
	    
    fi
    
    #build the project - for some reason xcode doesnt like these linking with &&
    make clean 
    make 
    make install
done

#create a universal lib with all these different architectures put inside
echo "creating universal library"
cd ${archs[0]}/lib
for file in *.a
do
    cd $ffmpegDir
    cmndStr="";    
    for arch in "${archs[@]}"
    do
	cmndStr="$cmndStr -arch ${arch} ${arch}/lib/$file"
    done

    xcrun -sdk iphoneos lipo -output $currDir/libs/$file -create $cmndStr
    echo "Universal $file created."
done

#get back to where we started
cd $currDir

#end main if
fi

exit 0