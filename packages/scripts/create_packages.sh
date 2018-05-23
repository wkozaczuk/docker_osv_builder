#!/bin/bash

source $(dirname $0)/env.sh
OSV_BUILD=$OSV_ROOT/build/release

clean_osv() {
  cd "$OSV_ROOT"
  ./scripts/build clean
}

build_osv() {
  image="$1"
  export_mode="$2"
  usrskel="$3"

  cd "$OSV_ROOT"
  ./scripts/build -j4 image="$image" export="$export_mode" usrskel="$usrskel"
}

prepare_package() {
  package_name="$1"
  title="$2"
  version="$3"

  rm -rf $PACKAGES/$package_name
  mkdir -p $PACKAGES/$package_name
  cd $PACKAGES/$package_name && $CAPSTAN package init --name "$package_name" --title "$title" --author "Waldek Kozaczuk" --version "$version"
  cp -rf $OSV_ROOT/build/export/. $PACKAGES/$package_name
}

build() {
  package_name="$1"
  cd $PACKAGES/$package_name && $CAPSTAN package build
}

build_osv_loader_and_boostrap_package() {
  #Build osv.loader and files that will make up bootstrap package
  build_osv empty all default

  #Copy loader.img as osv-loader.qemu
  mkdir -p $PACKAGES/osv.loader
  cp $OSV_BUILD/loader.img $PACKAGES/osv.loader/osv-loader.qemu
  mkdir -p $CAPSTAN_LOCAL_REPO/repository/mike/osv-loader/
  cp $PACKAGES/osv.loader/osv-loader.qemu $CAPSTAN_LOCAL_REPO/repository/mike/osv-loader/

  #Create bootstrap package
  prepare_package "osv.bootstrap" "OSv Bootstrap" "0.0.1"
  rm $PACKAGES/osv.bootstrap/tools/mount-nfs.so
  rm $PACKAGES/osv.bootstrap/tools/umount.so
  build "osv.bootstrap"
}

build_run_java_package() {
  #Create run-java-non-isolated
  build_osv "java-non-isolated" all none
  prepare_package "osv.run-java" "Run Java apps" "0.0.1"
  build "osv.run-java"
}

build_run_go_package() {
  #Create run-go-non-isolated
  build_osv "golang" all none
  prepare_package "osv.run-go" "Run Golang apps" "0.0.1"
  build "osv.run-go"
}

build_openjdk8-compact_profile_package() {
  profile="$1"
  version="$2"
  package_name="osv.openjdk8-zulu-compact$profile"
  build_osv "openjdk8-zulu-compact$profile" selected none
  prepare_package "$package_name" "Zulu Open JDK 8 compact profile $profile1" "$version"
  cd $PACKAGES/${package_name}/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact${profile}-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build "$package_name"
}

build_openjdk8-full_package() {
  version="$1"
  package_name="osv.openjdk8-zulu-full"
  build_osv "openjdk8-zulu-full" selected none
  prepare_package "$package_name" "Zulu Open JDK 8" "$version"
  #cd $PACKAGES/osv.openjdk8-zulu-full/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact${profile}-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build "$package_name"
}

build_openjdk8-zulu-compact3-with-java-beans_package() {
  version="$1"
  package_name="osv.openjdk8-zulu-compact3-with-java-beans"
  build_osv "openjdk8-zulu-compact3-with-java-beans" selected none
  prepare_package "$package_name" "Zulu Open JDK 8 with java.beans" "$version"
  cd $PACKAGES/${package_name}/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact3-with-java-beans-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build "$package_name"
}

build_httpserver_api_package() {
  build_osv "httpserver-api" all none
  prepare_package "osv.httpserver-api" "OSv httpserver with APIs" "0.0.1"
  rm $PACKAGES/osv.httpserver-api/usr/mgmt/plugins/libhttpserver-api_app.so  
  build "osv.httpserver-api"
}

build_httpserver_html5_gui_package() {
  build_osv "httpserver-html5-gui" selected none
  prepare_package "osv.httpserver-html5-gui" "OSv html5 GUI" "0.0.1"
  rm -rf $PACKAGES/osv.httpserver-html5-gui/init/
  build "osv.httpserver-html5-gui"
}

build_httpserver_html5_cli_package() {
  build_osv "httpserver-html5-cli" selected none
  prepare_package "osv.httpserver-html5-cli" "OSv html5 cli" "0.0.1"
  rm -rf $PACKAGES/osv.httpserver-html5-cli/init/
  build "osv.httpserver-html5-cli"
}

build_node_package() {
  build_osv "node" all none
  prepare_package "osv.node-6.1" "Node 6.1" "6.1"
  build "osv.node-6.1"
}

build_cli() {
  build_osv "cli" all none
  prepare_package "osv.cli" "Lighttpd" "0.0.1"
  build "osv.cli"
}

build_lighttpd() {
  build_osv "lighttpd" all none
  prepare_package "osv.lighttpd" "Lighttpd" "1.4.45"
  build "osv.lighttpd"
}

build_nginx() {
  build_osv "nginx" all none
  prepare_package "osv.nginx" "nginx" "1.12.1"
  build "osv.nginx"
}

build_iperf() {
  build_osv "iperf" all none
  prepare_package "osv.iperf" "iperf" "2.0.5"
  build "osv.iperf"
}

build_netperf() {
  build_osv "netperf" all none
  prepare_package "osv.netperf" "netperf" "2.7.0"
  build "osv.netperf"
}

build_redis-memonly() {
  build_osv "redis-memonly" all none
  prepare_package "osv.redis-memonly" "redis-memonly" "3.2.8"
  build "osv.redis-memonly"
}

build_memcached() {
  build_osv "memcached" all none
  prepare_package "osv.memcached" "memcached" "2.7.0"
  build "osv.memcached"
}

build_mysql() {
  build_osv "mysql" all none
  prepare_package "osv.mysql" "mysql" "5.6.21"
  build "osv.mysql"
}

#clean_osv

#build_osv_loader_and_boostrap_package
#build_run_java_package
#build_run_go_package

#build_httpserver_api_package
#build_httpserver_html5_gui_package
#build_httpserver_html5_cli_package

#build_cli
#build_lighttpd
#build_nginx
#build_iperf
#build_redis-memonly
#build_memcached
#build_mysql
