#!/bin/bash
#
# create_cfw.sh -- PS3 CFW creator
#
# Copyright (C) Youness Alaoui (KaKaRoTo)
#
# This software is distributed under the terms of the GNU General Public
# License ("GPL") version 3, as published by the Free Software Foundation.
#

BUILDDIR=$(pwd)
export PATH=$PATH:$BUILDDIR:$BUILDDIR/../ps3tools/

AWK="awk"
PUP="pup"
FIX_TAR="fix_tar"
PKG="pkg"
UNPKG="unpkg"
LOGFILE="$BUILDDIR/create_cfw.log"
OUTDIR="$BUILDDIR/CFW"
OFWDIR="$BUILDDIR/OFW"
USTARCMD="tar --format ustar -cvf"
INFILE=$1
OUTFILE=$2

if [ "x$INFILE" == "x" -o "x$OUTFILE" == "x" ]; then
    echo "Usage: $0 OFW.PUP CFW.PUP"
    exit
fi

patch_category_game_xml()
{
    log "Patching XML file"
    sed -i -e 's/src="sel:\/\/localhost\/welcome?type=game"/src="sel:\/\/localhost\/welcome?type=game"\r\n\t\t\t\t\/>\r\n\t\t\t<Query\r\n\t\t\t\tclass="type:x-xmb\/folder-pixmap"\r\n\t\t\t\tkey="seg_gamedebug"\r\n\t\t\t\tsrc="#seg_gamedebug"\r\n\t\t\t\t\/>\r\n\t\t\t<Query\r\n\t\t\t\tclass="type:x-xmb\/folder-pixmap"\r\n\t\t\t\tkey="seg_package_files"\r\n\t\t\t\tsrc="#seg_package_files"/' -e 's/<\/XMBML>/ \t<View id="seg_gamedebug">\r\n\t\t<Attributes>\r\n\t\t\t<Table key="game_debug">\r\n\t\t\t\t<Pair key="icon_rsc"><String>tex_album_icon<\/String><\/Pair>\r\n\t\t\t\t<Pair key="title_rsc"><String>msg_tool_app_home_ps3_game<\/String><\/Pair>\r\n\t\t\t\t<Pair key="child"><String>segment<\/String><\/Pair>\r\n\t\t\t<\/Table>\r\n\t\t<\/Attributes>\r\n\t\t<Items>\r\n\t\t\t<Query class="type:x-xcb\/game-debug" key="game_debug"  attr="game_debug" \/>\r\n\t\t<\/Items>\r\n\t<\/View>\r\n\r\n\t<View id="seg_package_files">\r\n\t\t<Attributes>\r\n\t\t\t<Table key="host_device">\r\n\t\t\t\t<Pair key="icon_rsc"><String>tex_album_icon<\/String><\/Pair>\r\n\t\t\t\t<Pair key="title_rsc"><String>msg_tool_install_file<\/String><\/Pair>\r\n\t\t\t\t<Pair key="child"><String>segment<\/String><\/Pair>\r\n\t\t\t\t<Pair key="ingame"><String>disable<\/String><\/Pair>\r\n\t\t\t<\/Table>\r\n\t\t<\/Attributes>\r\n\t\t<Items>\r\n\t\t\t<Query\r\n\t\t\t\tclass="type:x-xmb\/xmlpackagefolder"\r\n\t\t\t\tkey="host_device" attr="host_device"\r\n\t\t\t\tsrc="#seg_packages"\r\n\t\t\t\/>\r\n\t\t<\/Items>\r\n\t<\/View>\r\n\r\n\t<View id="seg_packages">\r\n\t\t<Items>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_host" src="host:\/\/localhost\/q?path=\/app_home\/\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_bdvd" src="host:\/\/localhost\/q?path=\/dev_bdvd\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_ms" src="host:\/\/localhost\/q?path=\/dev_ms\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_usb0" src="host:\/\/localhost\/q?path=\/dev_usb000\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_usb1" src="host:\/\/localhost\/q?path=\/dev_usb001\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_usb2" src="host:\/\/localhost\/q?path=\/dev_usb002\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_usb3" src="host:\/\/localhost\/q?path=\/dev_usb003\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_usb4" src="host:\/\/localhost\/q?path=\/dev_usb004\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_usb5" src="host:\/\/localhost\/q?path=\/dev_usb005\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_usb6" src="host:\/\/localhost\/q?path=\/dev_usb006\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t\t<Query class="type:x-xmb\/xmlpackagefolder" key="host_provider_usb7" src="host:\/\/localhost\/q?path=\/dev_usb007\&suffix=.pkg\&subclass=x-host\/package" \/>\r\n\t\t<\/Items>\r\n\t<\/View>\r\n\r\n<\/XMBML>\r\n/' dev_flash/vsh/resource/explore/xmb/category_game.xml || die "Could not copy file"

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

log "Deleting $OUTDIR and $OUTFILE"
rm -rf $OUTDIR
rm -f $OUTFILE
if [ "x$OFWDIR" != "x" ]; then
    rm -rf $OFWDIR
fi

log "Unpacking update file $INFILE"
$PUP x $INFILE $OUTDIR >> $LOGFILE 2>&1 || die "Could not extract the PUP file"

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

log "Searching for category_game.xml in dev_flash"
TAR_FILE=$(grep -l "category_game.xml" *.tar/content)
if [ "x$TAR_FILE" == "x" ]; then
    die "Could not find category_game.xml"
fi
log "Found xml file in $TAR_FILE"

tar -xvf $TAR_FILE >> $LOGFILE 2>&1 || die "Could not untar dev_flash file"

rm $TAR_FILE
patch_category_game_xml

log "Recreating dev_flash archive"
$USTARCMD $TAR_FILE dev_flash/ >> $LOGFILE 2>&1 || die "Could not create dev_flash tar file"
$FIX_TAR $TAR_FILE >> $LOGFILE 2>&1 || die "Could not fix the tar file"

PKG_FILE=$(basename $(dirname $TAR_FILE) .tar)
log "Recreating pkg file $PKG_FILE"
$PKG retail $(dirname $TAR_FILE) $PKG_FILE  >> $LOGFILE 2>&1 || die "Could not create pkg file"
mv $PKG_FILE $OUTDIR/update_files
cd $OUTDIR/update_files
rm -rf dev_flash

log "Creating update files archive"
$USTARCMD $OUTDIR/update_files.tar *.pkg *.img dev_flash3_* dev_flash_*  >> $LOGFILE 2>&1 || die "Could not create update files archive"
$FIX_TAR $OUTDIR/update_files.tar >> $LOGFILE 2>&1 || die "Could not fix update tar file"

VERSION=$(cat $OUTDIR/version.txt)
echo "$VERSION-KaKaRoTo" > $OUTDIR/version.txt

cd $BUILDDIR

log "Retreiving package build number"
BUILD_NUMBER=$($PUP i $INFILE 2>/dev/null | grep "Image version" | $AWK '{print $3}')

if [ "x$BUILD_NUMBER" == "x" ]; then
    die "Could not find build number"
fi

log "Found build number : $BUILD_NUMBER"

log "Creating CFW file"
$PUP c $OUTDIR $OUTFILE $BUILD_NUMBER >> $LOGFILE 2>&1 || die "Could not Create PUP file"


