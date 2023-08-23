#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export PHOTOPRISM_LDAP_ENABLED="true"
export PHOTOPRISM_LDAP_URI="ldap://localhost:389"
export PHOTOPRISM_LDAP_BIND_DN="cn={username},ou=users,dc=syncloud,dc=org"
export PHOTOPRISM_LDAP_ADMIN_GROUP_DN="cn=syncloud,ou=groups,dc=syncloud,dc=org"
export PHOTOPRISM_LDAP_ADMIN_GROUP_FILTER="(memberUid={username})"
export PHOTOPRISM_LDAP_ADMIN_GROUP_ATTRIBUTE="memberUid"
exec ${DIR}/photoprism/bin/photoprism.sh --config-path /var/snap/photoprism/current/config start
