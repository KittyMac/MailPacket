#! /bin/bash -

set -e

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

version=2.1.28
ARCHIVE=cyrus-sasl-$version
ARCHIVE_NAME=$ARCHIVE.tar.gz
ARCHIVE_PATCH=$ARCHIVE.patch
url=https://github.com/cyrusimap/cyrus-sasl/releases/download/$ARCHIVE/$ARCHIVE_NAME
parallel_mode=0

scriptdir="`pwd`"

current_dir="$scriptdir"
builddir="$current_dir/build/libsasl"
BUILD_TIMESTAMP=`date +'%Y%m%d%H%M%S'`
tempbuilddir="$builddir/workdir/$BUILD_TIMESTAMP"
mkdir -p "$tempbuilddir"
srcdir="$tempbuilddir/src"
logdir="$tempbuilddir/log"
resultdir="$builddir/builds"
tmpdir="$tempbuilddir/tmp"

BUILD="$(uname -m)"

mkdir -p "$resultdir"
mkdir -p "$logdir"
mkdir -p "$tmpdir"
mkdir -p "$srcdir"

if test -f "$resultdir/libsasl-$version-ios.tar.gz"; then
	echo already built
	cd "$scriptdir/.."
	tar xzf "$resultdir/libsasl-$version-ios.tar.gz"
	exit 0
fi

# download package file

if test -f "$current_dir/packages/$ARCHIVE_NAME" ; then
	:
else
	echo "download source package - $url"

	mkdir -p "$current_dir/packages"
  cd "$current_dir/packages"
	curl -L -O "$url"
	if test x$? != x0 ; then
		echo fetch of $ARCHIVE_NAME failed
		exit 1
	fi
fi

if [ ! -e "$current_dir/packages/$ARCHIVE_NAME" ]; then
    echo "Missing archive $ARCHIVE"
    exit 1
fi

echo "prepare sources"

cd "$srcdir"
tar -xzf "$current_dir/packages/$ARCHIVE_NAME"
if [ $? != 0 ]; then
    echo "Unable to decompress $ARCHIVE_NAME"
    exit 1
fi

logfile="$srcdir/$ARCHIVE/build.log"

echo "*** patching sources ***"

cd "$srcdir/$ARCHIVE"

# patch source files

cd "$srcdir/$ARCHIVE/include"
sed -E 's/\.\/\$< /.\/\$<'$BUILD' /' < Makefile.am > Makefile.am.new
mv Makefile.am.new Makefile.am
sed -E 's/\.\/\$< /.\/\$<'$BUILD' /' < Makefile.in > Makefile.in.new
mv Makefile.in.new Makefile.in
cd "$srcdir/$ARCHIVE/lib"
sed -E 's/\$\(AR\) cru \.libs\/\$@ \$\(SASL_STATIC_OBJS\)/&; \$\(RANLIB\) .libs\/\$@/' < Makefile.in > Makefile.in.new
mv Makefile.in.new Makefile.in

echo "building tools"
echo "*** generating makemd5 ***"

cd "$srcdir/$ARCHIVE"
export SDKROOT=
export IPHONEOS_DEPLOYMENT_TARGET=
./configure > "$logfile" 2>&1
if [[ "$?" != "0" ]]; then
  echo "CONFIGURE FAILED"
  exit 1
fi
cd include
make makemd5 >> "$logfile" 2>&1
if [[ "$?" != "0" ]]; then
  echo "BUILD FAILED"
  exit 1
fi
cd ..
echo generated makemd5$BUILD properly
mv "$srcdir/$ARCHIVE/include/makemd5" "$srcdir/$ARCHIVE/include/makemd5$BUILD"
make clean >>"$logfile" 2>&1
make distclean >>"$logfile" 2>&1
find . -name config.cache -print0 | xargs -0 rm

cd "$srcdir/$ARCHIVE"

export LANG=en_US.US-ASCII

LIB_NAME=$ARCHIVE
TARGETS="macosx iPhoneOS iPhoneSimulator"

SDK_IOS_MIN_VERSION=7.0
SDK_IOS_VERSION="`xcodebuild -showsdks 2>/dev/null | grep iphoneos | sed 's/.*iphoneos\(.*\)/\1/'`"
BUILD_DIR="$tmpdir/build"
INSTALL_PATH="${BUILD_DIR}/${LIB_NAME}/universal"
BITCODE_FLAGS="-fembed-bitcode"
if test "x$NOBITCODE" != x ; then
   BITCODE_FLAGS=""
fi

xcode_developer="$(xcode-select -p)"

