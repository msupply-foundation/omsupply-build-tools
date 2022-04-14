#!/bin/bash
set -e

echo '---'
echo '---'
echo '--- STARTING REMOTE SERVER'
echo '---'
echo '---'

[[ -z "${DONT_REFRESH_DATA}" ]] && _DONT_REFRESH_DATA=false || _DONT_REFRESH_DATA=$DONT_REFRESH_DATA
[[ -z "${FORCE_REFRESH_DATA}" ]] && _FORCE_REFRESH_DATA=false || FORCE_REFRESH_DATA=$FORCE_REFRESH_DATA

REFRESH_DATA=false

DATA_WAS_REFRESHED_FILE=/home/refreshed_data
if $_DONT_REFRESH_DATA; then
    echo 'not freseshing data DONT_REFRESH_DATA is true'
    REFRESH_DATA=false
else
    if test -f "$DATA_WAS_REFRESHED_FILE"; then
        if $_FORCE_REFRESH_DATA; then
            echo "refreshing data even though $DATA_WAS_REFRESHED_FILE exists FORCE_REFRESH_DATA is set to true"
            REFRESH_DATA=true
        else
            echo "not refreshing data, $DATA_WAS_REFRESHED_FILE exists"
            REFRESH_DATA=false
        fi
    else
        echo "refreshing data $DATA_WAS_REFRESHED_FILE does not exist"
         REFRESH_DATA=true
    fi
fi

if [ "$DATABASE_TYPE" = "sqlite" ]; then
    echo '--- AS SQLITE'
    if $REFRESH_DATA; then 
        ./remote_server_sqlite_cli refresh-data | tee remote_server_postgres.log
        echo "done" > $DATA_WAS_REFRESHED_FILE
    fi
    ./remote_server_sqlite &>> remote_server_sqlite.log &
    tail -f remote_server_sqlite.log &
else
    echo '--- AS POSTGRES'
    if $REFRESH_DATA; then 
        ./remote_server_postgres_cli refresh-data | tee remote_server_postgres.lo
        echo "done" > $DATA_WAS_REFRESHED_FILE
    fi
  ./remote_server_postgres &>> remote_server_postgres.log &
  tail -f remote_server_postgres.log &
fi

echo '---'
echo '---'
echo '--- Ready to go -> http://localhost:3000'
echo '---'
echo '---'

# Starting with bin bash so can `docker run -ti` straight into terminal
/bin/bash