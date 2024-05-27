#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
wget --progress=dot:giga https://github.com/cyberb/photoprism/archive/refs/heads/develop.tar.gz
tar xf develop.tar.gz
mv photoprism-develop photoprism-fork
cd photoprism-fork
make dep-tensorflow
make build-go
