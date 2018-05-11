#!/bin/bash
PACKAGE_BUILD_OR_IMPORT=${1-build}

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

build_or_import_package() {
  package_name="$1"
  cd $PACKAGES/$package_name && $CAPSTAN package $PACKAGE_BUILD_OR_IMPORT
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
  build_or_import_package "osv.bootstrap"
}

build_run_java_packages() {
  #Create run-java-isolated
  #build_osv "java-isolated" all none
  #prepare_package "osv.run-java-isolated" "Run Java apps in isolated mode" "0.0.1"
  #build_or_import_package "osv.run-java-isolated"

  #Create run-java-non-isolated
  build_osv "java-non-isolated" all none
  prepare_package "osv.run-java-non-isolated" "Run Java apps in non-isolated mode" "0.0.1"
  build_or_import_package "osv.run-java-non-isolated"
}

build_openjdk8-compact_profile_package() {
  profile="$1"
  version="$2"
  package_name="osv.openjdk8-zulu-compact$profile"
  build_osv "openjdk8-zulu-compact$profile" selected none
  prepare_package "$package_name" "Zulu Open JDK 8 compact profile $profile1" "$version"
  cd $PACKAGES/${package_name}/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact${profile}-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build_or_import_package "$package_name"
}

build_openjdk8-full_package() {
  version="$1"
  package_name="osv.openjdk8-zulu-full"
  build_osv "openjdk8-zulu-full" selected none
  prepare_package "$package_name" "Zulu Open JDK 8" "$version"
  #cd $PACKAGES/osv.openjdk8-zulu-full/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact${profile}-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build_or_import_package "$package_name"
}

build_openjdk8-zulu-compact3-with-java-beans_package() {
  version="$1"
  package_name="osv.openjdk8-zulu-compact3-with-java-beans"
  build_osv "openjdk8-zulu-compact3-with-java-beans" selected none
  prepare_package "$package_name" "Zulu Open JDK 8 with java.beans" "$version"
  cd $PACKAGES/${package_name}/usr/lib/jvm/ && rm jre && rmdir java && ln -s j2re-compact3-with-java-beans-image/jre jre
  cd $PACKAGES/${package_name} && cp $OSV_ROOT/modules/ca-certificates/build/etc/pki/ca-trust/extracted/java/cacerts usr/lib/jvm/jre/lib/security/
  build_or_import_package "$package_name"
}

build_httpserver_api_package() {
  build_osv "httpserver-api" all none
  prepare_package "osv.httpserver-api" "OSv httpserver with APIs" "0.0.1"
  rm $PACKAGES/osv.httpserver-api/usr/mgmt/plugins/libhttpserver-api_api.so  
  rm $PACKAGES/osv.httpserver-api/usr/mgmt/plugins/libhttpserver-api_app.so  
  rm $PACKAGES/osv.httpserver-api/usr/mgmt/plugins/libhttpserver-api_env.so  
  rm $PACKAGES/osv.httpserver-api/usr/mgmt/plugins/libhttpserver-api_network.so  
  rm $PACKAGES/osv.httpserver-api/usr/mgmt/plugins/libhttpserver-api_trace.so
  build_or_import_package "osv.httpserver-api"
}

build_httpserver_html5_gui_package() {
  build_osv "httpserver-html5-gui" selected none
  prepare_package "osv.httpserver-html5-gui" "OSv html5 GUI" "0.0.1"
  rm -rf $PACKAGES/osv.httpserver-html5-gui/init/
  build_or_import_package "osv.httpserver-html5-gui"
}

build_httpserver_html5_cli_package() {
  build_osv "httpserver-html5-cli" selected none
  prepare_package "osv.httpserver-html5-cli" "OSv html5 cli" "0.0.1"
  rm -rf $PACKAGES/osv.httpserver-html5-cli/init/
  build_or_import_package "osv.httpserver-html5-cli"
}

build_node_package() {
  build_osv "node" all none
  prepare_package "osv.node-6.1" "Node 6.1" "6.1"
  build_or_import_package "osv.node-6.1"
}

build_lighttpd() {
  build_osv "lighttpd" all none
  prepare_package "osv.lighttpd" "Lighttpd" "1.4.45"
  build_or_import_package "osv.lighttpd"
}

build_nginx() {
  build_osv "nginx" all none
  prepare_package "osv.nginx" "nginx" "1.12.1"
  build_or_import_package "osv.nginx"
}

#clean_osv

#build_osv_loader_and_boostrap_package
#build_run_java_packages

####build_openjdk8-compact_profile_package 1 "8.0.144" #Should be identified automatically
####build_openjdk8-zulu-compact3-with-java-beans_package "8.0.144"
####build_openjdk8-full_package "8.0.144"

#build_httpserver_api_package
#build_httpserver_html5_gui_package
build_httpserver_html5_cli_package

#build_node_package
#build_lighttpd
#build_nginx

#TODO - Java 9, nginx, 
#Moze - python, ruby, erlang
