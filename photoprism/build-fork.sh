#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
apk add git make bash
git clone https://github.com/cyberb/photoprism.git
cd photoprism
make all install DESTDIR=/opt/photoprism
#make docker-build
#docker compose up
#make terminal
#make dep
#make build-js
#make build-go