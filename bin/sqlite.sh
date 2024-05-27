#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
exec ${DIR}/sqlite/bin/sqlite.sh /var/snap/photoprism/current/.photoprism.db "$@"
