#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
exec ${DIR}/photoprism/bin/photoprism.sh --config-path /var/snap/photoprism/current/config "$@"
