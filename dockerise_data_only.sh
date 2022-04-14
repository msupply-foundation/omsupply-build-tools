#!/bin/bash

# --- CONFIG

BASE_IMAGE_NAME='msupplyfoundation/omsupply'
BASE_IMAGE_TAG='latest'
# To access localhost from within docker container use host.docker.internal
SYNC_URL="http://host.docker.internal:2048"
SYNC_SITE_NAME="demo"
SYNC_SITE_PASSWORD="pass"
SYNC_SITE_ID="2"
USERS="central admin:pass,hospital director:pass,rural pharm:pass" 

FORCE_REBUILD_WITH_DATA='0'

TAG_AS_LATEST=true
# Push to dockerhub
PUSH_TO_DOCKERHUB=false

NEW_IMAGE_NAME='msupplyfoundation/omsupply_withdata'
NEW_IMAGE_TAG="${BASE_IMAGE_TAG}"

NEW_IMAGE_NAME_AND_TAG="${NEW_IMAGE_NAME}:${NEW_IMAGE_TAG}"

docker build \
  --progress plain \
  -t "${NEW_IMAGE_NAME_AND_TAG}" \
  --build-arg BASE_IMAGE_NAME="$BASE_IMAGE_NAME" \
  --build-arg BASE_IMAGE_TAG="$BASE_IMAGE_TAG" \
  --build-arg SYNC_URL="$SYNC_URL" \
  --build-arg SYNC_SITE_NAME="$SYNC_SITE_NAME" \
  --build-arg SYNC_SITE_PASSWORD="$SYNC_SITE_PASSWORD" \
  --build-arg SYNC_SITE_ID="$SYNC_SITE_ID" \
  --build-arg USERS="$USERS" \
  --build-arg FORCE_REBUILD_WITH_DATA="$FORCE_REBUILD_WITH_DATA" \
  docker/build_with_central_data/.

if $PUSH_TO_DOCKERHUB; then
  docker push "${NEW_IMAGE_NAME_AND_TAG}"
fi

if $TAG_AS_LATEST; then
  
    docker tag $NEW_IMAGE_NAME_AND_TAG "${NEW_IMAGE_NAME}:latest"
    if $PUSH_TO_DOCKERHUB; then
    docker push "${NEW_IMAGE_NAME}:latest"

    fi
fi

docker tag $NEW_IMAGE_NAME_AND_TAG "new_withdata"
