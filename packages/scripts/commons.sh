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
  dependency="$4"

  rm -rf $PACKAGES/$package_name
  mkdir -p $PACKAGES/$package_name
  mkdir -p $OUTPUT/$package_name
  if [ "$dependency" == "" ]
  then
    cd $PACKAGES/$package_name && $CAPSTAN package init --name "$package_name" --title "$title" --author "Waldek Kozaczuk" --version "$version"
  else
    cd $PACKAGES/$package_name && $CAPSTAN package init --name "$package_name" --title "$title" --author "Waldek Kozaczuk" --version "$version" --require "$dependency"
  fi
  cp $PACKAGES/$package_name/meta/package.yaml $OUTPUT/${package_name}.yaml
  cp -rf $OSV_ROOT/build/export/. $PACKAGES/$package_name
}

set_package_command_line() {
  package_name="$1"
  command_line="$2"
  mkdir -p $PACKAGES/$package_name/meta
  cat << EOF > $PACKAGES/$package_name/meta/run.yaml
runtime: native
config_set:
  default:
    bootcmd: "$command_line"
config_set_default: default
EOF
}

build_package() {
  package_name="$1"
  cd $PACKAGES/$package_name && $CAPSTAN package build
  mv $PACKAGES/$package_name/$package_name.mpm $OUTPUT && rm -rf $PACKAGES/$package_name

  echo "-------------------------------------"
  echo "- Built package $package_name        "
  echo "-------------------------------------"
}

build_osv_loader_and_bootstrap_package() {
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
  prepare_package "$package_name" "Zulu Open JDK 8 compact profile $profile1" "$version" "osv.run-java"
  cd $PACKAGES/${package_name}/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact${profile}-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build_package "$package_name"
}

build_openjdk8-full_package() {
  version="$1"
  package_name="osv.openjdk8-zulu-full"
  build_osv "openjdk8-zulu-full" selected none
  prepare_package "$package_name" "Zulu Open JDK 8" "$version" "osv.run-java"
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build_package "$package_name"
}

build_openjdk8-zulu-compact3-with-java-beans_package() {
  version="$1"
  package_name="osv.openjdk8-zulu-compact3-with-java-beans"
  build_osv "openjdk8-zulu-compact3-with-java-beans" selected none
  prepare_package "$package_name" "Zulu Open JDK 8 with java.beans" "$version" "osv.run-java"
  cd $PACKAGES/${package_name}/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact3-with-java-beans-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build_package "$package_name"
}

build_openjdk10-java-base_package() {
  package_name="osv.openjdk10-java-base"
  build_osv "openjdk10-java-base" selected none
  prepare_package "$package_name" "Open JDK 10 (java-base)" "10.0.1" "osv.run-java"
  cd $PACKAGES/${package_name}/usr/lib/jvm/ && rmdir java && ln -s jdk-10.0.1-java-base/ java
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/java/lib/security/
  build_package "$package_name"
}

# Needs /init/xx_auto_yy file with '/libhttpserver-api.so &!' to make it run automatically
build_httpserver_api_package() {
  build_osv "httpserver-api.fg" all none
  prepare_package "osv.httpserver-api" "OSv httpserver with APIs (backend)" "$OSV_VERSION"
  rm $PACKAGES/osv.httpserver-api/usr/mgmt/plugins/libhttpserver-api_app.so  
  build_package "osv.httpserver-api"
}

build_httpserver_html5_gui_package() {
  build_osv "httpserver-html5-gui" selected none
  prepare_package "osv.httpserver-html5-gui" "OSv HTML5 GUI (frontend)" "$OSV_VERSION" "osv.httpserver-api"
  rm -rf $PACKAGES/osv.httpserver-html5-gui/init/
  set_package_command_line "osv.httpserver-html5-gui" "/libhttpserver-api.so"
  build_package "osv.httpserver-html5-gui"
}

build_httpserver_html5_cli_package() {
  build_osv "httpserver-html5-cli" selected none
  prepare_package "osv.httpserver-html5-cli" "OSv HTML5 Terminal (frontend)" "$OSV_VERSION" "osv.httpserver-api"
  rm -rf $PACKAGES/osv.httpserver-html5-cli/init/
  set_package_command_line "osv.httpserver-html5-cli" "/libhttpserver-api.so"
  build_package "osv.httpserver-html5-cli"
}

build_node_package() {
  build_osv "node" all none
  prepare_package "osv.node-js" "Node JS" "8.11.2"
  build_package "osv.node-js"
}

build_cli_package() {
  apt-get install -y openssl1.0 libssl1.0-dev
  build_osv "cli" all none
  apt-get install -y libssl-dev node-gyp nodejs-dev npm
  prepare_package "osv.cli" "Command Line" "$OSV_VERSION" "osv.httpserver-api"
  set_package_command_line "osv.cli" "/cli/cli.so"
  build_package "osv.cli"
}

build_lighttpd_package() {
  build_osv "lighttpd" all none
  prepare_package "osv.lighttpd" "Lighttpd" "1.4.45"
  set_package_command_line "osv.lighttpd" "/lighttpd.so -D -f /lighttpd/lighttpd.conf"
  build_package "osv.lighttpd"
}

build_nginx_package() {
  build_osv "nginx" all none
  prepare_package "osv.nginx" "NGINX" "1.12.2"
  set_package_command_line "osv.nginx" "/nginx.so -c /nginx/conf/nginx.conf"
  build_package "osv.nginx"
}

build_iperf_package() {
  build_osv "iperf" all none
  prepare_package "osv.iperf" "Iperf" "2.0.5"
  set_package_command_line "osv.iperf" "/tools/iperf -s"
  build_package "osv.iperf"
}

build_netperf_package() {
  build_osv "netperf" all none
  prepare_package "osv.netperf" "Netperf" "2.7.0"
  set_package_command_line "osv.netperf" "/tools/netserver.so -D -4 -f"
  build_package "osv.netperf"
}

build_redis_package() {
  build_osv "redis-memonly" all none
  prepare_package "osv.redis-memonly" "Redis" "3.2.8"
  set_package_command_line "osv.redis-memonly" "/redis-server redis.conf"
  build_package "osv.redis-memonly"
}

build_memcached_package() {
  build_osv "memcached" all none
  prepare_package "osv.memcached" "Memcached" "1.4.21"
  set_package_command_line "osv.memcached" '/memcached -t $OSV_CPUS -u root'
  build_package "osv.memcached"
}

build_mysql_package() {
  build_osv "mysql" all none
  prepare_package "osv.mysql" "MySQL" "5.6.40"
  set_package_command_line "osv.mysql" "/usr/bin/mysqld --datadir=/usr/data --user=root"
  build_package "osv.mysql"
}

build_generic_app_package() {
  app_name="$1"
  version="$2"
  command_line="$3"
  build_osv "$app_name" selected none
  prepare_package "osv.$app_name" "$app_name" "$version"
  set_package_command_line "$app_name" "$command_line"
  build_package "$app_name"
}
