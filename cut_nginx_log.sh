#!/bin/bash
# This script run at 00:00
##### crontab setting 
##### 1 0 * * * /usr/local/nginx/sbin/cut_nginx_log.sh > /dev/null 2>1
# The Nginx logs path

logs_path="/data/log/nginx/"
Year=$(date -d "yesterday" +"%Y")
Month=$(date -d "yesterday" +"%m")
YMD=$(date -d "yesterday" +"%Y%m%d")

[ ! -d ${logs_path}$Year/$Month/ ] && mkdir -p ${logs_path}$Year/$Month/
mv ${logs_path}access.log ${logs_path}$Year/$Month/access_$YMD.log
kill -USR1 `cat /usr/local/nginx/logs/nginx.pid`