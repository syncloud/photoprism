#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
rm -rf /var/snap/photoprism/current/database/aria_log_control
export MYSQL_HOME=/var/snap/wordpress/current/config
exec ${DIR}/mariadb/usr/bin/mysqld --basedir=$SNAP/mariadb/usr --datadir=$SNAP_DATA/database --plugin-dir=$SNAP/mariadb/lib/plugin --pid-file=$SNAP_DATA/database/mariadb.pid
