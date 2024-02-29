FROM golang:1.21-alpine as build

ARG WRITEFREELY_VERSION=v0.15.0
ARG WRITEFREELY_REF=1d89dea72eb8726b1c9571b063d5e490b8f27a2a
ARG WRITEFREELY_FORK=writefreely/writefreely

RUN apk add --no-cache --update \
        nodejs=20.11.1-r0 \
        npm=10.2.5-r0 \
        make=4.4.1-r2 \
        g++=13.2.1_git20231014-r0 \
        git=2.43.0-r0 \
        sqlite-dev=3.44.2-r0 \
    && npm install -g \
       less@4.2.0 \
       less-plugin-clean-css@1.5.1

RUN mkdir -p /go/src/github.com/${WRITEFREELY_FORK} && \
    git clone https://github.com/${WRITEFREELY_FORK}.git \
              /go/src/github.com/${WRITEFREELY_FORK} -b ${WRITEFREELY_VERSION}
WORKDIR /go/src/github.com/${WRITEFREELY_FORK}
RUN [ -n "${WRITEFREELY_REF}" ] && git checkout "${WRITEFREELY_REF}"

# hadolint ignore=DL3059
RUN cat ossl_legacy.cnf > /etc/ssl/openssl.cnf
ENV GO111MODULE=on
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN make build \
  && make ui \
  && mkdir /stage && \
     cp -R /go/bin \
           /go/src/github.com/${WRITEFREELY_FORK}/templates \
           /go/src/github.com/${WRITEFREELY_FORK}/static \
           /go/src/github.com/${WRITEFREELY_FORK}/pages \
           /go/src/github.com/${WRITEFREELY_FORK}/keys \
           /go/src/github.com/${WRITEFREELY_FORK}/cmd \
           /stage \
  && mv /stage/cmd/writefreely/writefreely /stage

# Final image
FROM alpine:3.19

ARG WRITEFREELY_UID=5000

RUN apk add --no-cache \
        openssl=3.1.4-r5 \
        ca-certificates=20230506-r0 \
    && adduser -D -H -h /writefreely -u "${WRITEFREELY_UID}" writefreely \
    && install -o writefreely -g writefreely -d /data
COPY --from=build --chown=writefreely:writefreely /stage /writefreely
COPY --chown=writefreely:writefreely --chmod=+x bin/writefreely-docker.sh /writefreely/

VOLUME /data
WORKDIR /writefreely
EXPOSE 8080

USER writefreely:writefreely

RUN chmod +x /writefreely/writefreely-docker.sh
ENTRYPOINT ["/writefreely/writefreely-docker.sh"]
