#!/bin/bash

PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

datef() { date "+%Y/%m/%d %H:%M" ; }


pre_mon()
{
	echo "[$(datef)] pre_mon(): Begin." >> $LOG0

	LOG1=$LOG0.1
	LOG2=$LOG0.2
	LOG3=$LOG0.3

	NEED_MAIL=no
	MAIL_TITLE=""
	cat /dev/null > $MAIL_TMP
	touch $HIS_LOG

	# get hostname
	HOST_NAME=$(hostname | awk -F'.' '{print $1}')
	SCRIPT_NAME=$(basename `echo $0`)
        ((WAIT_TIME=${#SCRIPT_NAME}*2))
        sleep ${WAIT_TIME}
	# get ip address
	for iface in `ifconfig |grep eth |awk '{print $1}'`
	do
		ETH_IF=$(ifconfig $iface | awk -F: '/inet addr/{split($2,a," ") ; print a[1]}')
		[[ ! -z $ETH_IF ]] && break
	done
	# exit if can not get hostname or ip address
	if [[ -z $HOST_NAME || -z $ETH_IF ]]
	then
		echo "[$(datef)] pre_mon(): Can not get hostname or IP address!" >> $LOG0
		exit
	fi
}

ntp_adjust()
{
	CLOCK=/etc/sysconfig/clock
	CLOCK_BASIC=$RUN/ntp_adjust/clock.basic
	LOCALTIME=/etc/localtime
	ZONE=/usr/share/zoneinfo/Asia/Shanghai

	echo "[$(datef)] ntp_adjust(): Begin." >> $LOG0

	[[ ! -d $RUN/ntp_adjust ]] && mkdir $RUN/ntp_adjust

	NOW_HOUR=$(date +%H)
	if [[ $NOW_HOUR == "00" ]]
	then
		if [[ ! -f $RUN/ntp_tag ]]
		then
			touch $RUN/ntp_tag

			#ntpdate update
			ntpdate $NTP_SVR_0 > $RUN/ntp.0.tmp 2>&1
			ret=$?
			if (( ret != 0 ))
			then
				sleep 2
				ntpdate $NTP_SVR_1 > $RUN/ntp.1.tmp 2>&1
				ret=$?
				if (( ret != 0 ))
				then
					NEED_MAIL=yes
					MAIL_TITLE="NTPERR:"$MAIL_TITLE
					echo "[$(datef)] NTP_ERR" >> $HIS_LOG
					
					echo -e "==========\nntpdate report:\n==========" >> $MAIL_TMP
					cat $RUN/ntp.0.tmp >> $MAIL_TMP
					echo "---" >> $MAIL_TMP
					cat $RUN/ntp.1.tmp >> $MAIL_TMP
					echo "" >> $MAIL_TMP
					
					rm -f $RUN/ntp_tag
				else
					hwclock -w > /dev/null 2>&1
				fi
			else
				hwclock -w > /dev/null 2>&1
			fi

			rm -f $RUN/ntp.*.tmp
		fi
	else
		[[ -f $RUN/ntp_tag ]] && rm -f $RUN/ntp_tag
	fi
}

reboot_chk()
{
	UP_MIN=10

	echo "[$(datef)] reboot_chk(): Begin." >> $LOG0

	if uptime | grep min | grep -v day > /dev/null 2>&1
	then
		UT_TIME=$(uptime | awk '{print $3}')

		if (( UT_TIME <= UP_MIN ))
		then
			NEED_MAIL=yes
			MAIL_TITLE="RBOT_${UP_TIME}:"$MAIL_TITLE
			echo "[$(datef)] REBOOT $UT_TIME minute ago" >> $HIS_LOG

			echo -e "==========\nuptime report:\n==========" >> $MAIL_TMP
			uptime >> $MAIL_TMP
			echo "" >> $MAIL_TMP
		fi
	fi
}

hardware_chk()
{
	echo "[$(datef)] hardware_chk(): Begin." >> $LOG0

	NOW_HOUR=$(date +%H)

	if [[ $NOW_HOUR == "00" ]]
	then
		if [[ ! -f $RUN/hardware_chk_tag ]]
		then
			touch $RUN/hardware_chk_tag

			[[ ! -d $RUN/hardware_chk ]] && mkdir $RUN/hardware_chk
			HARDWARE_NOW=$RUN/hardware_chk/hardware.now
			HARDWARE_ORI=$RUN/hardware_chk/hardware.ori

			#cpu check
			CPU_NAME=$(grep "^model name" /proc/cpuinfo | awk -F: '{print $2}' | head -1 | sed 's/^ \{1,\}//')
			CPU_NUM="`grep "^processor" /proc/cpuinfo | wc -l | awk '{print $1}'`"
			echo "CPU=[$CPU_NAME:$CPU_NUM]" > $HARDWARE_NOW

			#men check
			MEM_SIZE=$(grep "MemTotal:" /proc/meminfo | awk '{
			$2=$2/1024/64
			split($2,NUM,".")
			if($2-NUM[1]>=0.5) { NUM[1]=NUM[1]+1 }
			printf "%dM\n",NUM[1]*64
			}')
			echo "MEM=[$MEM_SIZE]" >> $HARDWARE_NOW

			#scsi card check
			SCSI=$(lspci | grep "SCSI storage controller" | awk -F: 'BEGIN{ORS=":"}{sub(/^ /,"",$3) ; print $3}' | sed 's/:$/\n/')
			echo "SCSI=[$SCSI]" >> $HARDWARE_NOW

			#hdd check
			HDD=$(fdisk -l| grep Disk | awk 'BEGIN{ORS=":"}{sub(/^ /,"",$3) ; sub(/,$/,"",$4) ; print $2$3$4}' | sed  's/:$/\n/')
			echo "HDD=[$HDD]" >> $HARDWARE_NOW

			#nic check
			NIC=$(lspci | grep "Ethernet controller" | awk -F: 'BEGIN{ORS=":"}{sub(/^ /,"",$3) ; print $3}' | sed 's/:$/\n/')
			echo "NIC=[$NIC]" >> $HARDWARE_NOW

			if [[ ! -f $HARDWARE_ORI ]]
			then
				cp $HARDWARE_NOW $HARDWARE_ORI
			else
				diff $HARDWARE_NOW $HARDWARE_ORI > /dev/null 2>&1
				ret=$?
				if (( ret != 0 ))
				then
					#hardware changed
					NEED_MAIL=yes
					MAIL_TITLE="HWCHG:"$MAIL_TITLE
					echo "[$(datef)] HARDWARE_CHK_CHANGED" >> $HIS_LOG

					awk '
					{if(NR==FNR){now[FNR]=$0}else{ori[FNR]=$0};max=FNR}
					END{printf "\n==========\n"
					for(i=1;i<=max;i++){printf "NEW hardware: %s\nOLD hardware: %s\n-\n",now[i],ori[i]}
					printf "==========\n\n"}' $HARDWARE_NOW $HARDWARE_ORI >> $MAIL_TMP

					mv $HARDWARE_ORI $HARDWARE_ORI.$(date +%Y%m%d%H%M)
					cp $HARDWARE_NOW $HARDWARE_ORI
				fi
			fi

			rm -f $HARDWARE_NOW
		fi
	else
		[[ -f $RUN/hardware_chk_tag ]] && rm -f $RUN/hardware_chk_tag
	fi
}

cpu_chk()
{
	echo "[$(datef)] cpu_chk(): Begin." >> $LOG0

	MPSTAT=$(mpstat 1 5)
	CPU_USED=$(echo "$MPSTAT" | awk '{if ( $0 ~ /Average/ ) {printf "%d\n",($3+$5)*100}}')
	CPU_WARN_TMP=$(echo ${CPU_WARN}*100 | bc)

	if (( CPU_USED >= CPU_WARN_TMP ))
	then
		NEED_MAIL=yes
		CPU_USED_REAL=$(echo $CPU_USED | awk '{printf "%.2f\n",$1/100}')
		MAIL_TITLE="CPU${CPU_USED_REAL}%:"$MAIL_TITLE
		echo "[$(datef)] CPU_CHK_${CPU_USED_REAL}%" >> $HIS_LOG

		echo -e "==========\nmpstat report:\n==========" >> $MAIL_TMP
		echo "$MPSTAT" >> $MAIL_TMP
		echo "" >> $MAIL_TMP

		echo -e "==========\ntop report:\n==========" >> $MAIL_TMP
		top -b -n 1 | head -50 >> $MAIL_TMP

		echo -e "==========\nps report:\n==========" >> $MAIL_TMP
		ps auxwwwf | head -50 >> $MAIL_TMP
		echo "" >> $MAIL_TMP
	fi
}

loadavg_chk()
{
	echo "[$(datef)] loadavg_chk(): Begin." >> $LOG0

	LOADAVG=$(awk '{printf "%d\n",$2*100}' /proc/loadavg)
	LOAD_WARN_TMP=$(echo ${LOAD_WARN}*100 | bc)

	if (( LOADAVG >= LOAD_WARN_TMP ))
	then
		NEED_MAIL=yes
		LOADAVG_REAL=$(echo $LOADAVG | awk '{printf "%.2f\n",$1/100}')
		MAIL_TITLE="LDAVG${LOADAVG_REAL}:"$MAIL_TITLE
		echo "[$(datef)] LOADAVG_CHK_${LOADAVG_REAL}" >> $HIS_LOG

		echo -e "==========\ntop report:\n==========" >> $MAIL_TMP
		top -b -n 1 | head -50 >> $MAIL_TMP

		echo -e "==========\nps report:\n==========" >> $MAIL_TMP
		ps auxwwwf | head -50 >> $MAIL_TMP
		echo "" >> $MAIL_TMP
	fi
}

swap_chk()
{
	echo "[$(datef)] swap_chk(): Begin." >> $LOG0

	SWAP_TOTAL=$(awk '/SwapTotal/{print $2}' /proc/meminfo)
	SWAP_FREE=$(awk '/SwapFree/{print $2}' /proc/meminfo)
	SWAP_USED=$(echo "$SWAP_TOTAL $SWAP_FREE" | awk '{printf "%d\n",($1-$2)/$1*100}')
	SWAP_WARN_TMP=$(echo ${SWAP_WARN} | bc)
	
	TOTAL_SWAP_WARN=2000000 #by K

       if [[ SWAP_TOTAL == 0 ]];then
                NEED_MAIL=yes
                MAIL_TITLE="SWP:${SWAP_TOTAL};"$MAIL_TITLE
                echo "[$(datef)] SWAP_CHK:${SWAP_TOTAL}" >> $HIS_LOG

                echo -e "==========\nfree report:\n==========" >> $MAIL_TMP
                free >> $MAIL_TMP
                echo "" >> $MAIL_TMP
       else
                 if [[ "$SWAP_TOTAL" -lt "$TOTAL_SWAP_WARN" ]];then
                        NEED_MAIL=yes
                        MAIL_TITLE="SWP:${SWAP_TOTAL};"$MAIL_TITLE
                        echo "[$(datef)] SWAP_CHK:${SWAP_TOTAL}" >> $HIS_LOG

                        echo -e "==========\nfree report:\n==========" >> $MAIL_TMP
                        free >> $MAIL_TMP
                        echo "" >> $MAIL_TMP
                fi

                if (( SWAP_USED >= SWAP_WARN_TMP ))
                then
                        if [[ ! -f $RUN/swap_tag ]]
                        then
                                touch $RUN/swap_tag
                                NEED_MAIL=yes
                                MAIL_TITLE="SWP${SWAP_USED}%:"$MAIL_TITLE
                                echo "[$(datef)] SWAP_CHK_${SWAP_USED}%" >> $HIS_LOG

                                echo -e "==========\nfree report:\n==========" >> $MAIL_TMP
                                free >> $MAIL_TMP
                                echo "" >> $MAIL_TMP

                                echo -e "==========\nvmstat report:\n==========" >> $MAIL_TMP
                                vmstat 1 5 >> $MAIL_TMP
                                echo "" >> $MAIL_TMP

                                echo -e "==========\niostat report:\n==========" >> $MAIL_TMP
                                iostat -dx 2 5 >> $MAIL_TMP
                                echo "" >> $MAIL_TMP
                        else
                                LAST_SWAP_TIME=$(ls -l --time-style=+%s $RUN/swap_tag | awk '{print $6}')
                                NOW_SWAP_TIME=$(date +%s)

                                (( NOW_SWAP_TIME - LAST_SWAP_TIME > SWAP_EXPIRE_TIME )) && rm -f $RUN/swap_tag
                        fi
                else
                        [[ -f $RUN/swap_tag ]] && rm -f $RUN/swap_tag
                fi
        fi

}

disk_chk()
{
	echo "[$(datef)] disk_chk(): Begin." >> $LOG0

	DISK_RPT=no
	df -m -l --no-sync -P > $RUN/df.tmp

	#check disk usage by used percentage
	while read line
	do
		if ! echo $line | grep "^/" > /dev/null 2>&1
		then
			continue
		fi

		FILESYSTEM=$(echo $line | awk '{print $1}')
		MOUNTPOINT=$(echo $line | awk '{print $6}')
		USED=$(echo $line | awk '{gsub("%","",$5);print $5}')

		if (( USED >= DISK_WARN ))
		then
			DISK_RPT=yes
			NEED_MAIL=yes
			MAIL_TITLE="DSK${MOUNTPOINT}${USED}%:"$MAIL_TITLE
			echo "[$(datef)] DISK_CHK_${MOUNTPOINT}_${USED}%" >> $HIS_LOG
		fi
	done < $RUN/df.tmp

        df -i > $RUN/dfi.tmp

        #check disk usage by used percentage
        while read line
        do
                if ! echo $line | grep "^/" > /dev/null 2>&1
                then
                        continue
                fi

                FILESYSTEM=$(echo $line | awk '{print $1}')
                MOUNTPOINT=$(echo $line | awk '{print $6}')
                USED=$(echo $line | awk '{gsub("%","",$5);print $5}')

                if (( USED >= DISK_WARN ))
                then
                        DISK_RPT=yes
                        NEED_MAIL=yes
                        MAIL_TITLE="DSK_INODE${MOUNTPOINT}${USED}%:"$MAIL_TITLE
                        echo "[$(datef)] DSK_INODE_CHK_${MOUNTPOINT}_${USED}%" >> $HIS_LOG
                fi
        done < $RUN/dfi.tmp

	if [[ $DISK_RPT == "yes" ]]
	then
		echo -e "==========\ndf report:\n==========" >> $MAIL_TMP
		cat $RUN/df.tmp >> $MAIL_TMP
		echo "" >> $MAIL_TMP
	fi

	#each month's report
}

secure_chk()
{
	echo "[$(datef)] secure_chk(): Begin." >> $LOG0

	#run at 00:00 and 12:00 every day
	NOW_HOUR=$(date +%H)
	if [[ $NOW_HOUR == "00" || $NOW_HOUR == "12" ]]
	then
		[[ ! -f $RUN/secure_chk.tag ]] && touch $RUN/secure_chk.tag
		[[ -f $RUN/secure_chk.tag ]] && return
	else
		[[ -f $RUN/secure_chk.tag ]] && rm -f $RUN/secure_chk.tag
		return
	fi

	[[ ! -d $RUN/secure_chk ]] && mkdir $RUN/secure_chk

	#check files like passwd, shadow, group, etc.
	for files in $PROTECT_FILE
	do
		[[ ! -f $files ]] && echo "[$(datef)] secure_chk(): $files not exists!" >> $LOG0 && continue

		FILES_NAME=$(basename $files)
		[[ ! -f $RUN/secure_chk/$FILES_NAME.ori ]] && cp -fp $files $RUN/secure_chk/$FILES_NAME.ori

		diff $files $RUN/secure_chk/$FILES_NAME.ori > $RUN/secure_chk/$FILES_NAME.diff 2>&1
		if [[ -s $RUN/secure_chk/$FILES_NAME.diff ]]
		then
			NEED_MAIL=yes
			MAIL_TITLE="SEC${files}:"$MAIL_TITLE

			echo "[$(datef)] SECCHK_${files}_CHANGED" >> $HIS_LOG
			echo -e "==========\n$files diff report:\n==========" >> $MAIL_TMP
			cat $RUN/secure_chk/$FILES_NAME.diff >> $MAIL_TMP
			echo "" >> $MAIL_TMP

			mv $RUN/secure_chk/$FILES_NAME.ori $RUN/secure_chk/$FILES_NAME.ori.$(date +%Y%m%d%H%M)
			cp -fp $files $RUN/secure_chk/$FILES_NAME.ori
		fi

		[[ -f $RUN/secure_chk/$FILES_NAME.diff ]] && rm -f $RUN/secure_chk/$FILES_NAME.diff
	done

	#check suid and sgid files
	if [[ ! -f $RUN/secure_chk/sugid_file.list ]]
	then
		#generate md5
		find / -type f \( -perm -2000 -o -perm -4000 \) > $RUN/secure_chk/sugid_file.list
		while read line
		do
			md5sum $line >> $RUN/secure_chk/sugid_file.list.tmp
		done < $RUN/secure_chk/sugid_file.list

		mv -f $RUN/secure_chk/sugid_file.list.tmp $RUN/secure_chk/sugid_file.list
	fi

	#compare current suid and sgid files to old list
	MD5_CHGED=no

	find / -type f \( -perm -2000 -o -perm -4000 \) > $RUN/secure_chk/sugid_file.list.new
	while read line
	do
		if grep "$line\>" $RUN/secure_chk/sugid_file.list > /dev/null 2>&1
		then
			MD5_OLD=$(grep "$line\>" $RUN/secure_chk/sugid_file.list | awk '{print $1}')
			MD5_NEW=$(md5sum $line | awk '{print $1}')

			if [[ $MD5_NEW != $MD5_OLD ]]
			then
				MD5_CHGED=yes
				echo "[$(datef)] MD5CHK_${line}_CHANGED" >> $HIS_LOG
				echo -e "$line\t$MD5_OLD\t==>\t$MD5_NEW" >> $RUN/secure_chk/md5_changed.tmp
			fi
		else
			echo "[$(datef)] secure_chk(): sid file increase: $line" >> $LOG0
			md5sum $line >> $RUN/secure_chk/sugid_file.list
		fi
	done < $RUN/secure_chk/sugid_file.list.new

	if [[ $MD5_CHGED == yes ]]
	then
		NEED_MAIL=yes
		MAIL_TITLE="MD5${files}:"$MAIL_TITLE
		echo -e "==========\nmd5sum report:\n==========" >> $MAIL_TMP
		cat $RUN/secure_chk/md5_changed.tmp >> $MAIL_TMP
		echo "" >> $MAIL_TMP
	fi

	[[ -f $RUN/secure_chk/sugid_file.list.new ]] && rm -f $RUN/secure_chk/sugid_file.list.new
	[[ -f $RUN/secure_chk/md5_changed.tmp ]] && rm -f $RUN/secure_chk/md5_changed.tmp
}

log_chk(){
	
	echo "[$(datef)] log_chk(): Begin." >> $LOG0	
	#key words configure file
	WARNNIG_KEYWORDS=$CONF/warning_keyword.conf
	SECURE_KEYWORDS=$CONF/secure_keyword.conf

	#log file 
	MSGLOG_FILE=/var/log/messages
	DMSGLOG_FILE=$RUN/dmesg.tmp
	SECURE_FILE=/var/log/secure

	URL=http://netmis.gamebto.com/bwinit
	FILENAME=logtail
	WGET_OPTION="-o /dev/null -t 3 -c -T 8 -w 5 --no-proxy"

	#logtail command and egrep command 
	LOGTAIL=/usr/local/bin/logtail
	GREP=egrep
	
	NOW_HOUR=$(date +%H%M)
	
	if [ "$NOW_HOUR" == "0030" ];then      
 
	   #检查机器是否存在logtail工具。没有就安装

	   DESTDIR=/usr/local/bin
           cd $RUN
           ls /usr/local/bin/logtail > /dev/null 2>&1
           ret=$?
           if [ "$ret" != "0" ];then
                wget $WGET_OPTION "$URL/$FILENAME"
                WRET1=$?
                if [ "$WRET1" != "0" ];then
                        sleep 3
                        wget $WGET_OPTION "$URL/$FILENAME"
                        WRET2=$?
                        if [ "$WRET2" != "0" ];then
                                NEEDMAIL=yes
                                MAIL_TITLE="INSTALL_LOGTAIL_ERROR:"$MAILTITLE
                                echo "[$(datef)] INSTALL_LOGTAIL_ERROR" >> $HIS_LOG
                                echo -e "==========\n Install logtail report \n==========\n" >> $MAIL_TMP
                                echo "[$(datef)] can not wget $URL/$FILENAME" | tee -a $MAIL_TMP >> $LOG0
                        else
                                #install logtail
                                chmod +x $FILENAME
                                cp $FILENAME $DESTDIR
                        fi
                else
                        #install logtail
                        chmod +x $FILENAME
                        cp $FILENAME $DESTDIR
                fi
           fi


	   #开始检查日志

           LOGCHKTAG=0
           SURCHKTAG=0

           dmesg > $DMSGLOG_FILE
           dmesg -c

           $LOGTAIL $MSGLOG_FILE > $RUN/check.$$
           $LOGTAIL $DMSGLOG_FILE >> $RUN/check.$$
           $LOGTAIL $SECURE_FILE >> $RUN/check.$$
        
           if [ -f $WARNNIG_KEYWORDS ];then
                if $GREP -i -f $WARNNIG_KEYWORDS $RUN/check.$$ >> $RUN/chkoutput.$$;then
                        echo "" >> $RUN/chkreport.$$
                        echo "##### DMESG and MESSAGE Log Performance Analysis Report #####" >> $RUN/chkreport.$$
                        echo "==--==--==--==--==--==--==--==--==--==--==--==--==--==--==" >> $RUN/chkreport.$$
                        cat $RUN/chkoutput.$$ >> $RUN/chkreport.$$
                        echo "" >> $RUN/chkreport.$$
                        LOGCHKTAG=1
                fi
           fi
           if [ -f $SECURE_KEYWORDS ];then
                if $GREP -i -f $SECURE_KEYWORDS $RUN/check.$$ > $RUN/chkoutput.$$;then
                        echo "" >> $RUN/chkreport.$$
                        echo "##### Secure Log Analysis Report #####" >> $RUN/chkreport.$$
                        echo "===---===---===---===---===---===---===---===" >> $RUN/chkreport.$$
                        cat $RUN/chkoutput.$$ >> $RUN/chkreport.$$
                        echo "" >> $RUN/chkreport.$$
                        SURCHKTAG=1
                fi
           fi

           if [ "$LOGCHKTAG" -eq "1" ];then
                NEED_MAIL=yes
                MAIL_TITLE="LOG CHECK:"$MAIL_TITLE
                echo "[$(datef)] LOG CHECK" >> $HIS_LOG
                echo "" >> $MAIL_TMP
                echo -e "==========\n Message and Dmesg log report \n========== \n" >> $MAIL_TMP
                cat $RUN/chkreport.$$ >> $MAIL_TMP
                
           elif [ "$SURCHKTAG" -eq "1" ];then
                NEED_MAIL=yes
                MAIL_TITLE="SECURE CHECK:"$MAIL_TITLE
                echo "[$(datef)] CHECK Secure" >> $HIS_LOG
                echo "" >> $MAIL_TMP
                echo -e "==========\n Secure log report \n========== \n" >> $MAIL_TMP
                cat $RUN/chkreport.$$ >> $MAIL_TMP
           fi

           echo "" > $DMSGLOG_FILE
	   rm -f $RUN/*.offset
	   #Clean Up
           rm -f $RUN/check.$$ $RUN/chkoutput.$$ $RUN/chkreport.$$ 
	fi
	
}

post_mon()
{
	echo "[$(datef)] post_mon(): Begin." >> $LOG0

	MAIL_TITLE="SYSMON_${HOST_NAME}:"$MAIL_TITLE
	if [[ $NEED_MAIL == "yes" ]]
	then
		echo -e "[$(datef)] ${HOST_NAME}($ETH_IF)\n" >> $MAIL_TMP.tmp
		cat $MAIL_TMP >> $MAIL_TMP.tmp

		mail_file "$MAIL_TITLE" $MAIL_TMP.tmp
		rm -f $MAIL_TMP.tmp
	fi

	rm -f $MAIL_TMP
}

####################

ROOT=/data/bw_mon/bw_sysmon
LOG=$ROOT/log
RUN=$ROOT/run
MAIL_TMP=$RUN/mail.tmp
LOG0=$LOG/bw_sysmon.log
HIS_LOG=$LOG/history.log
CONF=$ROOT/conf

. $ROOT/conf/bw_sysmon.conf
. /data/bw_mon/bw_comm_mod/mail.mod

# create dir and log
[[ ! -d $LOG ]] && mkdir $LOG
[[ ! -d $RUN ]] && mkdir $RUN

echo "" >> $LOG0
echo "[$(datef)] $0: Begin." >> $LOG0
pre_mon

ntp_adjust
reboot_chk
hardware_chk

cpu_chk
loadavg_chk
swap_chk
disk_chk
secure_chk
log_chk

post_mon
echo "[$(datef)] $0: End." >> $LOG0

# rotate log
LOG_SIZE=$(du -k $LOG0 | awk '{print $1}')

if (( LOG_SIZE > MAX_LOG_SIZE ))
then
	echo "[$(datef)] rotate log: Begin." >> $LOG0
	[[ -f $LOG3 ]] && rm -fv $LOG3 >> $LOG0
	[[ -f $LOG2 ]] && mv -fv $LOG2 $LOG3 >> $LOG0
	[[ -f $LOG1 ]] && mv -fv $LOG1 $LOG2 >> $LOG0
	
	mv -fv $LOG0 $LOG1 >> $LOG0
fi

echo "" >> $LOG0