function build_target {
  local current_logfile="$srcdir/$ARCHIVE-$TARGET-$MARCH/build.log"
  echo "log to $current_logfile"
  cp -R "$srcdir/$ARCHIVE" "$srcdir/$ARCHIVE-$TARGET-$MARCH"
  
  cd "$srcdir/$ARCHIVE-$TARGET-$MARCH"
  
  echo "*** building for $TARGET - $MARCH ***"

  if [[ $TARGET == "macosx" ]]; then
      local PREFIX=${BUILD_DIR}/${LIB_NAME}/${TARGET}${MARCH}
      rm -rf $PREFIX
      
      OPENSSL="--with-openssl=$BUILD_DIR/openssl-1.0.0d/universal"
      PLUGINS="--enable-otp=no --enable-digest=no --with-des=no --enable-login"
      ./configure --prefix=$PREFIX --enable-static=yes --disable-macos-framework --disable-dependency-tracking --disable-silent-rules $PLUGINS >> "$current_logfile" 2>&1
      
      make -j 8 >> "$current_logfile" 2>&1
      
      if [[ "$?" != "0" ]]; then
        echo "CONFIGURE FAILED"
        cat "$current_logfile"
        exit 1
      fi
  else
      local PREFIX=${BUILD_DIR}/${LIB_NAME}/${TARGET}${SDK_IOS_VERSION}${MARCH}
      rm -rf $PREFIX
  
      local CURRENT_TARGET="$MARCH-apple-ios${SDK_IOS_MIN_VERSION}${TARGET_SUFFIX}"
      export CPPFLAGS="-isysroot ${SYSROOT} -target ${CURRENT_TARGET} -Os"
      export CFLAGS="${CPPFLAGS} ${EXTRA_FLAGS}"
      export CC="$xcode_developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
      export CXX="$xcode_developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
      export LD="$xcode_developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld"
      export AR="$xcode_developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar"
  
      OPENSSL="--with-openssl=$BUILD_DIR/openssl-1.0.0d/universal"
      PLUGINS="--enable-otp=no --enable-digest=no --with-des=no --enable-login"
      ./configure --host=${ARCH} --prefix=$PREFIX --enable-shared=no --enable-static=yes --with-pam=$BUILD_DIR/openpam-20071221/universal $PLUGINS >> "$current_logfile" 2>&1
      
      make -j 8 >> "$current_logfile" 2>&1
      if [[ "$?" != "0" ]]; then
        echo "CONFIGURE FAILED"
        cat "$current_logfile"
        exit 1
      fi
  fi
  
  cd lib
  make install >> "$current_logfile" 2>&1
  cd ..
  cd include
  make install >> "$current_logfile" 2>&1
  cd ..
  cd plugins
  make install >> "$current_logfile" 2>&1
  
  cd ..
  if [[ "$?" != "0" ]]; then
    echo "BUILD FAILED"
    cat "$current_logfile"
  fi

  make clean >> "$current_logfile" 2>&1
  make distclean >> "$current_logfile" 2>&1
  find . -name config.cache -print0 | xargs -0 rm
}

pids=""
for TARGET in $TARGETS; do

    DEVELOPER="$(xcode-select --print-path)"
    SDK_ID="$(echo "$TARGET$SDK_IOS_VERSION" | tr A-Z a-z)"
    SYSROOT="$(xcodebuild -version -sdk "$SDK_ID" 2>/dev/null | egrep '^Path: ' | cut -d ' ' -f 2)"

    case $TARGET in
        (macosx)
            ARCH=arm
            MARCHS="arm64"
            EXTRA_FLAGS="$BITCODE_FLAGS"
            TARGET_SUFFIX=""
            ;;
        (iPhoneOS)
            ARCH=arm
            MARCHS="armv7 armv7s arm64"
            EXTRA_FLAGS="$BITCODE_FLAGS -miphoneos-version-min=$SDK_IOS_MIN_VERSION"
            TARGET_SUFFIX=""
            ;;
        (iPhoneSimulator)
            ARCH=i386
            MARCHS="i386 x86_64 arm64"
            EXTRA_FLAGS="$BITCODE_FLAGS -miphoneos-version-min=$SDK_IOS_MIN_VERSION"
            TARGET_SUFFIX="-simulator"
            ;;
    esac

    for MARCH in $MARCHS; do

        echo "building for $TARGET - $MARCH"
        build_target &
        pid="$!"
        pids="$pids $pid"
        if test "x$parallel_mode" != x1 ; then
          wait "$pid"
        fi
      done
done

if test "x$parallel_mode" = x1 ; then
  for pid in $pids; do
      wait $pid || exit 1
  done
fi

cd "$srcdir/$ARCHIVE"

echo "*** creating universal libs ***"

rm -rf "$INSTALL_PATH"
mkdir -p "$INSTALL_PATH"
mkdir -p "$INSTALL_PATH/lib"
mkdir -p "$INSTALL_PATH/include/sasl"
cp `find ./include -name '*.h'` "${INSTALL_PATH}/include/sasl"
ALL_LIBS="libsasl2.a sasl2/libanonymous.a sasl2/libcrammd5.a sasl2/libplain.a sasl2/libsasldb.a sasl2/liblogin.a"
for lib in $ALL_LIBS; do
    dir="`dirname $lib`"
    if [[ "$dir" != "." ]]; then
        mkdir -p ${INSTALL_PATH}/lib/$dir
    fi

    LIBS="${BUILD_DIR}/${LIB_NAME}/macosx*/lib/${lib}"
    output="${INSTALL_PATH}/lib/macosx/${lib}"
    mkdir -p "$(dirname "$output")"
    lipo -create ${LIBS} -output "$output"

    LIBS="${BUILD_DIR}/${LIB_NAME}/iPhoneOS${SDK_IOS_VERSION}*/lib/${lib}"
    output="${INSTALL_PATH}/lib/iphoneos/${lib}"
    mkdir -p "$(dirname "$output")"
    lipo -create ${LIBS} -output "$output"

    LIBS="${BUILD_DIR}/${LIB_NAME}/iPhoneSimulator${SDK_IOS_VERSION}*/lib/${lib}"
    output="${INSTALL_PATH}/lib/iphonesimulator/${lib}"
    mkdir -p "$(dirname "$output")"
    lipo -create ${LIBS} -output "$output"
done

echo "*** creating built package ***"

cd "$BUILD_DIR"
cp -r "$INSTALL_PATH"/* ./libsasl/

#cp -r "$INSTALL_PATH"/* libsasl.bin/
#tar -czf "libsasl-$version-ios.tar.gz" libsasl.bin
#mkdir -p "$resultdir"
#mv "libsasl-$version-ios.tar.gz" "$resultdir"
#cd "$resultdir"
#ln -s "libsasl-$version-ios.tar.gz" "libsasl-prebuilt-ios.tar.gz"

#cd "$scriptdir/.."
#tar xzf "$resultdir/libsasl-$version-ios.tar.gz"

exit 0
