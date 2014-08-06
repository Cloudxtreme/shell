#!/bin/bash

export PATH=/usr/local/mysql/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export LANG=C

# define directory
ROOT=/data/bw_mon/bw_mysqlbk
LOG=$ROOT/log
RUN=$ROOT/run
LOCAL_DATA=$ROOT/local_data
CONF=$ROOT/conf
_ErrLog=$Log/.${Now}.log

# tag file
RUN_TAG=$RUN/running.tag

# log file
LOG0=$LOG/bw_mysqlbk.log ; LOG1=$LOG0.1 ; LOG2=$LOG0.2 ; LOG3=$LOG0.3
bksize=$ROOT/log/bw_sizebk.log
nowtime=`date +%Y%m%d_%H%M`
delnowtime=`date -d "7 days ago"  +%Y%m%d_%H%M`
xtrabackcmdlog=$LOG/xtrabackcmd_$nowtime.log
xtrabackcmddellog=$LOG/xtrabackcmd_$nowtime.log
[[ -f $xtrabackcmddellog  ]] || rm -f $xtrabackcmddellog
# define temp file
MAIL_TMP=$RUN/mail.tmp

# define something about mail
MAIL_TITLE=
Week=$(date +%w)
Bindir=$LOCAL_DATA/bin-log

# read configuration file 读取配置文件
if [[  -f $CONF/bw_mysqlbk.conf && -f $CONF/mail.conf ]]
then
	. $CONF/bw_mysqlbk.conf
	. $CONF/mail.conf 
else
        echo "configuration file not exist, exit!!!"
	exit 1
fi

# defile funtions 定义日志输出
datef() { date "+%Y/%m/%d %H:%M" ; }
print_to_log() { echo "[$(datef)] $1" >> $LOG0 ; }
print_to_mail() { echo "[$(datef)] $1" >> $MAIL_TMP ; }
print_file_to_mail() { cat $1 >> $MAIL_TMP ; }
append_mail_title() { MAIL_TITLE="$MAIL_TITLE:$1" ; }
print_size(){ echo "$innobackupway:$whatway:$BACKUP_SERIAL:$Week:$Bkdirsz:$Bkdirgz:$Dataspace:$Datedirsize" >> $bksize;}

#定义短信报警
sys_arm()
{
if [[ $telphonesms ==  "yes" ]] ;then

                /usr/local/bin/sendsmspost.pl 15200823107    app_backup     $IP_ADDR==$Now===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 13144445556    app_backup     $IP_ADDR==$Now===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 18998304287    app_backup     $IP_ADDR==$Now===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 13580588410     app_backup     $IP_ADDR==$Now===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 15017557647     app_backup     $IP_ADDR==$Now===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 13609712013     app_backup     $IP_ADDR==$Now===$content=backup--faild-【保网】!
else 
echo "Telphone sms is disabled!---$content"
fi 
}

###备份binlog文件
bakbinlog()
{
binif=$(mysql -u ${Usr} -p${Pwd}  -e "show variables like 'log_bin'" --batch  |grep  "log_bin" |awk '{print $2}')
Datedir=$(mysql -u ${Usr} -p${Pwd}  -e "show variables like 'datadir'" --batch |grep "datadir"   |awk '{print $2}')
binlogfile=`mysql -u ${Usr} -p${Pwd}  -e "show binary logs" --batch    |grep -v "Log_name" |awk '{print $1}'`
if [[ $binif == "ON"  ]];then
cd $Datedir
for i in $binlogfile
do

[[ -d $Bindir/$BACKUP_SERIAL   ]] || mkdir -p $Bindir/$BACKUP_SERIAL

#删除老的binlog日志
Delbindir=`find $Bindir -type d -name $Bindelday*`
if [[  -d $Delbindir  ]] ;then 
 rm  -rf $Delbindir
 print_to_log "Delete binlog foreverbak:$Delbindir"
fi 

desdir=$Bindir/$BACKUP_SERIAL
#cp $i $desdir

done
   if [ $? -ne 0 ]
     then
        content="Mysql-binlog"
        sys_arm
     print_to_log "Mysql-binlog backup fail!!"
     else
     print_to_log "Mysql-binlog  backup sucess !!"
     fi




else
echo "binlog is OFF ,so exit backup binlog!"
print_to_log "binlog is OFF ,so exit backup binlog!"

fi

}

