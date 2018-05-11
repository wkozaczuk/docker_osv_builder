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
ed \
flex \
gcc-7 \
g++-7-multilib \
gdb \
gawk \
genromfs \
git \
gnutls-bin \
libboost1.65-all-dev \
libedit-dev \
libmaven-shade-plugin-java \
libncurses5-dev \
libssl-dev \
libtool \
libvirt-bin \
libyaml-cpp-dev \
maven \
nodejs \
mpm \
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

RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

#
# PREPARE ENVIRONMENT
#

# - prepare directories
RUN mkdir /git-repos /result
# - clone OSv
WORKDIR /git-repos
RUN git clone https://github.com/cloudius-systems/osv.git
WORKDIR /git-repos/osv
RUN git submodule update --init --recursive

# - install Mikelangelo Capstan
RUN curl https://raw.githubusercontent.com/mikelangelo-project/capstan/master/scripts/download | bash

# Copy capstan packages 
WORKDIR /capstan-packages
COPY ./packages/* /capstan-packages

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
