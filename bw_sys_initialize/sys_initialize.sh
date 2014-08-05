#!/bin/bash

PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

ROOT=$(pwd)
PKGS=$ROOT/pkgs
SCRIPTS=$ROOT/scripts
BACKUP=$ROOT/backup
NTPSERVER=210.72.145.44

# funtions
datef() { date "+%Y/%m/%d %H:%M" ; }

define_and_check_pkgs()
{
	[[ $PLATFORM == "32" ]] && NAIL=nail-12.3-1.el5.i386.rpm
	[[ $PLATFORM == "64" ]] && NAIL=nail-12.3-1.el5.x86_64.rpm
	
	local _PKGS_LIST="$NAIL"

	for pkgname in $_PKGS_LIST
	do
		if [[ ! -f $PKGS/$pkgname ]]
		then
			echo "[$(datef)] check_pkgs(): $PKGS/$pkgname not found!"
			exit
		fi
	done
}

check_scripts()
{
	local _SCRIPTS_LIST="sysctl.conf rc.local bw_log"
	
	for scriptname in $_SCRIPTS_LIST
	do
		if [[ ! -f $SCRIPTS/$scriptname ]]
		then
			echo "[$(datef)] check_scripts(): $SCRIPTS/$scriptname not found!!!"
			exit
		fi
	done
}

ins_nail()
{
	if ! rpm -qi nail > /dev/null 2>&1
	then
		rpm -ivh $PKGS/$NAIL
		if [[ $? == "0" ]]
		then
			echo "[$(datef)] nail installed successfully!"
		else
			echo "[$(datef)] cannot install nail!!!"
			exit
		fi
	fi
}

check_rpm()
{
	local _RPMS_LIST="fail2ban freetype gcc gcc-c++ gd glibc-devel glibc-headers lrzsz net-snmp ntp nail nmap sysstat"
	
	for rpmname in $_RPMS_LIST
	do
		if ! rpm -qi $rpmname > /dev/null 2>&1
		then
			#echo "[$(datef)] check_rpm(): $rpmname not installed!"
			yum -y install $rpmname
		fi
	done
}


config_lang()
{
	cp -fpv /etc/sysconfig/i18n $BACKUP
	
	sed -i 's/^LANG=.*$/LANG="en_US"/' /etc/sysconfig/i18n
	. /etc/sysconfig/i18n
}

config_ssh()
{
	cp -fpv /etc/ssh/sshd_config $BACKUP
	
#	sed -i 's/^#PermitRootLogin yes$/PermitRootLogin no/' /etc/ssh/sshd_config
	sed -i 's/^#UseDNS yes$/UseDNS no/' /etc/ssh/sshd_config
	
	local _SSH_PID=$(netstat -tnlp | grep "\:22\>" | awk '{print $7}' | awk -F'/' '{print $1}')
	kill -HUP $_SSH_PID
}

del_void_user()
{
	local _void_user="adm lp sync shutdown halt news uucp operator games gopher avahi nscd"
	
	cp -fpv /etc/passwd /etc/shadow /etc/group $BACKUP
	
	for users in $_void_user
	do
		userdel $users
	done
}

config_inittab()
{
	cp -fpv /etc/inittab $BACKUP
	
	sed -i 's/^id.*$/id:3:initdefault:/' /etc/inittab
	sed -i 's|^ca::ctrlaltdel:/sbin/shutdown -t3 -r now$|#ca::ctrlaltdel:/sbin/shutdown -t3 -r now|' /etc/inittab
}

config_ntsysv()
{
	local _keep_proc="cpuspeed crond microcode_ctl network sshd syslog"
	
	for procs in $(chkconfig --list | grep 3:on | awk '{print $1}')
	do
		if ! echo $_keep_proc | grep "\<$procs\>" > /dev/null 2>&1
		then
			chkconfig --level 3 $procs off
		fi
	done
	
	chkconfig --list | grep 3:on
}