spacejudge_all()
{
###针对整个库备份的判断
Datedir=$(mysql -u ${Usr} -p${Pwd}  -e "show variables like 'datadir'" --batch |grep "datadir"   |awk '{print $2}')
Datedirsize=$(du -sm $Datedir|awk '{print $1}')
Dataspace1=$(df -k $LOCAL_DATA|grep -v "Avail" |awk '{print $4}')
Dataspace=$( expr $Dataspace1 / 1024 )
define_initsize=$(cat $bksize| grep ":full:" |wc -l)
##
if [[ $define_initsize -eq 1  ]];then
inno_fullend_size=$(cat $bksize  |grep ":full:" |awk 'END{print $NF}' |awk -F: '{print $5}')
inno_allgz_size=$(cat $bksize  |grep ":full:" |awk 'END{print $NF}' |awk -F: '{print $6}')
Needspace=$( expr $Datedirsize + $inno_allgz_size  + $inno_allow_size)
#echo "存在1次全备依据...
#全备数据目录:"$Datedirsize"M 
#最后一次全备备份目录:"$inno_fullend_size"M 最后一次全备压缩文件:"$inno_allgz_size"M
#默认配置允许约束值:"$inno_allow_size"M 备份所需空间:"$Needspace"M [$Datedirsize + $inno_allgz_size  + $inno_allow_size] 剩余空间:"$Dataspace"M"
print_to_log  "存在1次全备依据...,全备数据目录:"$Datedirsize"M,最后一次全备备份目录:"$inno_fullend_size"M 最后一次全备压缩文件:"$inno_allgz_size"M,默认配置允许约束值:"$inno_allow_size"M 备份所需空间:"$Needspace"M [$Datedirsize + $inno_allgz_size  + $inno_allow_size] 剩余空间:"$Dataspace"M"
fi
if [[ $define_initsize -gt 1 ]];then
inno_fullend_size=$(cat $bksize  |grep ":full:" |awk 'END{print $NF}' |awk -F: '{print $5}')
inno_fullends_size=$(cat $bksize  |grep ":full:" |tail -n 2 |head -n 1|awk -F: '{print $5}')
inno_allgz_size=$(cat $bksize  |grep ":full:" |awk 'END{print $NF}' |awk -F: '{print $6}')
inno_fullendZ_size=$(cat $bksize  |grep ":full:" |awk 'END{print $NF}' |awk -F: '{print $6}')
inno_fullendsZ_size=$(cat $bksize  |grep ":full:"|tail -n 2 |head -n 1|awk -F: '{print $6}')
inno_var_size=$(expr $inno_fullend_size - $inno_fullends_size)
inno_varz_size=$(expr $inno_fullendZ_size - $inno_fullendsZ_size)
innovarsize=$(expr $inno_var_size + $inno_varz_size)
Needspace=$( expr $Datedirsize + $inno_allgz_size + $innovarsize + $inno_allow_size)
#echo "存在2次以上全备依据...
#全备数据目录:"$Datedirsize"M
#最后1次全备目录文件:"$inno_fullend_size"M 最后1次全备压缩文件:"$inno_allgz_size"M 
#前2次全备目录差异值:"$inno_var_size"M 前2次全备压缩差异值:"$inno_varz_size"M  前2次总的差异值:"$innovarsize"M 
#默认配置允许约束值:"$inno_allow_size"M 备份所需空间:"$Needspace"M [$Datedirsize+$inno_allgz_size+$innovarsize+$inno_allow_size] 剩余空间:"$Dataspace"M"
print_to_log  "存在2次以上全备依据...,全备数据目录:"$Datedirsize"M,最后1次全备目录文件:"$inno_fullend_size"M 最后1次全备压缩文件:"$inno_allgz_size"M ,前2次全备目录差异值:"$inno_var_size"M,前2次全备压缩差异值:"$inno_varz_size"M  前2次总的差异值:"$innovarsize"M ,默认配置允许约束值:"$inno_allow_size"M 备份所需空间:"$Needspace"M [$Datedirsize+$inno_allgz_size+$innovarsize+$inno_allow_size] 剩余空间:"$Dataspace"M"
fi 
if [[ $define_initsize -eq 0  ]];then
Needspace=$( expr $Datedirsize + $inno_allgz_size + $inno_allow_size)
#echo "
#不存在全备依据,开始取配置文件默认值...
#全备数据目录:"$Datedirsize"M
#备压缩文件:"$inno_allgz_size"M
#默认配置允许约束值:"$inno_allow_size"M
#备份所需空间:"$Needspace"M [$Datedirsize+$inno_allgz_size+$inno_allow_size] 剩余空间:"$Dataspace"M"
print_to_log  "不存在全备依据,开始取配置文件默认值...,全备数据目录:"$Datedirsize"M，全备压缩文件:"$inno_allgz_size"M,默认配置允许约束值:"$inno_allow_size"M,备份所需空间:"$Needspace"M [$Datedirsize+$inno_allgz_size+$inno_allow_size] 剩余空间:"$Dataspace"M"
fi

if [[ $Needspace -gt $Dataspace  ]];then
 
#echo "MYSQL数据库备份目录所剩空间约小于备份所需空间,退出备份程序!【备份所需空间为:"$Needspace"M，剩余空间:"$Dataspace"M】"
  print_to_log " MYSQL数据库备份目录所剩空间约小于备份所需空间,退出备份程序!【备份所需空间为:"$Needspace"M，剩余空间:"$Dataspace"M】"
# 短信报警
 content=" Mysql-remail-space-is-not-enough!"
        sys_arm
 exit

fi
}

