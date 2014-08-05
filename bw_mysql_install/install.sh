#!/bin/bash

PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

ROOT=$(pwd)
PKGS=$ROOT/pkgs
SCRIPTS=$ROOT/scripts

# funtions
datef() { date "+%Y/%m/%d %H:%M" ; }

define_pkgs()
{
	MYSQL=mysql-5.5.11-linux2.6-x86_64.tar.gz
	
	PKGS_LIST="$MYSQL"
}

check_pkgs()
{
	if [[ ! -f $PKGS/$1 ]]
	then
		echo "[$(datef)] check_pkgs(): $PKGS/$1 not found!"
		exit
	fi
}

check_gcc()
{
	if ! which gcc > /dev/null 2>&1
	then
		echo "[$(datef)] gcc not found!"
		exit
	fi
}

check_rpm()
{
	RPMS_LIST="ncurses-devel gcc-c++"
	
	rpm -qa > rpm_installed.list
	
	for rpmname in $RPMS_LIST
	do
		if ! grep $rpmname rpm_installed.list > /dev/null 2>&1
		then
			echo "[$(datef)] check_rpm(): $rpmname not installed!"
			exit
		fi
	done
        yum -y install libaio
}


ins_mysql()
{
        cd $PKGS
	[[ ! -d mysql_build ]] && mkdir mysql_build
	
	if [[ -f mysql_build/install_done.tag ]]
	then
		echo "[$(datef)] ins_mysql(): mysql installed, skin!"
		return
	fi
	
	for files in my.cnf
	do
		if [[ ! -f $SCRIPTS/$files ]]
		then
			echo "[$(datef)] ins_nginx(): $SCRIPTS/$files not found!"
			exit
		fi
	done
	
	tar xf $MYSQL -C /usr/local/
        cd /usr/local
        mv mysql-5.5.11-linux2.6-x86_64 mysql
	
        cd /usr/local/mysql
	cp -fv support-files/mysql.server /etc/init.d/mysqld
	chmod +x /etc/init.d/mysqld
	chkconfig --add mysqld
	chkconfig --level 3 mysqld on
	
	cp -fv $SCRIPTS/my.cnf /etc
        cd $PKGS
        touch mysql_build/install_done.tag
	
}

post_install()
{
	if ! grep "^mysql" /etc/passwd
	then
                groupadd mysql
		useradd -s /sbin/nologin -g mysql mysql
	fi
	
        /usr/local/mysql/scripts/mysql_install_db --user=mysql --force --basedir=/usr/local/mysql --datadir=/data/mysql/data	
	chown -R mysql:mysql /usr/local/mysql /data/mysql
	
	[[ ! -d /data/log/mysql ]] && mkdir -p /data/log/mysql
	chown -R mysql:mysql /data/log/mysql
	
	echo '' >> /etc/profile
	echo 'PATH=/usr/local/mysql/bin:$PATH' >> /etc/profile
	echo 'export PATH' >> /etc/profile
	
	[[ ! -d /data/log ]] && mkdir /data/log
	[[ ! -d /data/tmp ]] && mkdir /data/tmp
	chmod 777 /data/log /data/tmp
}

########
# main #
########


# define packages' name
define_pkgs

# check the package exists or not
for pkgname in $PKGS_LIST
do
	check_pkgs $pkgname
done

# check gcc
check_gcc

# check rpm needed
check_rpm

# install packages
cd $PKGS

ins_mysql

# something to do
post_install

# install complete
echo ""
echo "###########################################################"
echo "# [$(datef)] congratulagions!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "# [$(datef)] don't forget to modify configuration files!!!"
echo "# [$(datef)] have fun!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "###########################################################"
echo ""
