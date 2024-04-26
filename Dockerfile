# syntax=docker/dockerfile:1

ARG NONROOT_USER=ubuntu

FROM ubuntu:22.04 as base

FROM base as final
ARG NONROOT_USER
ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i -E 's/(apt-get upgrade)$/DEBIAN_FRONTEND=noninteractive \1 -y/g' $(which unminimize) && \
    sed -i -E 's/^(read)/REPLY=Y # \1/g' $(which unminimize)

RUN mv /etc/apt/apt.conf.d/docker-clean /tmp/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=./package.list,target=/tmp/package.list \
    unminimize && \
    apt update && \
    apt-get install -y $(grep -v '^# ' /tmp/package.list) \
    language-pack-ja manpages-ja
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list && \
    apt update && \
    apt-get install -y docker-ce-cli docker-compose-plugin
RUN mv /tmp/docker-clean /etc/apt/apt.conf.d/docker-clean && \
    rm /etc/apt/apt.conf.d/keep-cache

# Change apt mirror
RUN sed -i -r 's!(deb|deb-src) \S+!\1 mirror://mirrors.ubuntu.com/mirrors.txt!' /etc/apt/sources.list

# Change language to ja_JP.UTF-8
RUN localedef -i ja_JP -c -f UTF-8 -A /usr/share/locale/locale.alias ja_JP.UTF-8 && \
    update-locale LANG=ja_JP.UTF-8 && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata
ENV LANG ja_JP.UTF-8

RUN adduser --disabled-password --shell /bin/bash --gecos '' ${NONROOT_USER} && \
    usermod -aG sudo ${NONROOT_USER} && \
    echo "${NONROOT_USER} ALL=NOPASSWD: ALL" > /etc/sudoers.d/90-${NONROOT_USER} && \
    chmod 0440 /etc/sudoers.d/90-${NONROOT_USER} && \
    visudo -c
# Create and add docker group with gid
RUN groupadd -g 999 docker && \
    usermod -aG docker ${NONROOT_USER} && \
    usermod -aG docker ${NONROOT_USER} root

USER ${NONROOT_USER}
WORKDIR /home/${NONROOT_USER}
ENV TERM=xterm-256color
