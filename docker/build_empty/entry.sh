#!/bin/bash
set -e

echo '---'
echo '---'
echo '--- STARTING POSTGRES'
echo '---'
echo '---'

gosu postgres pg_ctl -D "${PGDATA}" -l postgres.log start  &>> postgresql_start.log
cat postgresql_start.log

echo '---'
echo '---'
echo '--- STARTING NGINX'
echo '---'
echo '---'
service nginx start &>> nginx_start.log
service nginx status  &>> nginx_start.log
cat nginx_start.log

exec "$@"