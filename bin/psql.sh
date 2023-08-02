#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
USER=photoprism
if [ -z "$SNAP_DATA" ]; then
  echo "SNAP_DATA environment variable must be set"
  exit 1
fi

# shellcheck source=config/env
. "${SNAP_DATA}/config/env"

if [[ "$(whoami)" == "$USER" ]]; then
    ${DIR}/postgresql/bin/psql.sh -p ${PSQL_PORT} -h ${PSQL_DATABASE} "$@"
else
    sudo -E -H -u $USER ${DIR}/postgresql/bin/psql.sh -p ${PSQL_PORT} -h ${PSQL_DATABASE} "$@"
fi
