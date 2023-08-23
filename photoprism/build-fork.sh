#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
apt update
apt install -y wget
wget https://github.com/cyberb/photoprism/archive/refs/heads/develop.tar.gz
tar xf develop.tar.gz
cd photoprism-develop
make terminal
make dep
make build-go
