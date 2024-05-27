#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/sqlite
ls -la ${DIR}/../
mkdir -p ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
mkdir ${BUILD_DIR}/bin
cp ${DIR}/sqlite.sh ${BUILD_DIR}/bin
