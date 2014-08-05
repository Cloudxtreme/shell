#/bin/bash 
#Changes in the system initialization
#Some args need to Change!!
Localdir=`pwd`
BACKUP=$Localdir/backup
CONF=$Localdir/sys.conf
shellname=$(basename $0)
cd /usr/local/tools
#Determine whether you are in the right position
if [[ !  -f  $Localdir/$shellname  ]];then
echo "Please cd to the directory location of the script at the same level,Exit"
exit
fi

[[ -d $BACKUP  ]] || mkdir -p $BACKUP
. $CONF
function gennip ()
{
re=`echo $IP | awk -F. '{printf "%d",$1*256^3+$2*256^2+$3*256+$4}'`
echo "$re"
}

function config_hostname()
{
IPADDR=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
for IP in $IPADDR
do
ipn=`gennip $IP`
if [ $ipn -ge 167772160 -a $ipn -le 184549376 -o $ipn -ge 2130706432 -a $ipn -le 2147483648 -o $ipn -ge 2886729728 -a $ipn -le 2887778304 -o $ipn -ge 3232235520 -a $ipn -le 3232301056 ]; then
IPP=`echo $IP|awk -F'.' '{print $NF}'`
echo "-----Starting configure the Hostname!"
        local _HOST_NAME=$base_hostname$IPP
        
        cp -fpv /etc/sysconfig/network $BACKUP
        
        if grep "^HOSTNAME=" /etc/sysconfig/network > /dev/null 2>&1
        then
                sed -i '/^HOSTNAME=.*$/d' /etc/sysconfig/network
        fi
        
        hostname $_HOST_NAME
        echo "HOSTNAME=$_HOST_NAME" >> /etc/sysconfig/network
        . /etc/sysconfig/network
        if ! grep  "$_HOST_NAME"  /etc/hosts |grep "$IP" > /dev/null 2>&1
	then
	echo "$IP	$_HOST_NAME"  >> /etc/hosts
	fi
echo "-----Configure hostname Have done!"
fi
done 
}

config_lang()
{
	if ! grep  "UTF-8"  /etc/sysconfig/i18n > /dev/null 2>&1
	then
	cp -fpv /etc/sysconfig/i18n $BACKUP
	sed -i 's/^LANG=.*$/LANG="en_US.UTF-8"/' /etc/sysconfig/i18n
	. /etc/sysconfig/i18n
	fi
}


config_network_param()
{
   if ! grep "synack_retries" /etc/sysctl.conf > /dev/null 2>&1
   then
	cp -fpv /etc/sysctl.conf /etc/rc.local $BACKUP
	
	echo "" >> /etc/sysctl.conf
echo  "
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
fs.file-max = 6553500
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.eth0.secure_redirects = 1
net.ipv4.conf.lo.secure_redirects = 1
net.ipv4.conf.default.secure_redirects = 1
net.ipv4.conf.all.secure_redirects = 1
net.ipv4.conf.eth0.accept_redirects = 0
net.ipv4.conf.eth0.send_redirects = 0
net.ipv4.conf.lo.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1800
net.core.wmem_max = 8388608
net.core.rmem_max = 8388608
net.ipv4.tcp_rmem = 4096 873814 8738140
net.ipv4.tcp_wmem = 4096 873814 8738140
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1" >> /etc/sysctl.conf
	sysctl -p
fi
	
}



config_hostname
config_lang
#config_network_param

if  grep base_init.sh /etc/rc.d/rc.local  > /dev/null 2>&1
then
sed -i '/base_init.sh/ {s/^/#/}'  /etc/rc.d/rc.local
fi 

