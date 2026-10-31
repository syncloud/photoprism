#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
if [[ $(id -u) -eq 0 ]]; then
  cd /var/snap/photoprism/current
  exec /usr/bin/sudo -H -u photoprism ${DIR}/photoprism/bin/photoprism.sh --config-path /var/snap/photoprism/current/config "$@"
fi
exec ${DIR}/photoprism/bin/photoprism.sh --config-path /var/snap/photoprism/current/config "$@"
