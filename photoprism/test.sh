#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/photoprism
#${BUILD_DIR}/bin/darktable-cli.sh -v

adduser test
ls -la /home/test
sudo -u test ${BUILD_DIR}/bin/darktable-cli.sh -v

${BUILD_DIR}/bin/heif-convert -v
${BUILD_DIR}/bin/heif-convert --list-decoders

${BUILD_DIR}/bin/exiftool

${BUILD_DIR}/bin/photoprism.sh --version
${BUILD_DIR}/bin/photoprism.sh users mod --help

grep -aq PHOTOPRISM_LDAP_ENABLED ${BUILD_DIR}/opt/photoprism/bin/photoprism