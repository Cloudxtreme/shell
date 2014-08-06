#!/bin/bash
#/bin/bash
#clear pxe

#remove xinetd and tftp
chkconfig tftp off
chkconfig xinetd off
service xinetd stop

yum -y remove system-config-netboot tftp-server xinetd

#remove vsftpd
chkconfig vsftpd off
service vsftpd stop

if [[ -d /var/ftp ]];then
	rm -rf /var/ftp
fi
yum -y remove vsftpd

#remove dhcp
service dhcpd stop
chkconfig dhcpd off

yum -y remove dhcp
