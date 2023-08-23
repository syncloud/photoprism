#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export PHOTOPRISM_LDAP_URI="ldap://localhost:389"
export PHOTOPRISM_LDAP_INSECURE="true"
export PHOTOPRISM_LDAP_SYNC="true"
export PHOTOPRISM_LDAP_BIND="simple"
export PHOTOPRISM_LDAP_BIND_DN="cn"
export PHOTOPRISM_LDAP_BASE_DN="dc=syncloud,dc=org"
export PHOTOPRISM_LDAP_ROLE="admin"
export PHOTOPRISM_LDAP_ROLE_DN="cn=syncloud,ou=groups,dc=syncloud,dc=org"
export PHOTOPRISM_LDAP_WEBDAV_DN="ou=users,dc=syncloud,dc=org"
exec ${DIR}/photoprism/bin/photoprism.sh --config-path /var/snap/photoprism/current/config start
