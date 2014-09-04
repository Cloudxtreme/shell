#!/bin/bash

PATH=/usr/local/jdk/bin:/usr/local/mysql/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

# define directory
ROOT=/data/bw_mon/bw_datacollect
LOG=$ROOT/log
RUN=$ROOT/run

# tag file
RUN_TAG=$RUN/running.tag

# log file
LOG0=$LOG/bw_datacollect.log ; LOG1=$LOG0.1 ; LOG2=$LOG0.2 ; LOG3=$LOG0.3

# read configuration file
. $ROOT/conf/bw_datacollect.conf

# defile funtions
datef() { date "+%Y/%m/%d %H:%M:%S" ; }
print_to_log() { echo "[$(datef)] $1" >> $LOG0 ; }

LookJavaPid()
{    
        print_to_log "$FUNCNAME(): Begin."
        if [ $APPTYPE == "resin" ];then
	    filter="com.caucho.server.resin.Resin"
	elif [ $APPTYPE == "tomcat" ];then
	    filter="org.apache.catalina.startup.Bootstrap"
	elif [ $APPTYPE == "order" ];then
	    filter="com.baoxian.order.service.server.master.StartUp"
	elif [ $APPTYPE == "scheduler" ];then
	    filter="com.baoxian.scheduler.trial.ServerApp"
	else
	    filter="zzb.srvbox.BoxApp"
	fi
	pidunm=$(jps -m -l|grep $filter|wc -l)
        if [[ $pidunm -ne 1 ]];then
            print_to_log "$FUNCNAME(): 返回进程ID不唯一,或进程不存在,请确认!"
	    exit
	else
	    pid=$(jps -m -l|grep $filter|awk '{print $1}')
	    echo $pid
        fi
        print_to_log "$FUNCNAME(): End."
}

GetHeapUsage()
{       
        print_to_log "$FUNCNAME(): Begin."
        jmap -heap $(LookJavaPid) 2>/dev/null >/tmp/jmap
        NewGeneration=$(grep -A 4 "New Generation" /tmp/jmap|tail -n 1|awk '{print $1}'|cut -d . -f 1)
        EdenSpace=$(grep -A 4 "Eden Space" /tmp/jmap|tail -n 1|awk '{print $1}'|cut -d . -f 1)
        FromSpace=$(grep -A 4 "From Space" /tmp/jmap|tail -n 1|awk '{print $1}'|cut -d . -f 1)
        ToSpace=$(grep -A 4 "To Space" /tmp/jmap|tail -n 1|awk '{print $1}'|cut -d . -f 1)
        concurrent=$(grep -A 4 "concurrent" /tmp/jmap|tail -n 1|awk '{print $1}'|cut -d . -f 1)
        PermGeneration=$(grep -A 4 "Perm Generation" /tmp/jmap|tail -n 1|awk '{print $1}'|cut -d . -f 1)
        #echo $NewGeneration, $EdenSpace, $FromSpace, $ToSpace, $concurrent, $PermGeneration
        print_to_log "$FUNCNAME(): End."
}

InsertSql()
{       
        print_to_log "$FUNCNAME(): Begin."
        #echo $@
        #date "+%Y-%m-%d %H:%M:%S"
        if [[ "$1" =~ ^yunwei_data_part ]];then
            sql="INSERT INTO $1 VALUES('$2',$3,$4,$5,$6)"
        elif [[ "$1" =~ ^yingyong_part ]];then
            sql="INSERT INTO $1 VALUES('$2',$3,$4,$5,$6,$7,$8)"
        elif [[ "$1" =~ ^xitong_connect_cm ]];then
            sql="INSERT INTO $1 VALUES('$2',$3,$4,$5,$6,$7,$8,$9,${10},${11},${12},${13},${14},${15})"
        elif [[ "$1" =~ ^xitong_connect_carbiz ]] || [[ "$1" =~ ^xitong_connect_go ]];then
            sql="INSERT INTO $1 VALUES('$2',$3,$4,$5,$6,$7,$8,$9,${10},${11},${12},${13})"
        fi
        #echo $1
        #echo $sql
        #mysql -u${MYSQLUSER} -p${MYSQLPASS} -h${MYSQLHOST} ${MYSQLDATABASE} -e "${sql}"
        print_to_log "$FUNCNAME(): End."
}

