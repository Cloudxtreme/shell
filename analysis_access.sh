#!/bin/bash
#Date create 2013-10-23
#Author lsh
#nginx格式：
#log_format main '$remote_addr - $remote_user [$time_local] $request ' '"$status" $body_bytes_sent "$http_referer" ' '"$http_user_agent" "$http_x_forwarded_for"';
#例子：
#221.194.30.151 - - [21/Jan/2014:12:03:49 +0800] "POST /cpmap/access/ HTTP/1.1" 200 803 "-" "msm-android-async-http/1.3.1"
log_path=aaa
log_dir=/home/liangshuhua
domain="crm.baoxian.in"
email="530035210@qq.com"
maketime=$(date +"%Y-%m-%d %H:%M")
logdate=$(date -d "yesterday" +%Y-%m-%d)
dayone=$(date +%d/%b/%Y)
now=$(date +%Y_%m%d_%H%M)

date_start=$(date +%s)
total_visit=`wc -l ${log_path} | awk '{print $1}'`
total_bandwidth=`awk -v total=0 '{total+=$10}END{print total/1024/1024}' ${log_path}`
total_unique=`awk '{ip[$1]++}END{print asort(ip)}' ${log_path}`
ip_pv=`awk '{ip[$1]++}END{for (k in ip){print ip[k],k}}' ${log_path} | sort -rn |head -20`
url_num=`awk '{url[$7]++}END{for (k in url){print url[k],k}}' ${log_path} | sort -rn | head -20`
#referer=`awk -v domain=$domain '$11 !~ /http:\/\/[^/]*'"$domain"'/{url[$11]++}END{for (k in url){print url[k],k}}' ${log_path} | sort -rn `
notfound=`awk '$9 == 404 {url[$7]++}END{for (k in url){print url[k],k}}' ${log_path} | sort -rn | head -20`

#spider=`awk -F'"' '$6 ~ /Baiduspider/ {spider["baiduspider"]++} $6 ~ /Googlebot/ {spider["googlebot"]++}END{for (k in spider){print k,spider[k]}}'  ${log_path}`
#search=`awk -F'"' '$4 ~ /http:\/\/www\.baidu\.com/ {search["baidu_search"]++} $4 ~ /http:\/\/www\.google\.com/ {search["google_search"]++}END{for (k in search){print k,search[k]}}' ${log_path}`
#echo -e "概况\n报告生成时间：${maketime}\n总访问量:${total_visit}\n总带宽:${total_bandwidth}M\n独立访客:${total_unique}\n\n访问IP统计\n${ip_pv}\n\n访问url(统计前20个页面)\n${url_num}\n\n来源页面统计\n${referer}\n\n404统计(统计前20个页面)\n${notfound}\n\n蜘蛛统计\n${spider}\n\n搜索引擎来源统计\n${search}"  

#统计该ip在干些什么
max_ip=`awk '{ip[$1]++}END{for (k in ip){print ip[k],k}}' ${log_path} | sort -rn |head -1 |awk '{print $2}'`
ip_havi=`cat $log_path | grep "$max_ip" | awk '{print $7}'| sort |uniq -c |sort -nr |head -20`
#统计当天哪个时间段访问量最多
time_stats=`awk '{print $4}' ${log_path}  | grep "$dayone" |cut -c 14-18 |sort|uniq -c|sort -nr |head -n 10`

echo -e "概况\n报告生成时间：${maketime}\n总访问量:${total_visit}\n总带宽:${total_bandwidth}M\n独立访客:${total_unique}\n\n访问IP统计(统计前20个IP):\n${ip_pv}\n\n访问url最多(统计前20个页面):\n${url_num}\n\n404统计(统计前20个页面):\n${notfound}\n\n当天访问次数最多的时间段如下:\n${time_stats}\n\n访问量最高的IP[${max_ip}]前20个最多的页面如下:\n${ip_havi} "

[[ -d $log_dir  ]] || mkdir -p $log_dir

echo -e "概况\n报告生成时间：${maketime}\n总访问量:${total_visit}\n总带宽:${total_bandwidth}M\n独立访客:${total_unique}\n\n访问IP统计(统计前20个IP):\n${ip_pv}\n\n访问url最多(统计前20个页面):\n${url_num}\n\n404统计(统计前20个页面):\n${notfound}\n\n当天访问次数最多的时间段如下:\n${time_stats}\n\n访问量最高的IP[${max_ip}]前20个最多的页面如下:\n${ip_havi} " > $log_dir/analysis_access$now.log
date_end=$(date +%s)
time_take=$(($date_end-$date_start))
take_time=$(($time_take/60))
take_time=$(echo "scale=2; $time_take/60" | bc)

echo "access统计脚本分析日志花费了: [start:$date_start end:$date_end] $time_take"s"  $take_time"min""
echo "access统计脚本分析日志花费了: [start:$date_start end:$date_end] $time_take"s"  $take_time"min"" >> $log_dir/analysis_access$now.log


