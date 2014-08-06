#!/bin/bash 
#create by HGM
#create_time: 2014-08-02
#jvm调优工具集


#1.jps  主要用来输出JVM中运行的进程状态信息

# 命令行参数选项说明如下：
#-q 不输出类名、Jar名和传入main方法的参数
#-m 输出传入main方法的参数
#-l 输出main类或Jar的全限名
#-v 输出传入JVM的参数

#Exp:查看jvm中运行的进程id和主类
function Jps (){
jps -m  -l 
}

#2.jstack  主要用来查看某个Java进程内的线程堆栈信息

#语法格式如下：
#-l long listings，会打印出额外的锁信息，在发生死锁时可以用jstack -l pid来观察锁持有情况
#-m mixed mode，不仅会输出Java堆栈信息，还会输出C/C++堆栈信息（比如Native方法）


#Exp:查看某应用的进程id  $1为应用名关键字
function LookJavaPid(){
ps aux |grep "$1" |grep -v grep | grep  -v "debugjvm.sh" |awk '{print $2}'
}


#Exp:查找当前时间某进程最消耗CPU的线程id的堆栈信息
function LookMaxThread(){
pidnum=$(LookJavaPid $1 |wc -l)
if [[ $pidnum -ne 1 ]];then
echo "  返回进程ID不唯一,请确认进程关键字是否正确!"
exit
fi
pid=$(LookJavaPid $1)
top_info=$(top -Hp $pid -n 1   |grep -A  10000  "TIME")
max_time_key=$(echo "$top_info" |awk '{print $(NF-2)}' |grep -v "TIME"   |sort -rnu  |head -n 1)
max_pid=$(echo "$top_info" |grep "$max_time_key" |awk '{print $2}')
max_key=$(printf "%x\n" $max_pid)
max_thread_info=$(jstack  $pid | grep -A 100  --color "$max_key" | sed -n '/1c97/,/prio/p' |sed '$d')
max_main_class=$(echo $max_thread_info| head -n 1 |awk '{print $1}')
echo   "  当前时间消耗CPU最大的jvm线程主类为: $max_main_class" 
echo -e "  当前时间消耗CPU最大的jvm线程详细信息: \r\n$max_thread_info"

}

#---使用示例: LookMaxThread "org.apache.catalina.startup.Bootstrap"

#3.jmap（Memory Map）和jhat（Java Heap Analysis Tool）   jmap用来查看堆内存使用状况，一般结合jhat使用.

#    jmap语法格式如下：
#jmap [option] pid
#jmap -heap pid查看进程堆内存使用情况，包括使用的GC算法、堆配置参数和各代中堆内存使用情况。

#Exp:jmap查看进程堆内存使用情况 
function LookThreadMem(){
jmap -heap $(LookJavaPid $1) 
}

#---使用示例: LookThreadMem "org.apache.catalina.startup.Bootstrap"

#Exp:jmap查看堆内存中的对象数目、大小统计直方图，如果带上live则只统计活对象
function LookThreadMemLive(){
livelog=/tmp/MemLive_log_$(date +%Y%m%d_%H%M%S).log
jmap -histo:live $(LookJavaPid $1) > $livelog
echo "  该服务器状态为live时,堆内存中的对象数目、大小统计直方图保存在: $livelog"
}

#---使用示例: LookThreadMemLive "org.apache.catalina.startup.Bootstrap"

#Exp: jhat分析查看jmap进程堆情况,通过web查看端口1999
#通过搜索关键字: Other Queries 搜索所有实例的数量以及类内存使用情况
function LookThreadMemWeb(){
jmap -dump:format=b,file=/tmp/dump.dat $(LookJavaPid $1)
jhat -J-Xmx4096m -port 1999 /tmp/dump.dat  
}

#---使用示例: LookThreadMemWeb "org.apache.catalina.startup.Bootstrap" 


#4.jstat JVM统计监测工具

# 语法格式如下：
#jstat [ generalOption | outputOptions vmid [interval[s|ms] [count]] ]
#vmid是Java虚拟机ID，在Linux/Unix系统上一般就是进程ID。interval是采样时间间隔。count是采样数目。
#jstat -gc 21711 250 4: 输出的是GC信息，采样时间间隔为250ms，采样数为4

#Exp: jvm统计监测
#堆内存 = 年轻代 + 年老代 + 永久代
#年轻代 = Eden区 + 两个Survivor区（From和To）
#S0C、S1C、S0U、S1U：Survivor 0/1区容量（Capacity）和使用量（Used）
#EC、EU：Eden区容量和使用量
#OC、OU：年老代容量和使用量
#PC、PU：永久代容量和使用量
#YGC、YGT：年轻代GC次数和GC耗时
#FGC、FGCT：Full GC次数和Full GC耗时
#GCT：GC总耗时
function StaticThread(){
jstat -gc $(LookJavaPid $1) 250 4
}

