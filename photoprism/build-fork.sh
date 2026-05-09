#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap/photoprism

cd ${DIR}
wget --progress=dot:giga https://github.com/photoprism/photoprism/archive/refs/heads/develop.tar.gz
tar xf develop.tar.gz
mv photoprism-develop photoprism-src

cd photoprism-src
patch -p1 < ${DIR}/ldap-webdav.patch
make dep-tensorflow
make build-go

cp photoprism ${BUILD_DIR}/opt/photoprism/bin/photoprism
