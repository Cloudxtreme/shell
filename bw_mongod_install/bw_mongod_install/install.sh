#!/bin/bash

PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

ROOT=$(pwd)
PKGS=$ROOT/pkgs
SCRIPTS=$ROOT/scripts

# funtions
datef() { date "+%Y/%m/%d %H:%M" ; }

define_pkgs()
{
	PACKAGES="mongodb-linux-x86_64-1.8.1.tgz"
	
	PKGS_LIST="$PACKAGES"
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
	RPMS_LIST="ruby ruby-irb ruby-libs ruby-rdoc"
	
	rpm -qa > rpm_installed.list
	
	for rpmname in $RPMS_LIST
	do
		if ! grep $rpmname rpm_installed.list > /dev/null 2>&1
		then
			echo "[$(datef)] check_rpm(): $rpmname not installed!"
	#		exit
		fi
	done
        yum -y install $RPMS_LIST
}


ins_mongod()
{       ntpdate ntp.api.bz
        cd $PKGS
	[[ ! -d build ]] && mkdir build
	
	if [[ -f build/install_done.tag ]]
	then
		echo "[$(datef)] ins_mongod(): mongod installed, skin!"
		return
	fi
	
	for files in config.tar.gz
	do
		if [[ ! -f $SCRIPTS/$files ]]
		then
			echo "[$(datef)] ins_mongod(): $SCRIPTS/$files not found!"
			exit
		fi
	done
        for package in $PKGS_LIST
        do  
 	     tar -xzf $package -C /usr/local
             cd /usr/local
             mv mongodb-linux-x86_64-1.8.1 /usr/local/mongodb
        done
        cd $PKGS
        touch build/install_done.tag
	
}

post_install()
{       if ! grep "^mongod" /etc/passwd
        then
           useradd -s /sbin/nologin mongod
        fi
        [[ ! -d /data/mongodb/data ]] && mkdir -p /data/mongodb/data
        [[ ! -d /data/log/mongodb ]] && mkdir -p /data/log/mongodb
        cd $SCRIPTS
        tar -xzPf config.tar.gz
        chown -R mongod.mongod /data/mongodb/data
        chown -R mongod.mongod /data/log/mongodb
        chown -R mongod.mongod /usr/local/mongodb
        chkconfig --add mongod
        chkconfig mongod on
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
#check_rpm

# install packages
cd $PKGS

ins_mongod

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
