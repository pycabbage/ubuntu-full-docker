# syntax=docker/dockerfile:1

ARG NONROOT_USER=ubuntu

FROM ubuntu:22.04 as base

FROM base as final
ARG NONROOT_USER
ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i -E 's/(apt-get upgrade)$/DEBIAN_FRONTEND=noninteractive \1 -y/g' $(which unminimize) && \
    sed -i -E 's/^(read)/REPLY=Y # \1/g' $(which unminimize)

RUN mv /etc/apt/apt.conf.d/docker-clean /tmp/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
    sed -i.bak -r 's!(deb|deb-src) \S+!\1 mirror://mirrors.ubuntu.com/mirrors.txt!' /etc/apt/sources.list
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=./package.list,target=/tmp/package.list \
    unminimize && \
    apt update && \
    apt-get install -y $(grep -v '^# ' /tmp/package.list) \
    locales language-pack-ja manpages-ja
RUN mv /tmp/docker-clean /etc/apt/apt.conf.d/docker-clean && \
    rm /etc/apt/apt.conf.d/keep-cache

# Change language to ja_JP.UTF-8
RUN localedef -i ja_JP -c -f UTF-8 -A /usr/share/locale/locale.alias ja_JP.UTF-8 && \
    update-locale LANG=ja_JP.UTF-8
ENV LANG ja_JP.UTF-8

RUN adduser --disabled-password --shell /bin/bash --gecos '' ${NONROOT_USER} && \
    usermod -aG sudo ${NONROOT_USER} && \
    echo "${NONROOT_USER} ALL=NOPASSWD: ALL" > /etc/sudoers.d/90-${NONROOT_USER} && \
    chmod 0440 /etc/sudoers.d/90-${NONROOT_USER} && \
    visudo -c

USER ${NONROOT_USER}
WORKDIR /home/${NONROOT_USER}
ENV TERM=xterm-256color
