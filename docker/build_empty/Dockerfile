FROM postgres:14-bullseye as base

# ------------ BASE 

RUN apt update
RUN apt-get update
RUN apt upgrade -y
RUN apt-get upgrade -y

# --- NGINX
RUN apt-get install nginx -y

# --- ZIP
RUN apt-get install zip gzip tar -y

# ------------ BUILD

FROM rust:latest as build

# --- NODE and NPX
ARG NODE_VERSION=16
# https://github.com/nodesource/distributions/blob/master/README.md -> Node.js LTS (v14.x): -> # Using Debian, as root
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash 
RUN apt-get install -y nodejs
RUN node -v
RUN npx -v

# --- YARN
RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add 
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install yarn -y

# --- BUILD remote_server
WORKDIR /home/
ARG REMOTE_SERVER_BRANCH=develop
ARG FORCE_REBUILD_REMOTE_SERVER='0'
RUN git clone -b ${REMOTE_SERVER_BRANCH} https://github.com/openmsupply/remote-server.git
RUN echo "REMOTE SERVER BUILD, BRANCH:${REMOTE_SERVER_BRANCH} DATE: $(date)" >> build-info.txt
WORKDIR /home/remote-server
RUN echo "REMOTE SERVER BUILD COMMIT: $(git rev-parse HEAD)" >> /home/build-info.txt
# --package server should build remote_server and remote_server_cli (bins as listed in src/sever/Cargo.toml)
# Sqlite
RUN cargo build --features default --release --package server
RUN cargo build --features default --release --package demo
RUN cp target/release/remote_server /home/remote_server_sqlite
RUN cp target/release/remote_server_cli /home/remote_server_sqlite_cli
RUN cp target/release/demo_cli /home/demo_sqlite_cli

# Postgres
RUN cargo build --features postgres --release --package server
RUN cargo build --features postgres --release --package demo
RUN cp target/release/remote_server /home/remote_server_postgres
RUN cp target/release/remote_server_cli /home/remote_server_postgres_cli
RUN cp target/release/demo_cli /home/demo_postgres_cli

# --- BUILD openmsupply-client
WORKDIR /home/
ARG OPENMSUPPLY_CLIENT_BRANCH=main
ARG FORCE_REBUILD_OPENMSUPPLY_CLIENT='0'
RUN git clone -b ${OPENMSUPPLY_CLIENT_BRANCH} https://github.com/openmsupply/openmsupply-client.git
RUN echo "OPENMSUPPLY CLIENT BUILD, BRANCH:${OPENMSUPPLY_CLIENT_BRANCH} DATE: $(date)" >> build-info.txt
WORKDIR /home/openmsupply-client
RUN echo "OPENMSUPPLY CLIENT BUILD COMMIT: $(git rev-parse HEAD)" >> /home/build-info.txt
RUN yarn install
RUN yarn build

# ------------ ENTRY

FROM base

# --- COPY REMOTE_SERVER FROM BUILD

WORKDIR /home/
COPY --from=build /home/remote_server_sqlite .
COPY --from=build /home/remote_server_sqlite_cli .
COPY --from=build /home/remote_server_postgres .
COPY --from=build /home/remote_server_postgres_cli .
COPY --from=build /home/demo_postgres_cli .
COPY --from=build /home/demo_sqlite_cli .
COPY --from=build /home/remote-server/configuration /home/configuration

ARG FORCE_REBUILD_CONFIGURATIONS='0'

# --- SETUP POSTGRES

# In this base image postgres functionality can only be done as postgres user
RUN apt-get install -y gosu
RUN gosu postgres initdb
RUN gosu postgres echo "listen_addresses = '*'" >> "${PGDATA}/postgresql.conf"
COPY postgres/pg_hba.conf "${PGDATA}/"
# Make /home accessible to postgres, so that postgres can write log and pg dump to it
RUN chmod 777 /home

# --- INITIALISE DATABASE
RUN gosu postgres pg_ctl -D "${PGDATA}" -l postgres.log start && ./remote_server_postgres_cli initialise-database
# omsupply-data.sqlite will be created in /home/ and server should be running from home
RUN ./remote_server_sqlite_cli initialise-database

# --- SETUP NGINX

COPY nginx/omsupply.conf /etc/nginx/conf.d/

# --- COPY OPENMSUPPLY_CLIENT FROM BUILD

COPY --from=build /home/openmsupply-client/packages/host/dist openmsupply-client
# Change api location
COPY front_end/config.js openmsupply-client/config.js

# Build info

COPY --from=build /home/build-info.txt .


# --- COPY ENTYRPOINT

ARG FORCE_REBUILD_ENTRY='0'

WORKDIR /home/
COPY export_env.sh .
COPY entry.sh .
COPY cmd.sh .
ENTRYPOINT ["/home/entry.sh"]
CMD [ "/home/cmd.sh" ]

EXPOSE 3000
