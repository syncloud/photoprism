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
cp lib/*-linux*/ld-*.so* ${BUILD_DIR}/lib/ld.so
ls -la