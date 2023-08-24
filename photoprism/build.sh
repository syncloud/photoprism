#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap/photoprism
while ! docker create --name=photoprism photoprism/photoprism:$VERSION ; do
  sleep 1
  echo "retry docker"
done
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export photoprism -o app.tar
tar xf app.tar
rm -rf app.tar
cp ${DIR}/photoprism/photoprism ${BUILD_DIR}/opt/photoprism/bin/photoprism
cp ${DIR}/photoprism.sh ${BUILD_DIR}/bin/
