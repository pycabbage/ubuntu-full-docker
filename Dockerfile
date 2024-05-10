# syntax=docker/dockerfile:1

ARG NONROOT_USER=ubuntu
ARG NONROOT_USER_UID=1000
ARG NONROOT_USER_GID=1000
ARG VARIANT=24.04
ARG PYTHON_VERSION=3.12.3
ARG NODEJS_VERSION=v22.1.0

FROM ubuntu:${VARIANT} as base

FROM base as builder
ARG NONROOT_USER
ARG NONROOT_USER_UID
ARG NONROOT_USER_GID
ARG VARIANT
ARG DEBIAN_FRONTEND=noninteractive

# Add non-root user before unminimize to avoid uid/gid conflict
# Create and add docker group with gid
RUN groupadd -g 999 docker
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && \
    apt-get install -y sudo adduser
RUN ( grep "${NONROOT_USER}" /etc/passwd || useradd -m -s /bin/bash -u ${NONROOT_USER_UID} "${NONROOT_USER}" ) && \
    usermod -aG docker,root,sudo "${NONROOT_USER}" && \
    echo "${NONROOT_USER} ALL=NOPASSWD: ALL" > "/etc/sudoers.d/90-${NONROOT_USER}" && \
    chmod 0440 "/etc/sudoers.d/90-${NONROOT_USER}" && \
    visudo -c

RUN sed -i -E 's/(apt-get upgrade)$/DEBIAN_FRONTEND=noninteractive \1 -y/g' $(which unminimize) && \
    sed -i -E 's/^(read)/REPLY=Y # \1/g' $(which unminimize)

RUN mv /etc/apt/apt.conf.d/docker-clean /tmp/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=./packages/ubuntu-${VARIANT}.list,target=/tmp/package.list \
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

FROM builder as pyenv_builder

ARG VARIANT
ARG NONROOT_USER_UID
ARG NONROOT_USER_GID
ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && \
    apt-get install -y build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev ccache

USER "${NONROOT_USER}"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=bind,source=./scripts/install-python-pyenv.sh,target=/tmp/install-python-pyenv.sh \
    . /tmp/install-python-pyenv.sh prepare
RUN --mount=type=bind,source=./scripts/install-python-pyenv.sh,target=/tmp/install-python-pyenv.sh \
    --mount=type=cache,target=/home/${NONROOT_USER}/.pyenv/sources,uid=${NONROOT_USER_UID},gid=${NONROOT_USER_GID},sharing=locked \
    --mount=type=cache,target=/home/${NONROOT_USER}/.pyenv/ccache,uid=${NONROOT_USER_UID},gid=${NONROOT_USER_GID},sharing=locked \
    . /tmp/install-python-pyenv.sh install "${PYTHON_VERSION}"

FROM builder as rust

USER "${NONROOT_USER}"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=bind,source=./scripts/install-rust.sh,target=/tmp/install-rust.sh \
    . /tmp/install-rust.sh

FROM builder as nodejs
ARG NODEJS_VERSION

USER "${NONROOT_USER}"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=bind,source=./scripts/install-nodejs-nvm.sh,target=/tmp/install-nodejs-nvm.sh \
    . /tmp/install-nodejs-nvm.sh install "${NODEJS_VERSION}"

FROM builder as final

USER "${NONROOT_USER}"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy python
COPY --from=pyenv_builder \
    --chown="${NONROOT_USER}":"${NONROOT_USER}" \
    "/home/${NONROOT_USER}/.pyenv" "/home/${NONROOT_USER}/.pyenv"
RUN --mount=type=bind,source=./scripts/install-python-pyenv.sh,target=/tmp/install-python-pyenv.sh \
    . /tmp/install-python-pyenv.sh bashrc

# Copy nodejs
COPY --from=nodejs \
    --chown="${NONROOT_USER}":"${NONROOT_USER}" \
    "/home/${NONROOT_USER}/.nvm" "/home/${NONROOT_USER}/.nvm"
RUN --mount=type=bind,source=./scripts/install-nodejs-nvm.sh,target=/tmp/install-nodejs-nvm.sh \
    . /tmp/install-nodejs-nvm.sh bashrc

# Copy rust (.cargo, .rustup)
COPY --from=rust \
    --chown="${NONROOT_USER}":"${NONROOT_USER}" \
    "/home/${NONROOT_USER}/.cargo" "/home/${NONROOT_USER}/.cargo"
COPY --from=rust \
    --chown="${NONROOT_USER}":"${NONROOT_USER}" \
    "/home/${NONROOT_USER}/.rustup" "/home/${NONROOT_USER}/.rustup"

# revert apt cache settings
RUN mv /tmp/docker-clean /etc/apt/apt.conf.d/docker-clean && \
    rm /etc/apt/apt.conf.d/keep-cache
# Change apt mirror
RUN \
    if [ "${VARIANT%.*}" -ge 24 ]; then \
    sed -i -r 's!(URIs:) \S+!\1 mirror://mirrors.ubuntu.com/mirrors.txt!' /etc/apt/sources.list.d/ubuntu.sources; \
    else \
    sed -i -r 's!(deb|deb-src) \S+!\1 mirror://mirrors.ubuntu.com/mirrors.txt!' /etc/apt/sources.list; \
    fi
# Change language to ja_JP.UTF-8
RUN localedef -i ja_JP -c -f UTF-8 -A /usr/share/locale/locale.alias ja_JP.UTF-8 && \
    update-locale LANG=ja_JP.UTF-8 && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata
# Build time log
RUN echo "Build time: $(date --rfc-3339=seconds -u) UTC" > /var/log/build-time.log
ENV LANG ja_JP.UTF-8
WORKDIR "/home/${NONROOT_USER}"
ENV TERM=xterm-256color
