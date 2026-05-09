#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

set -a
source /var/snap/photoprism/current/config/photoprism.env
set +a

# Trust the platform's syncloud CA (used to sign the Authelia OIDC issuer cert
# in dev / on devices without a real cert) on top of the system roots so
# photoprism's HTTP client can complete OIDC issuer discovery.
BUNDLE=/var/snap/photoprism/current/config/ca-bundle.crt
cp /etc/ssl/certs/ca-certificates.crt ${BUNDLE}
SYNCLOUD_CA=/var/snap/platform/current/syncloud.ca.crt
[ -f ${SYNCLOUD_CA} ] && cat ${SYNCLOUD_CA} >> ${BUNDLE}
export SSL_CERT_FILE=${BUNDLE}

rm -rf /var/snap/photoprism/common/web.socket
exec ${DIR}/photoprism/bin/photoprism.sh --config-path /var/snap/photoprism/current/config start
