#!/bin/bash
# Copyright 2019 The Hush Developers
# Usage: ./zcutil/build-debian-package.sh

set -e
set -x

BUILD_PATH="/tmp/hush"
PACKAGE_NAME="hush"
SRC_PATH=`pwd`
SRC_DEB=$SRC_PATH/contrib/debian
SRC_DOC=$SRC_PATH/doc

umask 022

if [ ! -e "./src/komodod" ]; then
	echo "No komodod found!"
	echo "Make sure to run ./build.sh before running $0"
	exit 1
fi

if [ ! -e "./src/komodo-cli" ]; then
	echo "No komodo-cli found!"
	echo "Make sure to run ./build.sh before running $0"
	exit 1
fi

if [ ! -d $BUILD_PATH ]; then
    echo "Creating $BUILD_PATH"
    mkdir $BUILD_PATH
fi

#PACKAGE_VERSION=$($SRC_PATH/src/hushd --version | grep version | cut -d' ' -f4 | tr -d v)
PACKAGE_VERSION=3.1.0

##
DEBVERSION=$(echo $PACKAGE_VERSION | sed 's/-beta/~beta/' | sed 's/-rc/~rc/' | sed 's/-/+/')
BUILD_DIR="$BUILD_PATH/$PACKAGE_NAME-$PACKAGE_VERSION-amd64"

if [ -e "$PACKAGE_NAME-$PACKAGE_VERSION-amd64.deb "]; then
	echo "Backing up previous build"
	cp $PACKAGE_NAME-$PACKAGE_VERSION-amd64.deb $PACKAGE_NAME-$PACKAGE_VERSION-amd64.deb.bak
fi

if [ -d $BUILD_DIR ]; then
    echo "Removing $BUILD_DIR"
    rm -R $BUILD_DIR
fi

DEB_BIN=$BUILD_DIR/usr/bin
DEB_CMP=$BUILD_DIR/usr/share/bash-completion/completions
DEB_DOC=$BUILD_DIR/usr/share/doc/$PACKAGE_NAME
DEB_MAN=$BUILD_DIR/usr/share/man/man1
DEB_SHR=$BUILD_DIR/usr/share/hush
mkdir -p $BUILD_DIR/DEBIAN $DEB_CMP $DEB_BIN $DEB_DOC $DEB_MAN $DEB_SHR
chmod 0755 -R $BUILD_DIR/*

# Package maintainer scripts (currently empty)
#cp $SRC_DEB/postinst $BUILD_DIR/DEBIAN
#cp $SRC_DEB/postrm $BUILD_DIR/DEBIAN
#cp $SRC_DEB/preinst $BUILD_DIR/DEBIAN
#cp $SRC_DEB/prerm $BUILD_DIR/DEBIAN

# Copy binaries
cp $SRC_PATH/src/komodod $DEB_BIN/hush-komodod
strip $DEB_BIN/hush-komodod
cp $SRC_PATH/src/komodo-cli $DEB_BIN/hush-komodo-cli
strip $DEB_BIN/hush-komodo-cli
cp $SRC_PATH/src/komodo-tx $DEB_BIN/hush-komodo-tx
strip $DEB_BIN/hush-komodo-tx
cp $SRC_PATH/src/hushd $DEB_BIN
cp $SRC_PATH/src/hush-cli $DEB_BIN
cp $SRC_PATH/src/hush-tx $DEB_BIN
cp $SRC_PATH/sapling-output.params $DEB_SHR
cp $SRC_PATH/sapling-spend.params $DEB_SHR

# Docs
#cp $SRC_PATH/doc/release-notes/release-notes-1.0.0.md $DEB_DOC/changelog
cp $SRC_PATH/contrib/debian/changelog $DEB_DOC
#cp $SRC_DEB/changelog $DEB_DOC/changelog.Debian
cp $SRC_DEB/copyright $DEB_DOC
cp -r $SRC_DEB/examples $DEB_DOC

# Manpages
cp $SRC_DOC/man/komodod.1 $DEB_MAN/hushd.1
cp $SRC_DOC/man/komodo-cli.1 $DEB_MAN/hush-cli.1
cp $SRC_DOC/man/komodo-tx.1 $DEB_MAN/hush-tx.1
# prevents warnings about binaries without manpages
cp $SRC_DOC/man/komodod.1 $DEB_MAN/hush-komodod.1
cp $SRC_DOC/man/komodo-cli.1 $DEB_MAN/hush-komodo-cli.1
cp $SRC_DOC/man/komodo-tx.1 $DEB_MAN/hush-komodo-tx.1

# Copy bash completion files
cp $SRC_PATH/contrib/hushd.bash-completion $DEB_CMP/hushd
cp $SRC_PATH/contrib/hush-cli.bash-completion $DEB_CMP/hush-cli
# Gzip files
gzip --best -n $DEB_DOC/changelog
#gzip --best -n $DEB_DOC/changelog.Debian
gzip --best -n $DEB_MAN/hushd.1
gzip --best -n $DEB_MAN/hush-cli.1
gzip --best -n $DEB_MAN/hush-tx.1
gzip --best -n $DEB_MAN/hush-komodod.1
gzip --best -n $DEB_MAN/hush-komodo-cli.1
gzip --best -n $DEB_MAN/hush-komodo-tx.1

cd $SRC_PATH/contrib

# Create the control file
dpkg-shlibdeps $DEB_BIN/hush-komodod $DEB_BIN/hush-komodo-cli
dpkg-gencontrol -P$BUILD_DIR -v$DEBVERSION

echo "Creating the Debian package"
fakeroot dpkg-deb --build $BUILD_DIR
cp $BUILD_PATH/$PACKAGE_NAME-$PACKAGE_VERSION-amd64.deb $SRC_PATH
# Analyze with Lintian, reporting bugs and policy violations
lintian -i $SRC_PATH/$PACKAGE_NAME-$PACKAGE_VERSION-amd64.deb
exit 0
