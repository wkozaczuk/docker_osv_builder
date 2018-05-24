#!/bin/bash

source $(dirname $0)/commons.sh

create_all_packages() {
  clean_osv

  build_osv_loader_and_boostrap_package
  build_run_java_package
  build_run_go_package
  build_node_package

  build_httpserver_api_package
  build_httpserver_html5_gui_package
  build_httpserver_html5_cli_package
  build_cli_package

  build_lighttpd_package
  build_nginx_package
  build_iperf_package
  build_netperf_package
  build_redis_package
  build_memcached_package
  build_mysql_package
}
