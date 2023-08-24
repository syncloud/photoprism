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
apt-get update
apt-get -qq install wget git
git clone https://github.com/cyberb/photoprism.git
cd photoprism
make docker-build
docker compose up
make terminal
make dep
#make build-js
make build-go