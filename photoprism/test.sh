#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/photoprism
#${BUILD_DIR}/bin/darktable-cli.sh -v

useradd test
sudo -u test ${BUILD_DIR}/bin/darktable-cli.sh -v

#${BUILD_DIR}/bin/darktable-cli.sh test123.orf test.jpg --apply-custom-presets false --width 7680 --height 7680 --hq true --upscale false --core --library :memory:

