#!/bin/bash
PWD=$(pwd $0)
pks=$PWD/packages
pksbud=$PWD/packages/build
sms=sms_install.tar.gz
smsdirname=$(echo  $sms|sed  's/.tar.gz//')
init_conf=$PWD/packages/conf
mydumpergz=mydumper-0.5.2.tar.gz
xtrabackgz=$PWD/packages/percona-xtrabackup-2.1.6-702.rhel5.x86_64.rpm
mydumperdir=$(echo  $mydumpergz|sed  's/.tar.gz//')

###安装短信报警
sms_install()
{
if [[ ! -f  /usr/local/bin/sendsmspost.pl  ]];then
cd  $pks
tar -zxvf $sms -C $pksbud
cd  $pksbud/$smsdirname
/bin/bash install.sh
fi  
}

###初始化数据库备份目录
# define directory
init_dir()
{
ROOT=/data/bw_mon/bw_mysqlbk
LOG=$ROOT/log
RUN=$ROOT/run
LOCAL_DATA=$ROOT/local_data
CONF=$ROOT/conf

if [[ -d $ROOT  ]];then
echo "$ROOT directory is exist mv it backup"
mv $ROOT  /data/bw_mon/bw_mysqlbk_bak_`date -I`
echo "backupdir:/data/bw_mon/bw_mysqlbk_bak_`date -I` "
fi


[[ -d $ROOT ]] ||  mkdir -p $ROOT
[[ -d $LOG  ]]  || mkdir -p $LOG
[[ -d $RUN  ]]  || mkdir -p $RUN
[[ -d $LOCAL_DATA ]] || mkdir -p $LOCAL_DATA
[[ -d $CONF ]]  ||  mkdir -p $CONF

cp $init_conf/*  $CONF 
cp $PWD/bw_mysqlbk.sh  $ROOT
cp $PWD/imexport.sh  $ROOT
cp   $init_conf/bw_sizebk.log $ROOT/log
}

###安装mydumper多线程备份
install_mydumper()
{
if [[ ! -f /usr/local/bin/mydumper  ]];then 

cd  $pks
tar -zxvf $mydumpergz -C $pksbud
cd  $pksbud/$mydumperdir
cmake .
make && make install
 
fi


}

###安装xtrabackup备份
install_xtra()
{
if [[ ! -f /usr/bin/innobackupex  ]];then

yum localinstall  $xtrabackgz  -y --nogpgcheck
#cd /tmp
#wget http://www.percona.com/redir/downloads/XtraBackup/LATEST/RPM/rhel5/x86_64/percona-xtrabackup-2.1.6-702.rhel5.x86_64.rpm
#yum localinstall  percona-xtrabackup-2.1.6-702.rhel5.x86_64.rpm   -y –nogpgcheck  
fi
}

init_dir
install_xtra
install_mydumper
sms_install
echo "All initing have finished!!"