InsertConnect()
{
        print_to_log "$FUNCNAME(): Begin."
        t=$(date +%s)
        netstat -nt |grep -v "127.0.0.1"|awk '/^tcp/ {print $5}' >/tmp/netstat
        num_go2=$(grep $GO2 /tmp/netstat |wc -l)
        num_cx=$(grep $CX /tmp/netstat |wc -l)
        num_cipm=$(grep $CIPM /tmp/netstat |wc -l)
        num_engine=$(grep $ENGINE /tmp/netstat |wc -l)
        num_b2b_biz=$(grep $B2B_BIZ /tmp/netstat |wc -l)
        num_b2bins=$(grep $B2BINS /tmp/netstat |wc -l)
        num_atm=$(grep $ATM /tmp/netstat |wc -l)
        num_ldap=$(grep $LDAP /tmp/netstat |wc -l)
        num_tc=$(grep $TC /tmp/netstat |wc -l)
        num_order=$(grep $ORDER /tmp/netstat |wc -l)
        num_xb=$(grep $XB /tmp/netstat |wc -l)
        num_image=$(grep $IMAGE /tmp/netstat |wc -l)
        num_cm=$(grep $CM /tmp/netstat |wc -l)
        num_rb=$(grep $RB /tmp/netstat |wc -l)
        num_foreign=$(grep -v 10\. /tmp/netstat |wc -l)
        if [[ "$APPLICATIONNAME" =~ ^carbiz ]] || [[ "$APPLICATIONNAME" =~ ^go ]];then
            A=("cx $num_cx" "cipm $num_cipm" "engine $num_engine" "b2b_biz $num_b2b_biz" "atm $num_atm" "ldap $num_ldap" "tc $num_tc" "order $num_order" "cm $num_cm" "rb $num_rb" "foreign $num_foreign")
        elif [[ "$APPLICATIONNAME" =~ ^cm ]];then
            A=("go2 $num_go2" "cx $num_cx" "cipm $num_cipm" "engine $num_engine" "b2b_biz $num_b2b_biz" "b2bins $num_b2bins" "atm $num_atm" "ldap $num_ldap" "tc $num_tc" "order $num_order" "xb $num_xb" "image $num_image" "foreign $num_foreign")

        fi
        for c in "${A[@]}"
        do
            echo xitong_shuju.part_$REGION.$APPLICATIONNAME.connect.$c $t |nc 10.143.66.187 2003
        done
        print_to_log "$FUNCNAME(): End."
}


InsertJvmHeapUsage()
{
       print_to_log "$FUNCNAME(): Begin."
       GetHeapUsage
       t=$(date +%s)
       A=("NewGeneration $NewGeneration" "EdenSpace $EdenSpace" "FromSpace $FromSpace" "ToSpace $ToSpace" "concurrent $concurrent" "PermGeneration $PermGeneration")
       for j in "${A[@]}"
       do 
           echo xitong_shuju.part_$REGION.$APPLICATIONNAME.JVM.$j $t |nc 10.143.66.187 2003
       done
       print_to_log "$FUNCNAME(): End." 
}

InsertQuoteVerifyInsurePay()
{
        print_to_log "$FUNCNAME(): Begin."
        T=$(date -I)
        S="SELECT (SELECT COUNT(1) FROM quote_task WHERE date_created>'${T} 00:00:00'),(SELECT COUNT(1) FROM verify_task WHERE date_created>'${T} 00:00:00'),(SELECT COUNT(1) FROM insure_task WHERE date_created>'${T} 00:00:00'),(SELECT COUNT(1) FROM order_info WHERE order_status!='CAN' and order_status!='FLR' and date_created>'${T} 00:00:00') FROM DUAL" 
        for s in $(seq 0 5)
        do
            if [ $s -eq 0 ]
            then
                Table="yunwei_data_part_one"
            fi
            if [ $s -eq 1 ]
            then
                Table="yunwei_data_part_two"
            fi
            if [ $s -eq 2 ]
            then
                Table="yunwei_data_part_three"
            fi
            if [ $s -eq 3 ]
            then
                Table="yunwei_data_part_four"
            fi
            if [ $s -eq 4 ]
            then
                Table="yunwei_data_part_five"
            fi
            if [ $s -eq 5 ]
            then
                Table="yunwei_data_part_six"
            fi
            #mysql -u${U} -p${P[$s]} -D ${D[$s]} -N -h ${H[$s]} -e "${S}" | while read q v i p; do A=("quote $q" "verify $v" "insure $i" "pay $p");t=$(date +%s);for r in "${A[@]}";do echo yunying_shuju.part_$part.$r $t ;done ;done
            #mysql -u${U} -p${P[$s]} -D ${D[$s]} -N -h ${H[$s]} -e "${S}" | while read q v i p; do echo $q,$v,$i,$p;done
            mysql -u${U} -p${P[$s]} -D ${D[$s]} -N -h ${H[$s]} -e "${S}" | while read q v i p; do InsertSql $Table "$(date "+%Y-%m-%d %H:%M:%S")" $v $q $i $p;done
        done
        print_to_log "$FUNCNAME(): End."
}

Int()
{
        if [[ -f $RUN_TAG ]];then
            print_to_log "$FUNCNAME(): Last process still running, exit!!!"
            echo "$FUNCNAME(): Last process still running, exit!!!"
            exit
        fi
        [[ ! -d $LOG ]] && mkdir $LOG
        [[ ! -d $RUN ]] && mkdir $RUN
        touch $RUN_TAG
}

Finish()
{
        print_to_log "$FUNCNAME(): Begin."
        LOG_SIZE=$(du -k $LOG0 | awk '{print $1}')
        if (( $LOG_SIZE > $MAX_LOG_SIZE ))
        then
            print_to_log "rotate log: Begin."
            [[ -f $LOG3 ]] && rm -fv $LOG3 >> $LOG0
            [[ -f $LOG2 ]] && mv -fv $LOG2 $LOG3 >> $LOG0
            [[ -f $LOG1 ]] && mv -fv $LOG1 $LOG2 >> $LOG0
            mv -fv $LOG0 $LOG1 >> $LOG0
            print_to_log "rotate log: End."
        fi
        rm -f $RUN_TAG
        print_to_log "$FUNCNAME(): End."
}


# main
print_to_log "---------$(datef)-----------"
print_to_log "$0: Begin."
Int
InsertJvmHeapUsage
InsertConnect
#InsertQuoteVerifyInsurePay
Finish
print_to_log "$0: End."
print_to_log ""
