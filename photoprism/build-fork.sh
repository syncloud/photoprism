#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap/photoprism

UPSTREAM_TAG=260305-fad9d5395

cd ${DIR}
wget --progress=dot:giga https://github.com/photoprism/photoprism/archive/refs/tags/${UPSTREAM_TAG}.tar.gz
tar xf ${UPSTREAM_TAG}.tar.gz
mv photoprism-${UPSTREAM_TAG} photoprism-src

cd photoprism-src
patch -p1 < ${DIR}/ldap-webdav.patch
make dep-tensorflow
make build-go

cp photoprism ${BUILD_DIR}/opt/photoprism/bin/photoprism
