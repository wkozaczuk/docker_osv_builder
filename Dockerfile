#
# Copyright (C) 2017 XLAB, Ltd.
# Copyright (C) 2018 Waldemar Kozaczuk
#
# This work is open source software, licensed under the terms of the
# BSD license as described in the LICENSE file in the top-level directory.
#

FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=linux

COPY ./etc/keyboard /etc/default/keyboard
COPY ./etc/console-setup /etc/default/console-setup

#
# PREREQUISITES
#
RUN apt-get update -y && apt-get install -y \
ant \
autoconf \
automake \
bison \
build-essential \
curl \
flex \
gcc \
g++-multilib \
gdb \
gawk \
genromfs \
git \
gnutls-bin \
libboost-all-dev \
libedit-dev \
libmaven-shade-plugin-java \
libncurses5-dev \
libssl-dev \
libtool \
libvirt-bin \
libyaml-cpp-dev \
maven \
openjdk-8-jdk-headless \
openssl \
p11-kit \
python-dpkt \
python-requests \
qemu-system-x86 \
qemu-utils \
tcpdump \
unzip \
wget && apt-get autoremove && apt-get clean

#ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#
# PREPARE ENVIRONMENT
#

# - prepare directories
#RUN mkdir /git-repos /result
# - clone and build OSv
#WORKDIR /git-repos
#RUN git clone --depth 1 https://github.com/cloudius-systems/osv.git
#WORKDIR /git-repos/osv
#RUN git submodule update --init --recursive

#WORKDIR /git-repos/osv
#CMD scripts/build -j4 check
CMD /bin/bash

#
# NOTES
#
# Build this container with (add --no-cache flag to rebuild also OSv):
# docker build -t mikelangelo/capstan-packages .
#
# Run this container with:
# docker run -it --volume="$PWD/result:/result" mikelangelo/capstan-packages
#
