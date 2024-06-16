#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/mariadb
mkdir -p ${BUILD_DIR}

cp -r /usr ${BUILD_DIR}/usr
cp ${DIR}/bin/* ${BUILD_DIR}/usr/bin