#---使用示例: StaticThread "org.apache.catalina.startup.Bootstrap" 


#5.jinfo  查看运行中的java程序的运行环境参数
function LookJavaArgs(){
jinfo $(LookJavaPid $1)
}

#---使用示例: LookJavaArgs "org.apache.catalina.startup.Bootstrap" 

#6.jstack 打印JAVA堆栈信息到/tmp目录,并统计分析
function PrintJavaThread(){
thread_log=/tmp/Thread_$(date +%Y%m%d_%H%M%S).log
jstack $(LookJavaPid $1)  > $thread_log
runnable=$(cat $thread_log |grep  " runnable "|wc -l)
waitable=$(cat $thread_log |grep " waiting on condition "|wc -l)
#如果发现有大量的线程都在处在 Wait on condition，从线程 stack看， 正等待网络读写，这可能是一个网络瓶颈的征兆.
hot_test=$(cat $thread_log |grep "Waiting for monitor entry"|wc -l)
hot_test1=$(cat $thread_log |grep "Wait on monito"|wc -l)
total_hot=$(expr $hot_test + $hot_test1)

echo "  该$1正在运行的线程数为: $runnable"
echo "  该$1正在等待的线程数为: $waitable"
echo "  该$1正在处于热锁的线程数约为: $total_hot"
if [[ $total_hot -gt $runnable    ]];then
echo "  该$1热锁数量过多,请查看相关日志!"
fi 
echo "  堆栈信息保存在: $thread_log"
}

#PrintJavaThread "org.apache.catalina.startup.Bootstrap" 

#查看线程的总数以及阻塞的线程的个数
function LookBlockedStatus(){
threadblock_log=/tmp/ThreadBlocked_$(date +%Y%m%d_%H%M%S).log
jstack -F $(LookJavaPid $1)  > $threadblock_log 2>&1
total_thread=$(cat $threadblock_log |grep "state =" |wc -l 2>&1)
total_block=$(cat $threadblock_log |grep "state = BLOCKED" |wc -l 2>&1)
total_deadlock=$(cat $threadblock_log |grep "No deadlocks found" |wc -l 2>&1)
echo "  该$1线程的总数为: $total_thread"
echo "  该$1阻塞线程数为: $total_block"
if [[ $total_deadlock -eq 1  ]];then
echo  "  该$1无死锁..."
else
echo  "  该$1有死锁存在..."
fi
echo "  堆栈信息保存在: $threadblock_log"
}

#---使用示例: LookBlockedStatus "org.apache.catalina.startup.Bootstrap"

function LookSysStatus(){
network_log=/tmp/networkstatics_$(date +%Y%m%d_%H%M%S).log
realcpu=$(cat /proc/cpuinfo |grep "physical id"|sort |uniq|wc -l)
logicpcu=$(cat /proc/cpuinfo |grep "processor"|wc -l)
everycpu=$(cat /proc/cpuinfo |grep "cores"|uniq |awk '{print $4}')
totalmem=$(free -m |grep "Mem:" |awk '{print $2}')
appusedmem=$(free -m |grep "cache"   |grep  -v "used" |awk '{print $3}')
appfreemem=$(free -m |grep "cache"   |grep  -v "used" |awk '{print $4}')
averload=$(w |grep "average" |awk '{print $(NF-2)}' |sed 's/,//')
netrecord=$(netstat -n > $network_log )
tcpstatics=$(cat $network_log | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}')
max_ESTABLISHED=$(cat $network_log |grep "ESTABLISHED" |awk '{print $(NF-1)}'  |awk -F':' '{print $(NF-1)}' |sort|uniq -c |sort -nr |head -n 10 >/tmp/max_establed.log )
max_TIME_WAIT=$(cat $network_log |grep "TIME_WAIT" |awk '{print $(NF-1)}'  |awk -F':' '{print $(NF-1)}' |sort|uniq -c |sort -nr |head -n 10 >/tmp/max_timewait.log )
echo " 真实物理CPU核数: $realcpu ,逻辑物理CPU核数: $logicpcu [一般看这个参数] ,每个CPU核数:$everycpu [Intel的U,支持超线程*2]"
echo " 总共的物理内存:$totalmem"M" ,程序使用的内存:$appusedmem"M" ,还剩余的内存为:$appfreemem"M""
echo " 当前服务器的负载情况:$averload [一般情况下大于10就已经很高了]"
echo -e " 当前服务器的TCP的连接情况如下: \r\n $tcpstatics"
echo " 当前服务器的tcp连接详细情况保存在: $network_log"
echo " 当前服务器已经建立的连接前10位IP为:"
echo "    数量  本地地址:端口 -->  远程连接IP [数量] "
for i in `cat /tmp/max_establed.log |awk '{print $2}'`
do
num=$(cat /tmp/max_establed.log |grep "$i" |awk '{print $1}')
localport=$(cat $network_log  |grep "ESTABLISHED" |grep "$i"  |awk '{print $4}' |sed 's/::ffff://'  |sort|uniq -c|sort -nr)

echo "$localport --> $i [$num]"
echo "---------------------------------------"
done 

echo " 当前服务器已经处于TIME_WAIT的连接前10位IP为:"
echo "    数量  本地地址:端口 -->  远程连接IP"
for i in `cat /tmp/max_timewait.log |awk '{print $2}'`
do

num=$(cat /tmp/max_timewait.log |grep "$i" |awk '{print $1}')
localport=$(cat $network_log  |grep "TIME_WAIT" |grep "$i"  |awk '{print $4}' |sed 's/::ffff://'  |sort|uniq -c|sort -nr)

echo "$localport --> $i [$num]"
echo "---------------------------------------"
done


}