spacejudge_diff()
{
###针对整个库增量备份空间的判断
Datedir=$(mysql -u ${Usr} -p${Pwd}  -e "show variables like 'datadir'" --batch |grep "datadir"   |awk '{print $2}')
Datedirsize=$(du -sm $Datedir|awk '{print $1}')
Dataspace1=$(df -k $LOCAL_DATA|grep -v "Avail" |awk '{print $4}')
Dataspace=$( expr $Dataspace1 / 1024 )
define_initsize=$(cat $bksize| grep ":diff:" |wc -l)
##
if [[ $define_initsize -eq 1  ]];then
inno_diffend_size=$(cat $bksize  |grep ":diff:" |awk 'END{print $NF}' |awk -F: '{print $5}')
inno_diffgz_size=$(cat $bksize  |grep ":diff:" |awk 'END{print $NF}' |awk -F: '{print $6}')
Needspace=$( expr $inno_diffend_size + $inno_diffgz_size  + $inno_allow_size)
#echo "存在1次增备依据...，增备数据目录:"$Datedirsize"M,最后一次增备备份目录:"$inno_diffend_size"M 最后一次增备压缩文件:"$inno_diffgz_size"M,默认配置允许约束值:"$inno_allow_size"M 备份所需空间:"$Needspace"M [$Datedirsize + $inno_diffgz_size  + $inno_allow_size] 剩余空间:"$Dataspace"M"
print_to_log  "存在1次增备依据...,增备数据目录:"$Datedirsize"M ,最后一次增备备份目录:"$inno_diffend_size"M 最后一次增备压缩文件:"$inno_diffgz_size"M,默认配置允许约束值:"$inno_allow_size"M 备份所需空间:"$Needspace"M [$inno_diffend_size + $inno_diffgz_size  + $inno_allow_size] 剩余空间:"$Dataspace"M"
fi
if [[ $define_initsize -gt 1 ]];then
inno_diffend_size=$(cat $bksize  |grep ":diff:" |awk 'END{print $NF}' |awk -F: '{print $5}')
inno_diffends_size=$(cat $bksize  |grep ":diff:" |tail -n 2 |head -n 1|awk -F: '{print $5}')
inno_allgz_size=$(cat $bksize  |grep ":diff:" |awk 'END{print $NF}' |awk -F: '{print $6}')
inno_diffendZ_size=$(cat $bksize  |grep ":diff:" |awk 'END{print $NF}' |awk -F: '{print $6}')
inno_diffendsZ_size=$(cat $bksize  |grep ":diff:"|tail -n 2 |head -n 1|awk -F: '{print $6}')
inno_var_size=$(expr $inno_diffend_size - $inno_diffends_size)
inno_varz_size=$(expr $inno_diffendZ_size - $inno_diffendsZ_size)
innovarsize=$(expr $inno_var_size + $inno_varz_size)
Needspace=$( expr $inno_diffend_size + $inno_allgz_size + $innovarsize + $inno_allow_size)
#echo "存在2次以上增备依据...
#增备数据目录:"$Datedirsize"M
#最后1次增备目录文件:"$inno_diffend_size"M 最后1次增备压缩文件:"$inno_allgz_size"M 
#前2次增备目录差异值:"$inno_var_size"M 前2次增备压缩差异值:"$inno_varz_size"M  前2次总的差异值:"$innovarsize"M 
#默认配置允许约束值:"$inno_allow_size"M 备份所需空间:"$Needspace"M [$Datedirsize+$inno_allgz_size+$innovarsize+$inno_allow_size] 剩余空间:"$Dataspace"M"
print_to_log  "存在2次以上增备依据...,增备数据目录:"$Datedirsize"M,最后1次增备目录文件:"$inno_diffend_size"M 最后1次增备压缩文件:"$inno_allgz_size"M ,前2次增备目录差异值:"$inno_var_size"M 前2次增备压缩差异值:"$inno_varz_size"M  前2次总的差异值:"$innovarsize"M ,默认配置允许约束值:"$inno_allow_size"M 备份所需空间:"$Needspace"M [$Datedirsize+$inno_allgz_size+$innovarsize+$inno_allow_size] 剩余空间:"$Dataspace"M"
fi
if [[ $define_initsize -eq 0  ]];then
Needspace=$( expr $inno_diffsz_siz + $inno_diffdir_size + $inno_allow_size)
#echo "不在增备依据,开始取配置文件默认值...
#增备数据目录:"$Datedirsize"M
#增备备份目录:"$inno_diffdir_size"M
#增备压缩文件:"$inno_diffsz_size"M
#默认配置允许约束值:"$inno_allow_size"M
#备份所需空间:"$Needspace"M [$inno_diffdir_size + $inno_diffsz_size + $inno_allow_size] 剩余空间:"$Dataspace"M"
print_to_log  "不存在增备依据,开始取配置文件默认值...，增备数据目录:"$Datedirsize"M,增备备份目录:"$inno_diffdir_size"M,增备压缩文件:"$inno_diffsz_size"M,默认配置允许约束值:"$inno_allow_size"M,备份所需空间:"$Needspace"M [$inno_diffdir_size + $inno_diffsz_size + $inno_allow_size] 剩余空间:"$Dataspace"M"
fi

if [[ $Needspace -gt $Dataspace  ]];then

#echo "MYSQL数据库备份目录所剩空间约小于备份所需空间,退出备份程序!【备份所需空间为:"$Needspace"M，剩余空间:"$Dataspace"M】"
 print_to_log " MYSQL数据库备份目录所剩空间约小于备份所需空间,退出备份程序!【备份所需空间为:$Needspace  M，剩余空间:$Dataspace  M】"
# 短信报警
 content=" Mysql-remail-space-is-not-enough!"
        sys_arm
 exit

fi


}


