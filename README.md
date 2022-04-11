# omsupply-build-tools
 
Repository for build tools of omSupply project, [back end](https://github.com/openmsupply/remote-server), [front end](https://github.com/openmsupply/openmsupply-client)

# Docker Overview

Two images have been added to [dockerhub msupplyfoundation](https://hub.docker.com/u/msupplyfoundation)

* [omsupply](https://hub.docker.com/repository/docker/msupplyfoundation/omsupply) -> empty image with no data and initilised schema
* [omsupply_withdata](https://hub.docker.com/repository/docker/msupplyfoundation/omsupply_withdata) -> image with data initilised, derived from omsupply image

Images include both postgres and sqlite binaries, export tool and auto data refresh (advance dates forward). 

# Docker for Consumers

See dockerhub for available tag/s or version, most of the time `latest` tag should be used. Once you've [installed docker](https://docs.docker.com/desktop/mac/install/), and picked the flavour you can run image locally. Images run inside `containers`, containers can be stopped and resumed with data persisting, you can also persist data between different images by mounting volumes (at the time of writting migrations are not implemented on back end so instructions for this is not provided)

Starting image is best done via command line, but can also be started with docker desktop (instructions are not included here, when starting image via docker desktop have to bind port 3000 to 3000).

## Starting image with data

`NOTE` make sure docker daemon is running (start docker desktop)

These are the easies images to get going, find the version you want [here](https://hub.docker.com/repository/docker/msupplyfoundation/omsupply_withdata) and then type the following in terminal:

```bash
docker run -ti -p 3000:3000 msupplyfoundation/omsupply_withdata:{tagname}
# i.e. if you want to use latest tag then
docker run -ti -p 3000:3000 msupplyfoundation/omsupply_withdata:latest
```

If something is already running on that port (like another container), then you can change the first 3000 to another port or stop image via docker desktop.

`docker` will give this container a random name, you can specify a different name with `--name`

```bash
docker run -ti -p 3000:3000 --name my-contianer-name msupplyfoundation/omsupply_withdata:latest
```

When container starts running, you can press enter and run terminal commands inside the container, type `exit` to stop container and release from terminal. `-ti` mean `interactive` (can enter things in terminal) and `tty` (can see terminal output).

You can now go to `http://localhost:3000` in your browser to access omSupply. `-p` means bind host port 3000 (port on your computer) to docker port 3000 (where app is running inside the container).

Every image with data that's pushed to dockerhub should have associated description [here](https://github.com/openmsupply/omsupply-build-tools/tree/main/builds), you can find original data find reference and usernames and passwords there

## Restarting image with data

You can do this either with docker desktop app or: 

```bash
# This will list all docker containers
docker container ls -a
# Restart either with container id or name (for example)
docker container start -ai 4b7a36ef4f36
```
Data should have persisted

## Starting image without data

These are empty images that need to be initilised, they can be found [here]([omsupply](https://hub.docker.com/repository/docker/msupplyfoundation/omsupply)

You would need to pass through sync site credentials via env variables

```bash
docker run -ti -p 3000:3000 -e APP_SYNC__URL="http://localhost:2048" -e APP_SYNC__USERNAME="demo_site" -e  APP_SYNC__PASSWORD="pass" -e APP_SYNC__SITE_ID=2 msupplyfoundation/omsupply:latest
```

## Exporting Env

When reporting bugs, you would need to provide devs with environment (information about build version, current container data etc..). This will require doing a couple of commands:

```bash
# This will list running container, can also find the name of container in docker desktop
docker container ps
# This will export env inside the container, if you already in container terminal just run ./export_env.sh (4b7a36ef4f36 is container id or name)
docker exec 4b7a36ef4f36 ./export_env.sh
# This will copy exported data to the folder you are in
docker cp 4b7a36ef4f36:/home/env_export.zip .
# Can run the following command if you not sure where the file is
pwd
```

Add issues to either back end](https://github.com/openmsupply/remote-server) or [front end](https://github.com/openmsupply/openmsupply-client) repositories with the bug, replication instructions and env export zip

## Extras

Every time a container is started from image:

* data is advanced forward (to current date), you can disable this by adding `-e DONT_REFRESH_DATA=true` when using `docker run`
* by default postgres flavour of server is started, can override this by adding `-e DATABASE_TYPE=sqlite` when using `docker run`

## Docker fo Devs

Two Dockerfiles are used to create base image and image with data, base image for publishing should be created by specifying git `tags` and temporary dev images can be created from any `branch`. `dockerise.sh` provides an easy way to create both base and data images, just change env variables in that file. `dockerise_data_only.sh` can be used to build just the data image from already created base image. With data images should be accompanied by a [description](https://github.com/openmsupply/omsupply-build-tools/tree/main/builds).

## docker/build_empty/Dockerfile

Creates base image, using postgres image as base.

* Builds both front end and back end based on docker args (`REMOTE_SERVER_BRANCH` and `OPENMSUPPLY_CLIENT_BRANCH`), git `tags` act kind of like branches, so tags can be specified instead of branch when publishing to dockerhub
* For back end both postgres and sqlite flavours are built, `remote_server_sqlite`, `remote_server_sqlite_cli`, `remote_server_postgres`, `remote_server_postgres_cli` executable are placed in `/home` folder in container
* Server configuration files are also copied to `/home` (every configuration can be overwritten by env variables passed through when running container, dot notations are specified by double underscore `__` i.e. `-e APP_SYNC__URL="..."` will replace sync.url)
* Openmsupply client is built and artifacts are placed in `/home/openmsupply-clinet` folder inside the container
* config.js is replaced with `/docker/build_empty/front_end/config.js` (api accessible on the same domain with same port, see nginx below)
* `remote_server_cli` is used to initilise schema for both pg and sqlite (openmsupply-databas.sqlite is placed inside `/home` dir)
* `nginx` config is copied over, nginx serves static f/e files and proxies server to `/api` route
* Build info is saved in `/home/build-info.txt` (branches and commits used in the build)
* `entry.sh` runs first on container startup (it's meant to be harder to override the cmd.sh), it start postgres and nginx
* `cmd.sh` would run after `entry.sh` and can be easily overwritten i.e. `docker run -ti image_name /bin/bash` to enter into container terminal without starting server, or `docker run -ti image_name ./remote_server_postgres_cli refresh-data` to run just the refresh data`, cmd.sh does the following:
    * Starts either sqlite or postgres server (postgres by default, but can be overwritten with `-e DATABASE_TYPE=sqlite`)
    * Server is started with logs going to remote_server_{flavour}.log in `/home/` folder
    * Refreshes data if it's a fresh container (see `cmd.sh` for how to stop data refresh)
* `export_env.sh` is copied to `/home`, this will create a zip with 
    * env info
    * both database export (can see what db was running by looking at env info, if DATABASE_TYPE is missing or it' not `sqlite` it's running postgres)
    * build info
    * server logs
* When building images docker caches lines that haven't changes thus some `FORCE_...` args are specified, they can be incremented for re-building image at that particular point (i.e. if entry.sh is changed or branch was updated)

## docker/build_empty/Dockerfile

If you want to create a new data image from already built base image, can use this Dockerfile. This dockerfile is alsy used by `dockerise.sh`. It would run `remote_server_cli` `initialise-from-central` sub command, which requires `-u` option to sync users, see `USERS` args

## dockerise.sh

A helper to dockerise both base and data image. Please see env varialbes that are available and changes as needed. It can auto push to dockerhub and set image as latest. 

Also creates a new tag `new` (for base) and `new_withdata` (for base with data), so that after build can easily run it i.e. `docker run -ti -p 3000:3000 new_withdata`

## dockerise_data_only.sh

For creating new data image from existing base image

## Git Action 

Ideally we would have git actions that do dockarisations and push to dockerhub, this is not done yet. To populate images with data `remote_server_cli` allows for exporting and importing central data to json `initialise-from-export` and `export-initilisation sub commands.


## Dockerhub

mSupply dockerhub credentials are in bitwarden


# Usefull docker commands

`sudo docker rm $(sudo docker ps -a -q)` removes all containers

`sudo docker rmi -f $(sudo docker images -a -q)`removes all images

`sudo docker volume prune` prune everything
