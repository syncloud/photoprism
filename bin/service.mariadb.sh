#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
rm -rf /var/snap/photoprism/current/database/aria_log_control
export MYSQL_HOME=/var/snap/photoprism/current/config
exec ${DIR}/mariadb/usr/bin/mysqld \
  --basedir=/snap/photoprism/current/mariadb/usr \
  --datadir=/var/snap/photoprism/current/database \
  --plugin-dir=/snap/photoprism/current/mariadb/lib/plugin \
  --pid-file=/var/snap/photoprism/current/database/mariadb.pid