#前期判断主机名/IP网卡接口
pre_backup()
{	
	print_to_log "$FUNCNAME(): Begin."

	# get hostname
	HOST_NAME=$(hostname | awk -F'.' '{print $1}')
	
	# get ip address, only consider eth0, eth0:1 and eth1
	for iface in eth0 eth0:1 eth1
	do
		IP_ADDR=$(ifconfig $iface | awk -F: '/inet addr/{split($2,a," ") ; print a[1]}')
		[[ ! -z $IP_ADDR ]] && break
	done
	
	MAIL_PREFIX="BACKUP_${HOST_NAME}(${IP_ADDR})"
	
	# exit if can not get hostname or ip address
	if [[ -z $HOST_NAME || -z $IP_ADDR ]]
	then
		print_to_log  "$FUNCNAME(): Can not get hostname or IP address!"
		print_to_mail "$FUNCNAME(): Can not get hostname or IP address!"
		print_to_mail "$FUNCNAME(): HOST_NAME=$HOST_NAME"
		print_to_mail "$FUNCNAME(): IP_ADDR=$IP_ADDR"
		append_mail_title "IP/HOSTNAME_ERR"
		mail_file "$MAIL_PREFIX:$MAIL_TITLE" $MAIL_TP
		rm -f $MAIL_TMP
		exit
	fi
	
	# exit if last backup still running
	if [[ -f $RUN_TAG ]]
	then
                content="Mysql-backup-process-still-running-exit!"
                sys_arm
		print_to_log "$FUNCNAME(): Last backup process still running, exit!!!"
		ps auxwww | grep bw_backup.sh | grep -v grep > $RUN/ps.tmp
		print_to_mail "$FUNCNAME(): Last backup process still running, exit!!!"
		print_to_mail "$FUNCNAME(): ps output:"
		print_file_to_mail $RUN/ps.tmp
		append_mail_title "LAST_BAK_RUNING"
		mail_file "$MAIL_PREFIX:$MAIL_TITLE" $MAIL_TMP
		rm -f $MAIL_TMP $RUN/ps.tmp
		exit
	else
		touch $RUN_TAG
	fi
}

