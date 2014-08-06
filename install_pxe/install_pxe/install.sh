#!/bin/bash
#安装PXE部署环境
Root=$(pwd)
Conf=$Root/server.conf
Backup=$Root/backup

if [[ ! -f $Conf ]];then
	echo "Configuration file not exist!!!"
	exit 1
else
	. $Conf
fi

network()
{
#修改eth0网卡的配置文件

sed -i "s/BOOTPROTO=dhcp/BOOTPROTO=static/" /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i "s/ONBOOT=no/ONBOOT=yes/" /etc/sysconfig/network-scripts/ifcfg-eth0
echo "IPADDR=$ip_address" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "NETMASK=$netmask" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "GATEWAY=$gateway" >> /etc/sysconfig/network-scripts/ifcfg-eth0

if [[ ! -f /etc/sysconfig/network-scripts/ifcfg-eth1 ]];then
	echo "ifcfg-eth1 configuration file not exist!!!"
else

#修改eth1网卡的配置文件
get_ip=`ifconfig eth0|grep "inet addr:"|awk -F':' '{print $2}'|awk '{print $1}'|awk -F'.' '{print $4}'`
sed -i "s/BOOTPROTO=dhcp/BOOTPROTO=static/" /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i "s/ONBOOT=no/ONBOOT=yes/" /etc/sysconfig/network-scripts/ifcfg-eth1
echo "IPADDR=192.168.100.$get_ip" >> /etc/sysconfig/network-scripts/ifcfg-eth1
echo "NETMASK=255.255.255.0"  >> /etc/sysconfig/network-scripts/ifcfg-eth1
fi

}


install()
{
grep "iso9660" /etc/mtab
rev=`echo $?`
if [[ $rev -eq 0 ]];then
        umount /dev/cdrom
fi
#配置yum源
cp -a ./conf/CentOS5-Base-163.repo /etc/yum.repos.d/CentOS-Base.repo
yum clean all

#配置DNS
echo "nameserver 202.96.128.86">/etc/resolv.conf
echo "nameserver 8.8.8.8">>/etc/resolv.conf

#安装TFTP
yum -y install system-config-netboot tftp-server xinetd

#安装vsftpd
yum -y install vsftpd

#安装dhcp
yum -y install dhcp

}

modify_conf()
{
#修改DHCP配置文件
cp -a ./conf/dhcpd.conf /etc/dhcpd.conf
sed -i "s/172.16.1.1/$ip_address/g" /etc/dhcpd.conf
sed -i "s/172.16.1.2/$gateway/g" /etc/dhcpd.conf
sed -i "s/172.16.1.0/$network/" /etc/dhcpd.conf
sed -i "s/255.255.255.0/$netmask/g" /etc/dhcpd.conf
sed -i "s/172.16.1.33/$f_ip/" /etc/dhcpd.conf
sed -i "s/172.16.1.44/$e_ip/" /etc/dhcpd.conf
sed -i "s/pxe.org/$domain_name/" /etc/dhcpd.conf

#修改KS文件
if [[ ! -d /var/ftp/pub/scripts ]];then
	mkdir /var/ftp/pub/scripts
fi
cp -a ./conf/ks.cfg /var/ftp/pub/scripts/ks.cfg
sed -i "s/172.16.1.1/$ip_address/g" /var/ftp/pub/scripts/ks.cfg

#拷贝初始化脚本
cp -a ./scripts/* /var/ftp/pub/scripts

#拷贝yum源文件
cp -a ./conf/CentOS5-Base-163.repo /var/ftp/pub/scripts

##
rm -f /tftpboot/linux-install/pxelinux.cfg/default
cp -a ./conf/default /tftpboot/linux-install/pxelinux.cfg/default
sed -i "s/172.16.1.1/$ip_address/g" /tftpboot/linux-install/pxelinux.cfg/default

}

pxe()
{
#挂载光盘和拷贝安装文件
grep "iso9660" /etc/mtab
rev=`echo $?`
if [[ $rev -eq 0 ]];then
	umount /dev/cdrom
else
	mount /dev/cdrom /mnt
fi

if [[ ! -d /var/ftp/pub/RHEL5 ]];then
	mkdir /var/ftp/pub/RHEL5
fi
cp -r /mnt/* /var/ftp/pub/RHEL5

pxeos -a -i "auto install linux system" -p FTP -D 0 -s $ip_address -L /pub/RHEL5 -K ftp://$ip_address/pub/scripts/ks.cfg linux
}

chk_service()
{
#重启网络
/etc/init.d/network restart

#启动TFTP服务
chkconfig tftp on
chkconfig xinetd on
service xinetd restart

#启动FTP服务
chkconfig vsftpd on
service vsftpd restart

#启动DHCP服务
service dhcpd restart
chkconfig dhcpd on

}

network
install
pxe
modify_conf
chk_service
