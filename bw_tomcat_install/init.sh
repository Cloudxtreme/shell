#!/bin/sh

ROOT=$(pwd)
SCRIPTS=$ROOT/scripts
PKGS=$ROOT/pkgs



datef(){ date "+%Y/%m/%d %H:%M" ; }

define_pkgs(){
	
	TOMCAT=apache-tomcat-6.0.35.tar.gz
	JAVA=jdk-6u30-linux-x64.bin
#	JAVA1_5=jdk1.5.0_22.tar.gz
        PKGS_LIST="$TOMCAT $JAVA"
	for package in $PKGS_LIST
	do
	    if [[ ! -f $PKGS/$package ]];then
	          echo "[$(datef)] check_scripts(): $PKGS/$package not found!!!"
	          exit
	    fi
	done
}

check_rpm()
{
	RPMS_LIST="perl-Config-General pcre-devel zlib-devel ncurses-devel gcc-c++ gcc glibc glibc-devel glibc-headers libxml2-devel autoconf curl curl-devel krb5-devel e2fsprogs-devel libidn-devel openssl-devel"
	local _NOTFOUNDRPM=""
	
	for rpmname in $RPMS_LIST
	do
		if ! rpm -qi $rpmname > /dev/null 2>&1
		then
			_NOTFOUNDRPM="${rpmname} ${_NOTFOUNDRPM}"
		fi
	done
	
	if [[ ! -z $_NOTFOUNDRPM ]];then
		echo "[$(datef)] check_rpm(): $_NOTFOUNDRPM not installed!"
		yum -y install $_NOTFOUNDRPM
	fi
}

ins_java(){
		

        cd $PKGS
        [[ ! -d java_build ]] && mkdir java_build

        if [[ -f java_build/install_done.tag ]];then
                echo "[$(datef)] ins_java(): java installed, skin!"
                return
        fi

        [[ ! -d /data/java ]] && mkdir -pv /data/java
        echo "\n"| sh jdk-6u30-linux-x64.bin
        mv jdk1.6.0_30 /data/java/jdk1.6.0_30
        cd /data/java
        ln -s jdk1.6.0_30 jdk

#        cd $PKGS
#		tar zxvf $JAVA1_5 -C /data/java

        touch $PKGS/java_build/install_done.tag
}

ins_tomcat(){

         cd $PKGS
	 [[ ! -d tomcat_build ]] && mkdir tomcat_build

	 if [[ -f tomcat_build/install_done.tag ]];then
                echo "[$(datef)] ins_tomcat(): tomcat installed, skin!"
                return
         fi

	 tar zxf $TOMCAT -C /usr/local
	 cd /usr/local
         ln -s apache-tomcat-6.0.35 tomcat
        
	cp -fv $SCRIPTS/server.xml /usr/local/tomcat/conf/server.xml
        cp -fv $SCRIPTS/logging.properties /usr/local/tomcat/conf/logging.properties
        cp -fv $SCRIPTS/tomcat /etc/init.d/tomcat
   
    chkconfig --add tomcat

    chmod 755 /etc/init.d/tomcat

    [ ! -d  /data/log/tomcat ] && mkdir -m777 -p /data/log/tomcat
	touch $PKGS/tomcat_build/install_done.tag
        echo '' >> /etc/profile
        echo 'export JAVA_HOME=/data/java/jdk' >> /etc/profile
        echo 'export JRE_HOME=/data/java/jdk/jre' >> /etc/profile
        echo 'export CATALINA_HOME=/usr/local/tomcat' >> /etc/profile
        echo 'export TOMCAT_HOME=/usr/local/tomcat' >> /etc/profile
        echo 'export PATH=$PATH:$JAVA_HOME/bin:$TOMCAT_HOME/bin' >> /etc/profile
        echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >> /etc/profile
        source /etc/profile
}


post_int(){

        echo "**************** Begin change www user mode *********************"
        if ! grep "^www" /etc/passwd
        then
                groupadd www
                useradd -g www -s /bin/bash -d /data/www www
        fi
                [[ -d /usr/local/tomcat ]] && chown -R www:www /usr/local/tomcat /usr/local/apache-tomcat-6.0.35
        echo "*************** End change www user mode ************************"
}

finish_ins(){
        # install complete
        echo ""
        echo "###########################################################"
        echo "# [$(datef)] congratulagions!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "# [$(datef)] don't forget to modify configuration files!!!"
        echo "# [$(datef)] based on your system resources like mem size "
        echo "###########################################################"
        echo ""
}

define_pkgs
#check_rpm
ins_java
ins_tomcat
post_int
finish_ins