## app backup ##
app_backup()
{
        # backup daemon files
        print_to_log "$FUNCNAME(): Begin."

        for files in $APP_LIST $SELF_LIST
        do
                cp -LRpf --parents $files $LOCAL_DATA/$BACKUP_SERIAL
        done
}

##choose  backup mysql ways
mysqlbakcmd()
{
if [[ $mysqlchoice == "mydumper" ]];then
 print_to_log  "mysql backup command for (mydumper)"
 mydump_cmd="/usr/local/bin/mydumper"
 $mydump_cmd -u ${Usr} -p ${Pwd} -B $_this_db -o $LOCAL_DATA/$BACKUP_SERIAL/${_this_db}

elif [[ $mysqlchoice == "mysqldump" ]] ;then 
print_to_log  "mysql backup command for (mysqldump)"
 mysqldump_cmd="mysqldump --single-transaction"
(( first_run == 0 )) && mysqldump_cmd="$mysqldump_cmd --flush-logs --delete-master-logs"	
$mysqldump_cmd --log-error=$_ErrLog -u${Usr} -p${Pwd} -S${mysql_sock} $_this_db > $LOCAL_DATA/$BACKUP_SERIAL/${_this_db}_${Now}.sql
fi




if [[ $mysqlchoice == "innobackupex" && $innobackupway == "all"  ]] ;then
#对备份空间进行判断
#                 spacejudge
whatway=full
print_to_log  "mysql backup command for (innobackupex-full)"
spacejudge_all
innobackupex --user=root --password=${Pwd} --no-timestamp --defaults-file=$mycnf   --slave-info --safe-slave-backup  $LOCAL_DATA/$BACKUP_SERIAL/fullbackup_${Now} >> $xtrabackcmdlog  2>&1
# innobackupex --user=root --password=${Pwd} --no-timestamp --defaults-file=$mycnf     $LOCAL_DATA/$BACKUP_SERIAL/fullbackup_${Now}    >> $xtrabackcmdlog  2>&1 
     if [ $? -ne 0 ]
     then
        content="Mysql-innobackupex-fullbackup"
        sys_arm
     print_to_log "database ${_this_db} backup fail !!"
     else
     print_to_log "database ${_this_db} backup sucess !!"
     fi
#全备目录大小，单位为M.
Bkdirsz=$(du -sm $LOCAL_DATA/$BACKUP_SERIAL/fullbackup_${Now}|awk '{print $1}')

elif [[  $mysqlchoice == "innobackupex" &&  $innobackupway == "diffall"  ]];then


case $Week  in
1 )

