#!/bin/bash

if [ "$1" == "" ]
then
  echo "Usage: publish_packages.sh <package_name>|all <source_dir>"
  exit 1
fi

source $(dirname $0)/commons.sh

SOURCE_PATH="$2"

CAPSTAN_LOCAL_REPO=$HOME/.capstan
CAPSTAN_KERNEL_PATH=$CAPSTAN_LOCAL_REPO/repository/mike/osv-loader
CAPSTAN_PACKAGES_PATH=$CAPSTAN_LOCAL_REPO/packages

mkdir -p $CAPSTAN_KERNEL_PATH
mkdir -p $CAPSTAN_PACKAGES_PATH

case "$1" in
  all)
    echo "Publishing all packages ..."
    cp $SOURCE_PATH/osv-loader.qemu $CAPSTAN_KERNEL_PATH
    cp $SOURCE_PATH/*.mpm $SOURCE_PATH/*.yaml $CAPSTAN_PACKAGES_PATH;;
  osv_loader_and_boostrap|run_java|run_go|node|openjdk10-java-base|httpserver_api|\
  httpserver_html5_gui|httpserver_html5_cli|cli|lighttpd|nginx|iperf|netperf|redis-memonly|memcached|mysql)
    echo "Publishing package $1 ..."
    cp $SOURCE_PATH/osv.$1.mpm $SOURCE_PATH/osv.$1.yaml $CAPSTAN_PACKAGES_PATH;;
  *)
    echo "Unrecognised which package to publish!"
esac
