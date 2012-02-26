#!/bin/bash

# Need absolute paths for most of this or else APT path mangling will 
# add extra prefixes

SYSDIR="/home/jman/code/deb-sysverify/test/"
WORKDIR="/home/jman/code/deb-sysverify/workdir/"

SRC_APT_ETC="$SYSDIR/etc/apt/"
SRC_DPKG_VAR="$SYSDIR/var/lib/dpkg/"

DPKG_TMPDIR="$WORKDIR/tmp-apt/var/lib/dpkg/"
DPKG_TMPSTATUS="$WORKDIR/tmp-apt/var/lib/dpkg/status"
APT_TMPDIR="$WORKDIR/tmp-apt/var/lib/apt/"
APT_CACHEDIR="$WORKDIR/tmp-apt/var/cache/apt/"
TMPROOT="$WORKDIR/test-root/"

mkdir -p "$DPKG_TMPDIR"
touch "$DPKG_TMPSTATUS"
mkdir -p "$APT_TMPDIR/lists"
mkdir -p "$APT_TMPDIR/lists/partial"
mkdir -p "$APT_CACHEDIR/archives/partial"

APT_OPTS="-o Dir::Etc=$SRC_APT_ETC 
          -o Dir::State=$APT_TMPDIR
          -o Dir::State::status=$DPKG_TMPSTATUS
          -o Dir::Cache=$APT_CACHEDIR
          --no-install-recommends"

DPKGLIST=$(dpkg --admindir=$SRC_DPKG_VAR -l)
PKGS=$(echo "$DPKGLIST" | grep "^ii" | awk '{print $2}')
PKGSVERS=$(echo "$DPKGLIST" | grep "^ii" | awk '{printf "%s=%s ",$2,$3}')

echo "$PKGS"

apt-get $APT_OPTS update
apt-get $APT_OPTS -d install $PKGS

for pkg in $PKGS; do
    echo "Extracting $pkg to test-root/"
    dpkg --extract "$APT_CACHEDIR"/archives/${pkg}_*.deb $TMPROOT
done

