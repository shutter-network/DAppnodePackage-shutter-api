ARG ASSETS_VERSION

FROM ghcr.io/shutter-network/assets:${ASSETS_VERSION} as assets

RUN rsync -aq --delete /assets-source/ /assets/

FROM victoriametrics/vmagent:v1.101.0

ARG NETWORK

ENV ASSETS_DIR=/assets \
    CONFIG_FILE=/config/${NETWORK}/vmagent.yml \
    USER_SETTINGS_FILE=/config/user/settings.env

COPY --from=assets ${ASSETS_DIR}/ ${ASSETS_DIR}/
COPY config/ /config/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p $(dirname ${USER_SETTINGS_FILE})

ENTRYPOINT [ "entrypoint.sh" ]
