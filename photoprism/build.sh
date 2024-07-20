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
#cp -r /lib64 ${BUILD_DIR} || true

cp ${DIR}/photoprism.sh ${BUILD_DIR}/bin/
cp ${DIR}/darktable-cli.sh ${BUILD_DIR}/bin/
cp ${DIR}/ffmpeg.sh ${BUILD_DIR}/bin/
cd ${BUILD_DIR}
ln -s lib/*-linux*/ld-*.so* ld.so