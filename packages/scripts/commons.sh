#!/bin/bash

source $(dirname $0)/env.sh
OSV_BUILD=$OSV_ROOT/build/release
OSV_VERSION="0.51.0"

clean_osv() {
  cd "$OSV_ROOT"
  ./scripts/build clean
}

build_osv() {
  image="$1"
  export_mode="$2"
  usrskel="$3"

  echo "-------------------------------------"
  echo "- Building OSv image $image ...      "
  echo "-------------------------------------"

  cd "$OSV_ROOT"
  ./scripts/build -j4 image="$image" export="$export_mode" usrskel="$usrskel"

  echo "-------------------------------------"
  echo "- Built OSv image $image             "
  echo "-------------------------------------"
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

build_package() {
  package_name="$1"
  cd $PACKAGES/$package_name && $CAPSTAN package build
  mv $PACKAGES/$package_name/$package_name.mpm $OUTPUT && rm -rf $PACKAGES/$package_name

  echo "-------------------------------------"
  echo "- Built package $package_name        "
  echo "-------------------------------------"
}

build_osv_loader_and_boostrap_package() {
  #Build osv.loader and files that will make up bootstrap package
  build_osv empty all default

  #Copy loader.img as osv-loader.qemu
  mkdir -p $PACKAGES/osv.loader
  cp $OSV_BUILD/loader.img $PACKAGES/osv.loader/osv-loader.qemu
  mkdir -p $CAPSTAN_LOCAL_REPO/repository/mike/osv-loader/
  cp $PACKAGES/osv.loader/osv-loader.qemu $CAPSTAN_LOCAL_REPO/repository/mike/osv-loader/
  cp $PACKAGES/osv.loader/osv-loader.qemu $OUTPUT

  #Create bootstrap package
  prepare_package "osv.bootstrap" "OSv Bootstrap" "$OSV_VERSION"
  rm $PACKAGES/osv.bootstrap/tools/mount-nfs.so
  rm $PACKAGES/osv.bootstrap/tools/umount.so
  build_package "osv.bootstrap"
}

build_run_java_package() {
  build_osv "java-non-isolated" all none
  prepare_package "osv.run-java" "Run Java apps" "$OSV_VERSION"
  build_package "osv.run-java"
}

build_run_go_package() {
  build_osv "golang" all none
  prepare_package "osv.run-go" "Run Golang apps" "$OSV_VERSION"
  build_package "osv.run-go"
}

build_openjdk8-compact_profile_package() {
  profile="$1"
  version="$2"
  package_name="osv.openjdk8-zulu-compact$profile"
  build_osv "openjdk8-zulu-compact$profile" selected none
  prepare_package "$package_name" "Zulu Open JDK 8 compact profile $profile1" "$version"
  cd $PACKAGES/${package_name}/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact${profile}-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build_package "$package_name"
}

build_openjdk8-full_package() {
  version="$1"
  package_name="osv.openjdk8-zulu-full"
  build_osv "openjdk8-zulu-full" selected none
  prepare_package "$package_name" "Zulu Open JDK 8" "$version"
  #cd $PACKAGES/osv.openjdk8-zulu-full/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact${profile}-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build_package "$package_name"
}

build_openjdk8-zulu-compact3-with-java-beans_package() {
  version="$1"
  package_name="osv.openjdk8-zulu-compact3-with-java-beans"
  build_osv "openjdk8-zulu-compact3-with-java-beans" selected none
  prepare_package "$package_name" "Zulu Open JDK 8 with java.beans" "$version"
  cd $PACKAGES/${package_name}/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact3-with-java-beans-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build_package "$package_name"
}

build_httpserver_api_package() {
  build_osv "httpserver-api" all none
  prepare_package "osv.httpserver-api" "OSv httpserver with APIs" "$OSV_VERSION"
  rm $PACKAGES/osv.httpserver-api/usr/mgmt/plugins/libhttpserver-api_app.so  
  build_package "osv.httpserver-api"
}

build_httpserver_html5_gui_package() {
  build_osv "httpserver-html5-gui" selected none
  prepare_package "osv.httpserver-html5-gui" "OSv HTML5 GUI" "$OSV_VERSION"
  rm -rf $PACKAGES/osv.httpserver-html5-gui/init/
  build_package "osv.httpserver-html5-gui"
}

build_httpserver_html5_cli_package() {
  build_osv "httpserver-html5-cli" selected none
  prepare_package "osv.httpserver-html5-cli" "OSv HTML5 cli" "$OSV_VERSION"
  rm -rf $PACKAGES/osv.httpserver-html5-cli/init/
  build_package "osv.httpserver-html5-cli"
}

build_node_package() {
  build_osv "node" all none
  prepare_package "osv.node-js" "Node JS" "8.11.2"
  build_package "osv.node-js"
}

build_cli_package() {
  build_osv "cli" all none
  prepare_package "osv.cli" "Command Line" "$OSV_VERSION"
  build_package "osv.cli"
}

build_lighttpd_package() {
  build_osv "lighttpd" all none
  prepare_package "osv.lighttpd" "Lighttpd" "1.4.45"
  build_package "osv.lighttpd"
}

build_nginx_package() {
  build_osv "nginx" all none
  prepare_package "osv.nginx" "NGINX" "1.12.2"
  build_package "osv.nginx"
}

build_iperf_package() {
  build_osv "iperf" all none
  prepare_package "osv.iperf" "Iperf" "2.0.5"
  build_package "osv.iperf"
}

build_netperf_package() {
  build_osv "netperf" all none
  prepare_package "osv.netperf" "Netperf" "2.7.0"
  build_package "osv.netperf"
}

build_redis_package() {
  build_osv "redis-memonly" all none
  prepare_package "osv.redis-memonly" "Redis" "3.2.8"
  build_package "osv.redis-memonly"
}

build_memcached_package() {
  build_osv "memcached" all none
  prepare_package "osv.memcached" "Memcached" "1.4.21"
  build_package "osv.memcached"
}

build_mysql_package() {
  build_osv "mysql" all none
  prepare_package "osv.mysql" "MySQL" "5.6.40"
  build_package "osv.mysql"
}
