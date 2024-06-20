#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
exec ${DIR}/mariadb/usr/bin/mysql --socket=/var/snap/photoprism/current/mysql.sock "$@"
