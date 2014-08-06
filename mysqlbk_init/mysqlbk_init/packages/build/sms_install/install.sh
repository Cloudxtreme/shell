#!/bin/bash
ROOT=$(pwd)
SCRIPTS=$ROOT/scripts
PKGS=$ROOT/pkgs


#tar -zxvf libwww-perl-5.837.tar.gz -C $PKGS

cd /$PKGS/libwww-perl-5.837

perl ./Makefile.PL  && make && make install 

cp $SCRIPTS/sendsmspost.pl  /usr/local/bin/

cd /usr/local/bin/  

chmod 755 sendsmspost.pl
mkdir -p /data/log/zabbix/

perl sendsmspost.pl

res=$? 

if [[   $res -eq 0    ]] ;then 
echo -e  "\033[44m Install sms Successfully!! \033[0m"
echo   "SMS is location on   /usr/local/bin/sendsmspost.pl "
else 
echo -e   "\033[41m Install sms Fail!! \033[0m" 
fi 