delete_Mon
#对备份空间进行判断
#                 spacejudge
whatway=full
print_to_log  "mysql backup command for (innobackupex-full)"
spacejudge_all
 innobackupex --user=root --password=${Pwd} --no-timestamp --defaults-file=$mycnf --slave-info --safe-slave-backup   $LOCAL_DATA/$BACKUP_SERIAL/fullbackup_${Now} >> $xtrabackcmdlog   2>&1
# innobackupex --user=root --password=${Pwd} --no-timestamp --defaults-file=$mycnf    $LOCAL_DATA/$BACKUP_SERIAL/fullbackup_${Now}  >> $xtrabackcmdlog  2>&1
     if [ $? -ne 0 ]
     then
        content="Mysql"
        sys_arm
     print_to_log "database ${_this_db} backup fail !!"
     else
     print_to_log "database ${_this_db} backup sucess !!"
     fi
#全备目录大小，单位为M.
Bkdirsz=$(du -sm $LOCAL_DATA/$BACKUP_SERIAL/fullbackup_${Now}|awk '{print $1}')
;;

2 | 3 | 4 | 5 | 6 | 0 )
whatway=diff
dateYM=`echo  "$BACKUP_SERIAL" |awk -F'_' '{print $1}'`
dateHM=`echo  "$BACKUP_SERIAL" |awk -F'_' '{print $2}'`
YM=$(date -d "$dateYM" +%Y-%m-%d)
HM=$(date -d "$dateHM" +%H:%M)
mytime="$YM $HM"
datestr=`date -d "$mytime"`
tst=`date -d "$mytime" +%s`
while [[ "${datestr:0:3}" != "Mon" ]]
do
        let "tst=tst-86400"
        datestr=`date -d "@$tst"`
done

FULL_SERIAL=$(date -d "$datestr" +%Y%m%d)
fullbackupdirname=fullbackup_${FULL_SERIAL}
xtrabackupdiffdir=$LOCAL_DATA/$BACKUP_SERIAL/diff_${Now}
xtrabackupfulldir=$(find $LOCAL_DATA -type d  -name $fullbackupdirname*)
if [[ ! -d $xtrabackupfulldir  ]];then 
echo "xtrabackupex fullbackup directory-[$xtrabackupfulldir]  is not exist.exit!"
print_to_log "xtrabackupex fullbackup directory-[$xtrabackupfulldir]  is not exist.exit!"
content="xtrabackupex-fullbackup-directory-isnot-exist-exit"
sys_arm
exit
fi  

print_to_log  "mysql backup command for (innobackupex-diff)"
spacejudge_diff
 innobackupex --incremental $xtrabackupdiffdir --no-timestamp --slave-info --safe-slave-backup  --incremental-basedir=$xtrabackupfulldir --user=root --password=${Pwd} --defaults-file=$mycnf >> $xtrabackcmdlog  2>&1
# innobackupex --incremental $xtrabackupdiffdir --no-timestamp  --incremental-basedir=$xtrabackupfulldir --user=root --password=${Pwd} --defaults-file=$mycnf  >> $xtrabackcmdlog  2>&1
     if [ $? -ne 0 ]
     then
        content="Mysql-innobackupex-diffbackup"
        sys_arm
     print_to_log "database ${_this_db} backup fail (innobackupex-diff) !!"
     else
     print_to_log "database ${_this_db} backup sucess !!"
    print_to_log  "mysql backup command for (innobackupex-diff)"
    print_to_log  "innobackupex-diff Backup the fulldir: $xtrabackupfulldir"
     fi
#增备目录大小，单位为M.
Bkdirsz=$(du -sm  $xtrabackupdiffdir|awk '{print $1}')

;;
esac

break
fi 





}

## backup mysql ##
mysql_backup()
{
   print_to_log "$FUNCNAME(): Begin."

   for _this_db in $bk_db_list
do
	if ! mysql -u${Usr} -p${Pwd} -S${mysql_sock} --execute='show databases' --batch | grep "\<$_this_db\>" > /dev/null 2>&1
	then
		print_to_log "DATABASE \"$_this_db\" not exists!"
		return
	else
#由于空间不够取消binlog备份
#                 bakbinlog
                 mysqlbakcmd
		if [ $? -ne 0 ]
                then
	            content="Mysql"		
                    sys_arm 
                    print_to_log "database ${_this_db} backup fail !!"
                else
                    print_to_log "database ${_this_db} backup sucess !!"
		fi
	fi
done
}

