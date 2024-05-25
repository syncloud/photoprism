#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
wget --progress=dot:giga https://github.com/cyberb/photoprism/archive/refs/heads/upstream.tar.gz
tar xf develop.tar.gz
cd photoprism-develop
make dep-tensorflow
make build-go
