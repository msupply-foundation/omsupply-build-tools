ARG BASE_IMAGE_NAME=omsupply
ARG BASE_IMAGE_TAG=latest
FROM $BASE_IMAGE_NAME:$BASE_IMAGE_TAG

ARG SYNC_URL="http://localhost:2048"
ARG SYNC_SITE_NAME="demo"
# d74ff0ee8da3b9806b18c877dbf29bbde50b5bd8e4dad7a3a725000feb82e8f1 = "pass" (sha256)
ARG SYNC_SITE_PASSWORD_SHA256="d74ff0ee8da3b9806b18c877dbf29bbde50b5bd8e4dad7a3a725000feb82e8f1"
ARG SYNC_SITE_ID="2"
ARG USERS="central admin:pass,hospital director:pass,rural pharm:pass" 

ARG FORCE_REBUILD_WITH_DATA='0'

# Import data
WORKDIR /home/
RUN gosu postgres pg_ctl -D "${PGDATA}" -l postgres.log start && echo "Syncing, if this freezes make sure central server is running (for some reason requests to 'host.docker.internal' freeze if port is not listening)" && APP_SYNC__URL=$SYNC_URL APP_SYNC__USERNAME=$SYNC_SITE_NAME APP_SYNC__PASSWORD_SHA256=$SYNC_SITE_PASSWORD_SHA256 APP_SYNC__SITE_ID=$SYNC_SITE_ID ./remote_server_postgres_cli initialise-from-central -u "${USERS}"
RUN APP_SYNC__URL=$SYNC_URL APP_SYNC__USERNAME=$SYNC_SITE_NAME APP_SYNC__PASSWORD_SHA256=$SYNC_SITE_PASSWORD_SHA256 APP_SYNC__SITE_ID=$SYNC_SITE_ID ./remote_server_sqlite_cli initialise-from-central -u "${USERS}"


