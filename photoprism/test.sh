#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/photoprism
${BUILD_DIR}/bin/darktable-cli.sh --help


