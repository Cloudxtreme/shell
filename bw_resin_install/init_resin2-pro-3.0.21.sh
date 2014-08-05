#!/bin/sh

ROOT=$(pwd)
SCRIPTS=$ROOT/scripts
PKGS=$ROOT/pkgs
RESINVERSION=resin2_pro_3.0.21



datef(){ date "+%Y/%m/%d %H:%M" ; }

define_pkgs(){
	
	RESIN=resin-pro-3.0.21.tar.gz
	JAVA=jdk1.6.0_25.tar.gz
	PKGS_LIST="$RESIN $JAVA"
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
		tar zxvf $JAVA -C /data/java

        cd /data/java
        ln -s * jdk

        touch $PKGS/java_build/install_done.tag
}

ins_resin(){

         cd $PKGS
	 [[ ! -d ${RESINVERSION}_build ]] && mkdir ${RESINVERSION}_build

	 if [[ -f ${RESINVERSION}_build/install_done.tag ]];then
                echo "[$(datef)] ins_resin(): ${RESINVERSION} installed, skin!"
                return
         fi

	 tar zxf $RESIN -C ${RESINVERSION}_build
	 cd ${RESINVERSION}_build/*
	./configure --prefix=/usr/local/${RESINVERSION} --enable-jni --enable-64bit --enable-linux-smp --with-java-home=/data/java/jdk && make && make install 
        
	if [[ $? != "0" ]];then
		echo "[$(datef)] ins_${RESINVERSION}(): install error!"
		exit
	fi
	cd ../../../
    cp -fv $SCRIPTS/license_resin_pro_3.0.21.jar /usr/local/${RESINVERSION}/lib
	cp -fv $SCRIPTS/${RESINVERSION}.conf /usr/local/${RESINVERSION}/conf/${RESINVERSION}.conf

    cp -fv $SCRIPTS/${RESINVERSION} /etc/init.d/${RESINVERSION}
   
    chkconfig --add ${RESINVERSION}

    chmod 755 /etc/init.d/${RESINVERSION}

    [ ! -d  /data/log/${RESINVERSION} ] && mkdir -m777 -p /data/log/${RESINVERSION}
	touch $PKGS/${RESINVERSION}_build/install_done.tag
}


post_int(){

        echo "**************** Begin change www user mode *********************"
        if ! grep "^www" /etc/passwd
        then
                groupadd www
                useradd -g www -s /bin/bash -d /data/www www
        fi
                [[ -d /usr/local/${RESINVERSION} ]] && chown -R www:www /usr/local/${RESINVERSION}
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
check_rpm
#ins_java
ins_resin
post_int
finish_ins