config_hostname()
{
	local _HOST_NAME=$(awk -F'=' '/^HOST_NAME=/ {print $2}' conf_me.conf)
	
	cp -fpv /etc/sysconfig/network $BACKUP
	
	if grep "^HOSTNAME=" /etc/sysconfig/network > /dev/null 2>&1
	then
		sed -i '/^HOSTNAME=.*$/d' /etc/sysconfig/network
	fi
	
	hostname $_HOST_NAME
	echo "HOSTNAME=$_HOST_NAME" >> /etc/sysconfig/network
	. /etc/sysconfig/network
}

config_network_param()
{
	cp -fpv /etc/sysctl.conf /etc/rc.local $BACKUP
	
	echo "" >> /etc/sysctl.conf
	cat $SCRIPTS/sysctl.conf >> /etc/sysctl.conf
	sysctl -p
	
	echo "" >> /etc/rc.local
	cat $SCRIPTS/rc.local >> /etc/rc.local
	. /etc/rc.local
}

mk_some_dir()
{
	[[ ! -d /data/log ]] && mkdir -v /data/log
	chmod 777 /data/log
	
	[[ ! -d /data/tmp ]] && mkdir -v /data/tmp
	chmod 777 /data/tmp
}

add_logrotate()
{
	cp -fpv $SCRIPTS/bw_log /etc/logrotate.d
	
	mv -vf /etc/cron.daily/logrotate /etc/cron.hourly/
}

add_snmpd()
{
        [ ! -d /etc/snmp ] && mkdir -p /etc/snmp
	[ -f /etc/snmp/snmpd.conf ] && mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.initbackup
	 cp -fpv $SCRIPTS/snmpd.conf /etc/snmp
        [ -f /etc/snmp/snmpd.options ] && mv -f /etc/snmp/snmpd.options /etc/snmp/snmpd.options.bak
        if [[ -f /etc/init.d/snmpd && "${snmpPort}" != "161" ]]
          then
	    if ! grep -q "OPTIONS=.*TCP" /etc/init.d/snmpd
          then
            sed -i "s/OPTIONS=.*-a/& ${snmpPort}/" /etc/init.d/snmpd && echo "snmp端口已经修改为${snmpPort}" | tee -a ${stdOutLog} || echo "snmp端口修改失败" | tee -a ${stdErrLog}
        /etc/init.d/snmpd restart
        fi
        fi
}

systemtime()
{
       ps -ef |  grep ntpd | grep -v grep && /etc/init.d/ntpd stop
       ntpdate $NTPSERVER && hwclock -w && echo "系统时间同步完成" | tee -a ${stdOutLog} || echo "系统时间同步失败" | tee -a ${stdErrLog}
}

########
# main #
########
[[ ! -d $BACKUP ]] && mkdir $BACKUP

# MUST run in the directory which 'install.sh' resides
if [[ ! -f $ROOT/run_here.tag ]]
then
	echo "[$(datef)] change directory and run as './install'!"
	exit
fi

# check platform
case "$(file /bin/ls | awk '{print $3}')" in
	32-bit)
		PLATFORM="32"
		;;
	64-bit)
		PLATFORM="64"
		;;
	*)
		echo "[$(datef)] must run in '32-bit' or '64-bit' RHEL OS!"
		exit
		;;
esac

# define and check package
define_and_check_pkgs

# check conf_me.conf
if [[ $(awk -F'=' '/^HOST_NAME=/ {print $2}' conf_me.conf) == "" ]]
then
	echo "[$(datef)] conf_me.conf define error, see readme!"
	exit
fi

# check scripts
check_scripts

# install nail for email
ins_nail

# check rpm
check_rpm


# begin to initialize
config_lang
#config_ssh
del_void_user
config_inittab
config_ntsysv
config_hostname
config_network_param
mk_some_dir
add_logrotate
add_snmpd
systemtime

# complete
echo ""
echo "###########################################################"
echo "# [$(datef)] congratulagions!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "# [$(datef)] pls modify /etc/fstab & mount /data noatime!!"
echo "# [$(datef)] and then run 'shutdown -r now' to reboot sys!"
echo "# [$(datef)] have fun!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "###########################################################"
echo ""
