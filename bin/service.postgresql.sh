#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

# shellcheck source=config/env
. "${SNAP_DATA}/config/env"
export PHOTOPRISM_LDAP_URI="ldap://localhost:389"
export PHOTOPRISM_LDAP_INSECURE="true"
export PHOTOPRISM_LDAP_SYNC="true"
export PHOTOPRISM_LDAP_BIND="simple"
export PHOTOPRISM_LDAP_BIND_DN="cn"
export PHOTOPRISM_LDAP_BASE_DN="dc=syncloud,dc=org"
export PHOTOPRISM_LDAP_ROLE=""
export PHOTOPRISM_LDAP_ROLE_DN="ou=users,ou=groups,dc=syncloud,dc=org"
export PHOTOPRISM_DATABASE_DRIVER="postgresql"
export PHOTOPRISM_DATABASE_SERVER="mariadb:4001"
export PHOTOPRISM_DATABASE_NAME="photoprism"
export PHOTOPRISM_DATABASE_USER=""
export PHOTOPRISM_DATABASE_PASSWORD=""
exec ${DIR}/postgresql/bin/pg_ctl.sh -w -s -D ${PSQL_DATABASE} start