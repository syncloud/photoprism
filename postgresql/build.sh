#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

VERSION=15.3

BUILD_DIR=${DIR}/../build/snap/postgresql

while ! docker build --build-arg VERSION=$VERSION -t postgres:syncloud . ; do
  sleep 1
  echo "retry docker"
done
docker run postgres:syncloud postgres --help
docker create --name=postgres postgres:syncloud
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
echo "${VERSION}" > ${BUILD_DIR}/../db.major.version
docker export postgres -o postgres.tar
tar xf postgres.tar
rm -rf postgres.tar
ls -la 
ls -la bin
ls -la usr/bin
ls -ls usr/share/postgresql-common/pg_wrapper
PGBIN=$(echo usr/lib/postgresql/*/bin)
ldd $PGBIN/initdb || true
mv $PGBIN/postgres $PGBIN/postgres.bin
mv $PGBIN/pg_dump $PGBIN/pg_dump.bin
cp $DIR/bin/* bin
cp $DIR/pgbin/* $PGBIN
