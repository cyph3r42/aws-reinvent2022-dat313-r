FROM debian:stable-slim as fetcher

RUN apt-get update && apt-get install -y \
  curl \
  wget


FROM alpine:3.16.2


RUN set -ex \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk update \
    && apk upgrade \
    && apk add --no-cache \
    bash \
    bind-tools \
    bird \
    busybox-extras \
    curl \
    file\
    findutils \
    gcc \
    git \
    grep \
    jq \
    libc-dev \
    libc6-compat \
    liboping \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    musl-dev \
    nmap \
    nmap-nping \
    nmap-scripts \
    openssl \
    py3-pip \
    py3-setuptools \
    python3-dev \
    scapy \
    socat \
    speedtest-cli \
    openssh \
    strace \
    util-linux \
    vim \
    git \
    rsync \
    zsh \
    websocat \
    wget \
    swaks \
    redis

# Installing httpie ( https://httpie.io/docs#installation)
RUN pip3 install --upgrade httpie



# Setting User and Home
USER root
WORKDIR /root
ENV HOSTNAME netshoot

# ZSH Themes
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
COPY zshrc .zshrc
COPY motd motd


# Running ZSH
CMD ["zsh"]
