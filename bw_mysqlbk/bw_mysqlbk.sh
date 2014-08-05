#!/bin/bash

export PATH=/usr/local/mysql/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export LANG=C

# define directory
ROOT=/data/bw_mon/bw_mysqlbk
LOG=$ROOT/log
RUN=$ROOT/run
LOCAL_DATA=$ROOT/local_data
CONF=$ROOT/conf

# tag file
RUN_TAG=$RUN/running.tag

# log file
LOG0=$LOG/bw_mysqlbk.log ; LOG1=$LOG0.1 ; LOG2=$LOG0.2 ; LOG3=$LOG0.3

# define temp file
MAIL_TMP=$RUN/mail.tmp

# define something about mail
MAIL_TITLE=


# read configuration file
if [[  -f $CONF/bw_mysqlbk.conf && -f $CONF/mail.conf ]]
then
	. $CONF/bw_mysqlbk.conf
	. $CONF/mail.conf 
else
        echo "configuration file not exist, exit!!!"
	exit 1
fi

# defile funtions
datef() { date "+%Y/%m/%d %H:%M" ; }
print_to_log() { echo "[$(datef)] $1" >> $LOG0 ; }
print_to_mail() { echo "[$(datef)] $1" >> $MAIL_TMP ; }
print_file_to_mail() { cat $1 >> $MAIL_TMP ; }
append_mail_title() { MAIL_TITLE="$MAIL_TITLE:$1" ; }

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
		mail_file "$MAIL_PREFIX:$MAIL_TITLE" $MAIL_TMP
		rm -f $MAIL_TMP
		exit
	fi
	
	# exit if last backup still running
	if [[ -f $RUN_TAG ]]
	then
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
		mydump_cmd="/usr/local/bin/mydumper"
		$mydump_cmd -u ${Usr} -p ${Pwd} -B $_this_db -o $LOCAL_DATA/$BACKUP_SERIAL/${_this_db} -v 3  >> $LOG/logfile 2>&1
		if [ $? -ne 0 ]
                then 
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
        rm -rf $BACKUP_SERIAL
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

                /usr/local/bin/sendsmspost.pl 15200823107    app_backup     $IP_ADDR==$NOW===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 13144445556    app_backup     $IP_ADDR==$NOW===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 18998304287    app_backup     $IP_ADDR==$NOW===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 13580588410     app_backup     $IP_ADDR==$NOW===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 15017557647     app_backup     $IP_ADDR==$NOW===$content=backup--faild-【保网】!
                /usr/local/bin/sendsmspost.pl 13609712013     app_backup     $IP_ADDR==$NOW===$content=backup--faild-【保网】!

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


# create dir and log
[[ ! -d $LOCAL_DATA ]] && mkdir $LOCAL_DATA
[[ ! -d $LOG ]] && mkdir $LOG
[[ ! -d $RUN ]] && mkdir $RUN

BACKUP_SERIAL=$(date +%Y%m%d)_$(date +%H%M)
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

rm -f $RUN_TAG
