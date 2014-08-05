#!/bin/bash

PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

ROOT=$(pwd)
PKGS=$ROOT/pkgs
SCRIPTS=$ROOT/scripts

# funtions
datef() { date "+%Y/%m/%d %H:%M" ; }

define_pkgs()
{
	PUPPET="facter-1.6.7.tar.gz puppet-2.7.13.tar.gz"
	
	PKGS_LIST="$PUPPET"
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


ins_puppetclient()
{       ntpdate ntp.api.bz
        cd $PKGS
	[[ ! -d puppet_build ]] && mkdir puppet_build
	
	if [[ -f puppet_build/install_done.tag ]]
	then
		echo "[$(datef)] ins_puppetclient(): puppetclient installed, skin!"
		return
	fi
	
	for files in config.tar.gz
	do
		if [[ ! -f $SCRIPTS/$files ]]
		then
			echo "[$(datef)] ins_puppetclient(): $SCRIPTS/$files not found!"
			exit
		fi
	done
        for package in $PUPPET
        do
 	     tar -xzf $package
             dir=`echo "$package"|awk -F '-' '{print $1}'` 
             #dir=awk -F '-' '{print $1}' $package
             #dir=`awk -F '-' '{print $1}' $package`
             #echo $dir
             cd ${dir}*
             ruby install.rb
             cd ..
        done
        cd $PKGS
        touch puppet_build/install_done.tag
	
}

post_install()
{
        [[ ! -d /data/log/puppet ]] && mkdir /data/log/puppet 
        cd $SCRIPTS
        tar -xzPf config.tar.gz
        chkconfig --add puppet
        chkconfig puppet on
        if ! grep "^puppet" /etc/passwd
        then
           useradd -M -s /sbin/nologin puppet    
           puppetd --mkusers
        fi
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

ins_puppetclient

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
