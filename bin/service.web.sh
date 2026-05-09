#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

set -a
source /var/snap/photoprism/current/config/photoprism.env
set +a

rm -rf /var/snap/photoprism/common/web.socket
exec ${DIR}/photoprism/bin/photoprism.sh --config-path /var/snap/photoprism/current/config start
