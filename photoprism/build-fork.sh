#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap/photoprism

if [ -z "$UPSTREAM_TAG" ]; then
  echo "UPSTREAM_TAG is required" >&2
  exit 1
fi

cd ${DIR}
wget --progress=dot:giga https://github.com/photoprism/photoprism/archive/refs/tags/${UPSTREAM_TAG}.tar.gz
tar xf ${UPSTREAM_TAG}.tar.gz
mv photoprism-${UPSTREAM_TAG} photoprism-src

cd photoprism-src
patch -p1 < ${DIR}/syncloud.patch
make dep-tensorflow
go test ./internal/auth/acl/...
go test ./internal/auth/oidc/ -run 'TestSocketTransport|TestHttpClient'
go test ./internal/entity/ -run 'TestAuthLdap|TestLinkLdapUser|TestUser_EnsureUserBasePath'
make build-go

cp photoprism ${BUILD_DIR}/opt/photoprism/bin/photoprism
