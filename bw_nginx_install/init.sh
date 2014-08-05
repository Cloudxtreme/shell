#!/bin/sh

ROOT=$(pwd)
SCRIPTS=$ROOT/scripts
PKGS=$ROOT/pkgs



datef(){ date "+%Y/%m/%d %H:%M" ; }

define_pkgs(){
	
	NGINX=nginx-1.0.6.tar.gz
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

ins_web_nginx(){
        cd $PKGS
	[[ ! -d nginx_build ]] && mkdir nginx_build
	
	if [[ -f nginx_build/install_done.tag ]];then
		echo "[$(datef)] ins_web_nginx(): nginx installed, skin!"
		return
	fi
	
	for files in nginx.conf htpasswd nginx
	do
		if [[ ! -f $SCRIPTS/$files ]]
		then
			echo "[$(datef)] ins_web_nginx(): $SCRIPTS/$files not found!"
			exit
		fi
	done
        
	tar xf $NGINX -C nginx_build
	cd nginx_build/*
	./configure --prefix=/usr/local/nginx --with-http_stub_status_module --without-select_module --without-poll_module --with-http_ssl_module && make && make install
	
	if [[ $? != "0" ]];then
		echo "[$(datef)] ins_web_nginx(): install error!"
		exit
	fi
	
	cd ../../../
	cp -fv $SCRIPTS/nginx.conf /usr/local/nginx/conf/
	cp -fv $SCRIPTS/htpasswd /usr/local/nginx/conf/
	cp -fv $SCRIPTS/nginx /etc/init.d/
	chmod +x /etc/init.d/nginx
	chkconfig --add nginx
	touch $PKGS/nginx_build/install_done.tag
}

post_int(){

        echo "**************** Begin change www user mode *********************"
        if ! grep "^www" /etc/passwd
        then
                groupadd www
                useradd -g www -s /bin/bash -d /data/www www
        fi
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

datef
define_pkgs
check_rpm
ins_web_nginx
post_int
finish_ins