#--- LookSysStatus
function YewuStatics(){
curl -s  "http://im.baoxian.com/plugins/online/status"    -o /tmp/test.html  2>&1
dailiren=$(sed 's/,/\n/g'  /tmp/test.html  |wc -l)
echo "  该时刻在线代理人数为: $dailiren"
}

#YewuStatics

[[ -d /data/log/statics  ]] || mkdir -p /data/log/statics 


if [[ ! -z $1 || ! -z $2  ]];then
if [[ $1 == "commbine"   ]];then
runlist="
Jps
LookMaxThread
LookThreadMem
LookThreadMemLive
LookThreadMemWeb
StaticThread
LookJavaArgs
PrintJavaThread
LookBlockedStatus
LookSysStatus
YewuStatics
"
key="$2"
echo $runlist |sed 's/ /\n/g' |awk '{print NR,$0}' > /tmp/row.txt
savelog=statics__$(date +%Y%m%d_%H%M%S).log
echo "输出日志保存在: /data/log/statics/$savelog"
for i in `echo "$key"  |sed 's/,/\n/g'`
do
run=$(cat /tmp/row.txt |grep "^$i" |awk '{print $2}')
echo "$run  $3"
sleep 1
echo "[ $run: ] " >> /data/log/statics/$savelog
$run  $3  >>/data/log/statics/$savelog
echo "---------------------------------------------------------------------"  >> /data/log/statics/$savelog
echo "---------------------------------------------------------------------"  >> /data/log/statics/$savelog
done

else
$1 $2
fi 
else

echo -e "debugjvm.sh 调试同工具集\n\r"
echo "Tips: tomcat进程关键字为:org.apache.catalina.startup.Bootstrap"
echo " <1> 查看jvm中运行的进程id和主类"
echo -e "     Exp: ./debugjvm.sh Jps\n\r"

echo " <2> 查找当前时间某进程最消耗CPU的线程id的堆栈信息"
echo -e  "     Exp: ./debugjvm.sh  LookMaxThread "org.apache.catalina.startup.Bootstrap"\r\n"

echo " <3> 查看进程堆内存使用情况 "
echo -e "     Exp: ./debugjvm.sh  LookThreadMem "org.apache.catalina.startup.Bootstrap"\r\n"

echo " <4> 查看堆内存中的对象数目、大小统计直方图，只统计活对象"
echo -e "     Exp: ./debugjvm.sh LookThreadMemLive "org.apache.catalina.startup.Bootstrap"\n\r"

echo " <5> 分析查看jmap进程堆情况,通过web查看端口1999"
echo "     通过搜索关键字: Other Queries 搜索所有实例的数量以及类内存使用情况"
echo -e  "     Exp: ./debugjvm.sh LookThreadMemWeb "org.apache.catalina.startup.Bootstrap"\r\n"

echo " <6> jvm统计监测 统计堆内存,GC等"
echo -e "     Exp: ./debugjvm.sh StaticThread "org.apache.catalina.startup.Bootstrap"\r\n"

echo " <7> 查看运行中的java程序的运行环境参数"
echo -e  "     Exp: ./debugjvm.sh LookJavaArgs "org.apache.catalina.startup.Bootstrap"\n\r"

echo " <8> 打印JAVA堆栈信息到/tmp目录,并统计分析"
echo -e "     Exp: ./debugjvm.sh PrintJavaThread "org.apache.catalina.startup.Bootstrap"\r\n"

echo " <9> 查看线程的总数以及阻塞的线程的个数"
echo -e "     Exp: ./debugjvm.sh LookBlockedStatus "org.apache.catalina.startup.Bootstrap"\r\n"

echo " <10> 查看服务器此时的系统状态"
echo -e "     Exp: ./debugjvm.sh LookSysStatus\r\n"

echo " <11> 查看当前代理人在线数"
echo -e  "     Exp: ./debugjvm.sh YewuStatics\r\n"

echo " 常用调试命令集合:"
echo " 组合以上 2,3,4,6,8,9,10"
echo -e  "     Exp: ./debugjvm.sh commbine 2,3,4,6,8,9,10 "org.apache.catalina.startup.Bootstrap"\r\n"

fi
