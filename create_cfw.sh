#!/bin/bash
#
# create_cfw.sh -- PS3 CFW creator
#
# Copyright (C) Youness Alaoui (KaKaRoTo)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

BUILDDIR=`pwd`
export PATH=$PATH:$BUILDDIR:$BUILDDIR/../ps3tools/

AWK="awk"
PUP="pup"
FIX_TAR="fix_tar"
PKG="pkg"
UNPKG="unpkg"
LOGFILE="$BUILDDIR/create_cfw.log"
OUTDIR="$BUILDDIR/CFW"
OFWDIR="$BUILDDIR/OFW"



if [ "x$1" == "x" -o "x$2" == "x" ]; then
    echo "Usage: $0 OFW.PUP CFW.PUP"
    exit
fi

copy_category_tool_xml()
{
    log "Replacing XML file"
    cp dev_flash/vsh/resource/explore/xmb/category_game_tool2.xml dev_flash/vsh/resource/explore/xmb/category_game.xml || die "Could not copy file"
}

die()
{
    log "$@"
    exit 1
}

log ()
{
    echo "$@"
    echo "$@" >> $LOGFILE
}
echo > $LOGFILE
log "PS3 Custom Firmware Creator"
log "By KaKaRoTo"
log ""

log "Deleting $OUTDIR and $2"
rm -rf $OUTDIR
rm -f $2
if [ "x$OFWDIR" != "x" ]; then
    rm -rf $OFWDIR
fi

log "Unpacking update file $1"
$PUP x $1 $OUTDIR >> $LOGFILE 2>&1 || die "Could not extract the PUP file"

cd $OUTDIR
mkdir update_files
cd update_files
log "Extracting update files from unpacked PUP"
tar -xvf $OUTDIR/update_files.tar  >> $LOGFILE 2>&1 || die "Could not untar the update files"

if [ "x$OFWDIR" != "x" ]; then
    log "Copying firmware to $OFWDIR"
    cd $BUILDDIR
    cp -r $OUTDIR $OFWDIR
    cd $OUTDIR/update_files
fi

mkdir dev_flash
cd dev_flash
log "Unpkg-ing dev_flash files"
for f in ../dev_flash*tar*; do
    $UNPKG $f "$(basename $f).tar" >> $LOGFILE 2>&1 || die "Could not unpkg $f"
done

log "Searching for category_game_tool2.xml in dev_flash"
TAR_FILE=$(grep -l "category_game_tool2.xml" *.tar/content)
if [ "x$TAR_FILE" == "x" ]; then
    die "Could not find category_game_tool2.xml"
fi
log "Found xml file in $TAR_FILE"

tar -xvf $TAR_FILE >> $LOGFILE 2>&1 || die "Could not untar dev_flash file"

rm $TAR_FILE
copy_category_tool_xml

log "Recreating dev_flash archive"
tar -H ustar -cvf $TAR_FILE dev_flash/ >> $LOGFILE 2>&1 || die "Could not create dev_flash tar file"
$FIX_TAR $TAR_FILE >> $LOGFILE 2>&1 || die "Could not fix the tar file"

PKG_FILE=$(basename $(dirname $TAR_FILE) .tar)
log "Recreating pkg file $PKG_FILE"
$PKG retail $(dirname $TAR_FILE) $PKG_FILE  >> $LOGFILE 2>&1 || die "Could not create pkg file"
mv $PKG_FILE $OUTDIR/update_files
cd $OUTDIR/update_files
rm -rf dev_flash

log "Retreiving package build number"
BUILD_NUMBER=$($PUP i $1 2>/dev/null | grep "Image version" | $AWK '{print $3}')

if [ "x$BUILD_NUMBER" == "x" ]; then
    die "Could not find build number"
fi

log "Found build number : $BUILD_NUMBER"

log "Creating update files archive"
tar -H ustar -cvf $OUTDIR/update_files.tar *.pkg *.img dev_flash3_* dev_flash_*  >> $LOGFILE 2>&1 || die "Could not create update files archive"
$FIX_TAR $OUTDIR/update_files.tar >> $LOGFILE 2>&1 || die "Could not fix update tar file"

VERSION=$(cat $OUTDIR/version.txt)
echo "$VERSION-KaKaRoTo" > $OUTDIR/version.txt

cd $BUILDDIR

log "Creating CFW file"
$PUP c $OUTDIR $2 $BUILD_NUMBER >> $LOGFILE 2>&1 || die "Could not Create PUP file"


