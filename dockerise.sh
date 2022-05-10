#!/bin/bash
set -e
# --- BASE BUILD CONFIG

SHOULD_BUILD_BASE=true
# Use tag instead of branch for published builds
OPENMSUPPLY_CLIENT_BRANCH='main'
# Use tag instead of branch for published builds
REMOTE_SERVER_BRANCH='develop'
# msupplyfoundation would be dockerhub account
NEW_IMAGE_NAME='msupplyfoundation/omsupply'
NEW_IMAGE_TAG="be-${REMOTE_SERVER_BRANCH}_fe-${OPENMSUPPLY_CLIENT_BRANCH}"
NODE_VERSION='16'

# --- BUILD WITH DATA CONFIG

SHOULD_BUILD_WITH_DATA=true
NEW_IMAGE_WITH_DATA_NAME='msupplyfoundation/omsupply_withdata'
NEW_IMAGE_WITH_DATA_TAG="${NEW_IMAGE_TAG}"

# To access localhost from within docker container use host.docker.internal
SYNC_URL="http://host.docker.internal:2048"
SYNC_SITE_NAME="demo"
# d74ff0ee8da3b9806b18c877dbf29bbde50b5bd8e4dad7a3a725000feb82e8f1 = "pass" (sha256)
SYNC_SITE_PASSWORD_SHA256="d74ff0ee8da3b9806b18c877dbf29bbde50b5bd8e4dad7a3a725000feb82e8f1"
SYNC_SITE_ID="2"
USERS="Demo:pass,Demo2:pass,Kopu:pass,Waikato:pass"

# ---- COMBINED CONFIG

# Also create latest tag, i.e. omsupply:latest and omsupply_withdata:latest
TAG_AS_LATEST=true
# Push to dockerhub
PUSH_TO_DOCKERHUB=false

# ---- REBUILDING FLAGS

# Increment any value to force rebuild (i.e. when branch names haven't changed but new changes were pushed to that branch or entrypoint changed etc..)
FORCE_REBUILD_REMOTE_SERVER='0'
FORCE_REBUILD_OPENMSUPPLY_CLIENT='0'
FORCE_REBUILD_CONFIGURATIONS='0'
FORCE_REBUILD_ENTRY='0'
FORCE_REBUILD_WITH_DATA='0'

# --- BASE BUILD

if $SHOULD_BUILD_BASE; then

  NEW_IMAGE_NAME_AND_TAG="${NEW_IMAGE_NAME}:${NEW_IMAGE_TAG}"
  echo -e "\nBuilding image: ${NEW_IMAGE_NAME_AND_TAG}\n"

  docker build \
    --progress plain \
    -t "${NEW_IMAGE_NAME_AND_TAG}" \
    --build-arg REMOTE_SERVER_BRANCH="$REMOTE_SERVER_BRANCH" \
    --build-arg OPENMSUPPLY_CLIENT_BRANCH="$OPENMSUPPLY_CLIENT_BRANCH" \
    --build-arg NODE_VERSION="$NODE_VERSION" \
    --build-arg FORCE_REBUILD_REMOTE_SERVER="$FORCE_REBUILD_REMOTE_SERVER" \
    --build-arg FORCE_REBUILD_OPENMSUPPLY_CLIENT="$FORCE_REBUILD_OPENMSUPPLY_CLIENT" \
    --build-arg FORCE_REBUILD_CONFIGURATIONS="$FORCE_REBUILD_CONFIGURATIONS" \
    docker/build_empty/.

  if $PUSH_TO_DOCKERHUB; then
    docker push "${NEW_IMAGE_NAME_AND_TAG}"
  fi

  if $TAG_AS_LATEST; then
    
      echo -e "\nTaggins as latest: ${NEW_IMAGE_NAME}:latest\n"
      docker tag $NEW_IMAGE_NAME_AND_TAG "${NEW_IMAGE_NAME}:latest"
      if $PUSH_TO_DOCKERHUB; then
      docker push "${NEW_IMAGE_NAME}:latest"
      fi

  fi

  # For ease of testing new local images
  docker tag $NEW_IMAGE_NAME_AND_TAG "new"

fi

# -- BUILD WITH DATA

if $SHOULD_BUILD_WITH_DATA; then

  NEW_IMAGE_NAME_AND_TAG="${NEW_IMAGE_WITH_DATA_NAME}:${NEW_IMAGE_WITH_DATA_TAG}"
  echo -e "\nBuilding image: ${NEW_IMAGE_NAME_AND_TAG}\n"

  docker build \
    --progress plain \
    -t "${NEW_IMAGE_NAME_AND_TAG}" \
    --build-arg BASE_IMAGE_NAME="$NEW_IMAGE_NAME" \
    --build-arg BASE_IMAGE_TAG="$NEW_IMAGE_TAG" \
    --build-arg SYNC_URL="$SYNC_URL" \
    --build-arg SYNC_SITE_NAME="$SYNC_SITE_NAME" \
    --build-arg SYNC_SITE_PASSWORD_SHA256="$SYNC_SITE_PASSWORD_SHA256" \
    --build-arg SYNC_SITE_ID="$SYNC_SITE_ID" \
    --build-arg USERS="$USERS" \
    --build-arg FORCE_REBUILD_WITH_DATA="$FORCE_REBUILD_WITH_DATA" \
    docker/build_with_central_data/.

  if $PUSH_TO_DOCKERHUB; then
    docker push "${NEW_IMAGE_NAME_AND_TAG}"
  fi

  if $TAG_AS_LATEST; then
    
      docker tag $NEW_IMAGE_NAME_AND_TAG "${NEW_IMAGE_WITH_DATA_NAME}:latest"
      if $PUSH_TO_DOCKERHUB; then
      docker push "${NEW_IMAGE_WITH_DATA_NAME}:latest"

      fi
  fi

  # For ease of testing new local images
  docker tag $NEW_IMAGE_NAME_AND_TAG "new_withdata"
fi



# --build-arg substitues the ARG variables in Dockerfile
# --no-cache -> can be used to re-build (rebuilds the whole image, can also use FORCE_REBUILD args)
# --progress plain -> show full progress
# --platform -> can be used when targeting other systems, i.e. "linux/amd64"