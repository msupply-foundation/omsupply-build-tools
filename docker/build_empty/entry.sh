#!/bin/bash
set -e

echo '---'
echo '---'
echo '--- STARTING POSTGRES'
echo '---'
echo '---'

gosu postgres pg_ctl -D "${PGDATA}" -l postgres.log start

echo '---'
echo '---'
echo '--- STARTING NGINX'
echo '---'
echo '---'
service nginx start
service nginx status

exec "$@"