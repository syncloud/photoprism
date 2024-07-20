#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap/photoprism
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

cp -r /bin ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
cp -r /opt ${BUILD_DIR}
#cp -r /lib64 ${BUILD_DIR} || true

cp -r ${DIR}/bin/* ${BUILD_DIR}/bin
cd ${BUILD_DIR}
ln -s lib/*-linux*/ld-*.so* ld.so