## tar ##
tar_file()
{
        print_to_log "$FUNCNAME(): Begin."

        cd $LOCAL_DATA
        tar -zcf $BACKUP_SERIAL.tar.gz $BACKUP_SERIAL
case $Week  in
2 | 3 | 4 | 5 | 6 | 0 )
rm -rf $BACKUP_SERIAL
;;
esac
#完备/增备压缩目录大小，单位为M.
Bkdirgz=$(du -sm  $BACKUP_SERIAL.tar.gz|awk '{print $1}') 
}

## remote backup ###
remote_backup()
{
        print_to_log "$FUNCNAME(): Begin."

        if ! nmap -P0 -p$RSYNC_PORT $BACKUP_SERVER | grep "$RSYNC_PORT/tcp open" > /dev/null 2>&1
        then
                print_to_log "$FUNCNAME(): $BACKUP_SERVER port $RSYNC_PORTmay con't conneted, exit!!!"

                print_to_mail "$FUNCNAME(): backup server $BACKUP_SERVER con't conneted, exit!!!"
                append_mail_title "BAK_SVR_DOWN"

                mail_file "$MAIL_PREFIX:$MAIL_TITLE" $MAIL_TMP
                rm -f $MAIL_TMP
                return
        fi
        [[ ! -d $ROOT/$IP_ADDR/$(basename $ROOT) ]] && mkdir -p $ROOT/$IP_ADDR/$(basename $ROOT)
        #chown -R $RSYNC_USR:$RSYNC_USR $LOCAL_DATA/$IP_ADDR $LOCAL_DATA/${BACKUP_SERIAL}*

        if [[ $COMPRESS == enable ]]
        then
                print_to_log "$FUNCNAME(): compress enabled, rsync tar.gz file."
                #RSYNC_DATA=$LOCAL_DATA/$BACKUP_SERIAL.tar.gz
                RSYNC_DATA=$LOCAL_DATA
        else
                print_to_log "$FUNCNAME(): compress disabled, rsync dir."
                #RSYNC_DATA=$LOCAL_DATA/$BACKUP_SERIAL
                RSYNC_DATA=$LOCAL_DATA
        fi
        rsync -av --password-file=$PW_FILE $ROOT/$IP_ADDR ${RSYNC_USR}@${BACKUP_SERVER}::${RSYNC_MOD} > $RUN/rsync.tmp.1 2>&1
        #echo "rsync -av --password-file=$PW_FILE $ROOT/$IP_ADDR ${RSYNC_USR}@${BACKUP_SERVER}::${RSYNC_MOD} > $RUN/rsync.tmp.1 2>&1"
        local ret1=$?
        rsync -av --delete --password-file=$PW_FILE $RSYNC_DATA/ ${RSYNC_USR}@${BACKUP_SERVER}::${RSYNC_MOD}/${IP_ADDR}/$(basename $ROOT) > $RUN/rsync.tmp.2 2>&1
        local ret2=$?

        if [[ $ret1 != 0 || $ret2 != 0 ]]
        then
                content="Mysql-rsync-error!!"
                sys_arm
                print_to_log "$FUNCNAME(): rsync error!!!"
                print_to_log "$FUNCNAME(): rsync -av --password-file=$PW_FILE $LOCAL_DATA/$IP_ADDR ${RSYNC_USR}@${BACKUP_SERVER}::${RSYNC_MOD}"
                print_to_log "$FUNCNAME(): ret = $ret1"
                print_to_log "$FUNCNAME(): rsync -av --password-file=$PW_FILE $RSYNC_DATA ${RSYNC_USR}@${BACKUP_SERVER}::${RSYNC_MOD}/${IP_ADDR}"
                print_to_log "$FUNCNAME(): ret = $ret2"

                print_to_mail "$FUNCNAME(): rsync error!!!"
                print_to_mail "$FUNCNAME(): rsync -av --password-file=$PW_FILE $LOCAL_DATA/$IP_ADDR ${RSYNC_USR}@${BACKUP_SERVER}::${RSYNC_MOD}"
                print_to_mail "$FUNCNAME(): ret = $ret1 , rsync output:"
                print_file_to_mail $RUN/rsync.tmp.1
                print_to_mail "$FUNCNAME(): rsync -av --password-file=$PW_FILE $RSYNC_DATA ${RSYNC_USR}@${BACKUP_SERVER}::${RSYNC_MOD}/${IP_ADDR}"
                print_to_mail "$FUNCNAME(): ret = $ret2 , rsync output:"
                print_file_to_mail $RUN/rsync.tmp.2

                append_mail_title "RSYNC_ERR"
                mail_file "$MAIL_PREFIX:$MAIL_TITLE" $MAIL_TMP
                rm -f $MAIL_TMP
        else
                print_to_log "$FUNCNAME(): rsync successfully!!!"
        fi

        rm -f $RUN/rsync.tmp.*
}

