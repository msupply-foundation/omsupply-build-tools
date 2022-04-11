ARG BASE_IMAGE_NAME=omsupply
ARG BASE_IMAGE_TAG=latest
FROM $BASE_IMAGE_NAME:$BASE_IMAGE_TAG

ARG SYNC_URL="http://localhost:2048"
ARG SYNC_SITE_NAME="demo"
ARG SYNC_SITE_PASSWORD="pass"
ARG SYNC_SITE_ID="2"
ARG USERS="central admin:pass,hospital director:pass,rural pharm:pass" 

ARG FORCE_REBUILD_WITH_DATA='0'

# Import data
WORKDIR /home/
RUN gosu postgres pg_ctl -D "${PGDATA}" -l postgres.log start && APP_SYNC__URL=$SYNC_URL APP_SYNC__USERNAME=$SYNC_SITE_NAME APP_SYNC__PASSWORD=$SYNC_SITE_PASSWORD APP_SYNC__SITE_ID=$SYNC_SITE_ID ./remote_server_postgres_cli initialise-from-central -u "${USERS}"
RUN APP_SYNC__URL=$SYNC_URL APP_SYNC__USERNAME=$SYNC_SITE_NAME APP_SYNC__PASSWORD=$SYNC_SITE_PASSWORD APP_SYNC__SITE_ID=$SYNC_SITE_ID ./remote_server_sqlite_cli initialise-from-central -u "${USERS}"


