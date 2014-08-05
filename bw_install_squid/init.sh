#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:/usr/local/squid/sbin
export PATH

ROOT=$(pwd)
SCRIPTS=$ROOT/scripts
PKGS=$ROOT/pkgs

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, use sudo sh $0"
    exit 1
fi

datef(){ date "+%Y/%m/%d %H:%M" ; }

define_pkgs(){

        SQUID=squid-3.0.STABLE7.tar.gz
        PKGS_LIST="$SQUID"
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

ins_squid(){
        cd $PKGS
        [[ ! -d squid_build ]] && mkdir squid_build

        if [[ -f squid_build/install_done.tag ]];then
                echo "[$(datef)] ins_squid(): squid installed, skin!"
                return
        fi

        for files in squid.conf 
        do
                if [[ ! -f $SCRIPTS/$files ]]
                then
                        echo "[$(datef)] ins_squid(): $SCRIPTS/$files not found!"
                        exit
                fi
        done

        tar xzf $SQUID -C squid_build
        cd squid_build/*
        ./configure --prefix=/usr/local/squid --enable-async-io=160 --enable-follow-x-forwarded-for --enable-storeio=aufs,diskd,coss --with-maxfd=65536 --with-pthreads --enable-dlmalloc --enable-epoll --enable-cache-digests --enable-default-err-language=Simplify_Chinese --enable-err-languages="Simplify_Chinese English" --enable-stacktraces --enable-removal-policies=heap,lru --enable-delay-pools --enable-snmp --disable-internal-dns --enable-large-cache-files --with-large-files --with-aio --enable-x-accelerator-vary --disable-poll --enable-useragent-log --enable-referer-log --enable-kill-parent-hack --disable-ident-lookups --enable-ssl --enable-underscore
        make && make install
        if [[ $? != "0" ]];then
                echo "[$(datef)] ins_squid(): install error!"
                exit
        fi

        cd ../../../
        \cp -fv $SCRIPTS/squid.conf /usr/local/squid/etc/
        touch $PKGS/squid_build/install_done.tag
}

post_int(){

        echo "**************** Begin change squid user mode *********************"
        if ! grep "^squid" /etc/passwd
        then
                groupadd squid
                useradd -g squid -s /sbin/nologin squid
        fi
        chown -R squid.squid /usr/local/squid
        [[ ! -d /data/log/squid ]] && mkdir /data/log/squid -p && chown -R squid.squid /data/log/squid
        [[ ! -d /data/squid/cache ]] && mkdir /data/squid/cache -p && chown -R squid.squid /data/squid/cache
        squid -k parse
        if [[ $? != "0" ]];then
                echo "[$(datef)] ins_squid(): install error!"
                exit
            else
                /usr/local/squid/sbin/squid -z
        fi
        echo "/usr/local/squid/sbin/squid -s" >> /etc/rc.d/rc.local
        crontab -l > crontab.tmp
        echo "1 0 * * * /usr/local/squid/sbin/squid -k rotate" >> crontab.tmp
        crontab crontab.tmp
        rm -f crontab.tmp
        /usr/local/squid/sbin/squid -s
        echo "*************** End change squid user mode ************************"
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
ins_squid
post_int
finish_ins
