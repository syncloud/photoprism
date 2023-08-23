#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
export DEBIAN_FRONTEND="noninteractive"
echo 'APT::Acquire::Retries "3";' > /etc/apt/apt.conf.d/80retries
echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/80recommends
echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf.d/80suggests
echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/80forceyes
echo 'APT::Get::Fix-Missing "true";' > /etc/apt/apt.conf.d/80fixmissing
echo 'force-confold' > /etc/dpkg/dpkg.cfg.d/force-confold
apt-get update && apt-get -qq upgrade
apt-get -qq install \
    libc6 ca-certificates bash sudo nano avahi-utils jq lsof lshw \
    exiftool sqlite3 tzdata gpg make zip unzip wget curl rsync \
    imagemagick libvips-dev rawtherapee ffmpeg libavcodec-extra x264 x265 libde265-dev \
    libaom3 libvpx7 libwebm1 libjpeg8 libmatroska7 libdvdread8 libebml5 libgav1-bin libatomic1
wget --progress=dot:giga https://github.com/cyberb/photoprism/archive/refs/heads/develop.tar.gz
tar xf develop.tar.gz
cd photoprism-develop
make terminal
make dep
make build-go