## post backup ##
post_backup()
{
	print_to_log "$FUNCNAME(): Begin."

	# delete backup
	MAX_DAY_AGO=$(date -d "$MAX_SAVE_DAY days ago" +%Y%m%d)
	DEL_PREFIX="$LOCAL_DATA/$MAX_DAY_AGO"

	cat /dev/null > $RUN/last_delete
        if [[ $COMPRESS == enable ]]
        then
                LS_CMD='ls'
        else
                LS_CMD='ls -d'
        fi
	for lists in $($LS_CMD ${DEL_PREFIX}_* 2> /dev/null)
	do
		if [[ -e $lists ]]
		then
			echo $lists >> $RUN/last_delete
			rm -fr $lists
		fi
	done
}
###由于空间不够在备份周一前删除前一周周一的备份
delete_Mon()
{

        print_to_log "$FUNCNAME(): Begin."
        # delete backup
        MAX_DAY_AGO=$(date -d "$MAX_SAVE_DAY days ago" +%Y%m%d)
        DEL_PREFIX="$LOCAL_DATA/$MAX_DAY_AGO"
        
        cat /dev/null > $RUN/last_delete
        if [[ $COMPRESS == enable ]]
        then
                LS_CMD='ls -d'
        else    
                LS_CMD='ls -d'
        fi      
        for lists in $($LS_CMD ${DEL_PREFIX}_* 2> /dev/null)
        do
                if [[ -e $lists ]]
                then
                        echo $lists >> $RUN/last_delete
                        rm -fr $lists
                fi
        done

}


# create dir and log
[[ ! -d $LOCAL_DATA ]] && mkdir $LOCAL_DATA
[[ ! -d $LOG ]] && mkdir $LOG
[[ ! -d $RUN ]] && mkdir $RUN

BACKUP_SERIAL=$(date +%Y%m%d)_$(date +%H%M)
Bindelday=`date  -d "3 days ago" +%Y%m%d `

Now=$BACKUP_SERIAL
[[ ! -d $BACKUP_SERIAL ]] && mkdir $LOCAL_DATA/$BACKUP_SERIAL

# main
print_to_log "---------$(datef)-----------"
print_to_log "$0: Begin."
pre_backup
app_backup
mysql_backup

[[ $COMPRESS == enable ]] && tar_file
post_backup
[[ $REMOTE_BACKUP == enable ]] && remote_backup

print_to_log "$0: End."


# rotate log
LOG_SIZE=$(du -k $LOG0 | awk '{print $1}')

if (( $LOG_SIZE > $MAX_LOG_SIZE ))
then
	print_to_log "rotate log: Begin."
	[[ -f $LOG3 ]] && rm -fv $LOG3 >> $LOG0
	[[ -f $LOG2 ]] && mv -fv $LOG2 $LOG3 >> $LOG0
	[[ -f $LOG1 ]] && mv -fv $LOG1 $LOG2 >> $LOG0

	mv -fv $LOG0 $LOG1 >> $LOG0
fi

print_to_log ""
print_size 
rm -f $RUN_TAG
