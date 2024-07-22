#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
BRANCH=develop
#BRANCH=debug
wget --progress=dot:giga https://github.com/cyberb/photoprism/archive/refs/heads/$BRANCH.tar.gz
tar xf $BRANCH.tar.gz
mv photoprism-$BRANCH photoprism-fork
cd photoprism-fork
make dep-tensorflow
make build-go

BUILD_DIR=${DIR}/../build/snap/photoprism
cp ${DIR}/photoprism-fork/photoprism ${BUILD_DIR}/opt/photoprism/bin/photoprism
