ARG FROM_TAG=alpine-jdk11

FROM jenkins/inbound-agent:${FROM_TAG}

ARG GOSU_VERSION=1.11
ARG DOCKER_CHANNEL=stable
ARG DOCKER_VERSION=20.10.10
ARG TINY_VERSION=0.18.0

USER root

RUN \
    set -ex; \
    if [ -f /etc/alpine-release ] ; then \
        echo "Alpine"; \
    elif [ -f /etc/debian_version ] ; then \
        echo "Debian, setting locales" \
        && apt-get update \
        && apt-get install -y --no-install-recommends locales \
        && localedef -i en_US -f UTF-8 en_US.UTF-8 \
        && rm -rf /var/lib/apt/lists/*; \
    fi

ENV LANG=en_US.UTF-8

RUN \
    set -ex; \
    if [ -f /etc/alpine-release ] ; then \
        apk add --no-cache curl shadow iptables python3 py3-pip; \
    elif [ -f /etc/debian_version ] ; then \
        apt-get update \
        && apt-get install -y --no-install-recommends curl iptables python3 python3-pip; \
    fi

RUN \
    set -ex; \
    echo "Installing tiny and gosu"; \
    curl -SsLo /usr/bin/gosu https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 \
    && chmod +x /usr/bin/gosu \
    && curl -SsLo /usr/bin/tiny https://github.com/krallin/tini/releases/download/v${TINY_VERSION}/tini-static-amd64 \
    && chmod +x /usr/bin/tiny

RUN \
    set -ex; \
    echo "Installing docker"; \
    curl -Ssl "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" | \
    tar -xz --strip-components=1 --directory /usr/bin/

# Aquí la sustitución para docker-compose:
RUN \
    set -ex; \
    echo "Installing docker-compose (official binary)"; \
    curl -SL https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

COPY entrypoint.sh /entrypoint.sh
COPY modprobe.sh /usr/local/bin/modprobe
COPY wrapdocker.sh /usr/local/bin/wrapdocker

VOLUME /var/lib/docker

ENTRYPOINT [ "tiny", "--", "/entrypoint.sh" ]
