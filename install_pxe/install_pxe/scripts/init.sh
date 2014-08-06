#!/bin/bash
PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

ip=`ifconfig eth0|grep "inet addr:"|awk -F':' '{print $2}'|awk '{print $1}'`
netmask=`ifconfig eth0|grep "Mask"|awk '{print $4}'|awk -F: '{print $2}'`
get_ip=`ifconfig eth0|grep "inet addr:"|awk -F':' '{print $2}'|awk '{print $1}'|awk -F'.' '{print $4}'`
gateway=`ip route show|grep default|awk '{print $3}'`

#修改网卡eth0的IP地址
echo "IPADDR=$ip" >> /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i "s/BOOTPROTO=dhcp/BOOTPROTO=static/" /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i "s/ONBOOT=no/ONBOOT=yes/" /etc/sysconfig/network-scripts/ifcfg-eth0
echo "NETMASK=$netmask" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "GATEWAY=$gateway" >> /etc/sysconfig/network-scripts/ifcfg-eth0

#修改网卡eth1的IP地址
if [[ -f /etc/sysconfig/network-scripts/ifcfg-eth1 ]];then
	echo "IPADDR=192.168.100.$get_ip" >> /etc/sysconfig/network-scripts/ifcfg-eth1
	echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-eth1
	sed -i "s/BOOTPROTO=dhcp/BOOTPROTO=static/" /etc/sysconfig/network-scripts/ifcfg-eth1
	sed -i "s/ONBOOT=no/ONBOOT=yes/" /etc/sysconfig/network-scripts/ifcfg-eth1
else
	exit 1
fi

/etc/init.d/network restart

echo "nameserver 202.96.128.86" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf


###################add ssh key##########################
hongyuhuai_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCkdEOICSSI09LloSzOdP4kYEL48m/wh6DslFOgA/3Kz/8NhkJjjwe65CZ5WasNMiQ47mm4e7yG9K7s9fOoEcfItpIhPS0zoACEf7hs/uVwq78PwTkNsVhSHucbDoN7pnfT+v13eEd6LD1/afkQt/a7N/QSWpmCTglihb56OzDtJw== Administrator@WIN-6OMFV4C9GEP'

yuanhong_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCrFOXxFke87fmq+L+EPOS4c+HSbLJ3kKrLZAxNZJ8oZPaMoWFa7xGVU6EubRj6R6dYxiyz7dpmj8DLNJUsXtpIHOFCbq+65CfG4Ui55B7/bq7m5k/drWB5Wto+aFixkwSDa/CuZA8tzRMaMfMZ3B3E+VO/OtAxh5mSe+2N/RQ4nQ== yuanhong'

public_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQC8lEIf24U5CNVK/RXLzsOHQ8DvNiJNdjSxI1AXS4XfzDiU6yEB6DJjoW1nh9YiY4dgtPweM7oOeaNuzanc3ehrEdlsPvSxzcQxP7m2Ysrhg5d+gZQBROBNsB6mfy1Py1Lwv5LsHIWTvaUBfnqTQO+WmfnCmnkrjkV4QeyvWZDU7w== public'

liangshuhua_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDaqr4cw9HQxgmC0fpsrnOd+j3j1XPOVKL/sv1NqQvynN/02y0tc0ki4vCX7PWa1/zt/2SHTtkOloW0LLRuFsyfFFoAnwDqnIUhamRr2iI5ZUran6jsXpi/SAKnKMB3C7cR+T5sdWt/4piUSeSyAYpb7LMKSRh931DLEm8uzqYZqQ== liangshuhua'

qiuyuxian_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQC1pJoRU5rF4WRKf38sg7mlTfbC7XlboOgXl+dkKlcf+clk1wH5a4ki0HHAc5XHfxmY86ahQDPIQoY6kS1q5STb9xOjmH3SKjMGmbIuhRSGtG3P3c1huFWF5mjYhw49H2mN/tdOdQQtMRJn+P19jyNyubc95QTw92tJuKH0GdCPmQ== qiuyuxian'

liwuyu_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDZ0NOr5X/SRwO5d439N3//U3Zxo+Jaukb62Gl4WE89W0VhBzNDGQFf4D40YoQ7uQ2XQ+i2bv5S2M2OVJbgu2fvUAXUviyJCzPrhdP2jBnTczHtA29RYg59M/i/OciDo++5QVr/xX6wUvQe2qwA1AQkQZ1305RycXV9z2m0QbUs/Q== liwuyu'

   sed -i 's/^#PermitEmptyPasswords no$/PermitEmptyPasswords no/' /etc/ssh/sshd_config
   sed -i 's/^PasswordAuthentication yes$/PasswordAuthentication no/' /etc/ssh/sshd_config
   sed -i 's/^#RSAAuthentication yes$/RSAAuthentication yes/' /etc/ssh/sshd_config
   sed -i 's/^#PubkeyAuthentication yes$/PubkeyAuthentication yes/' /etc/ssh/sshd_config
   sed -i 's/^#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
   sed -i 's/^#StrictModes yes$/StrictModes no/' /etc/ssh/sshd_config
   sed -i 's/^PermitRootLogin no$/PermitRootLogin yes/' /etc/ssh/sshd_config
   sed -i 's/^#UseDNS yes$/UseDNS no/' /etc/ssh/sshd_config

   /etc/init.d/sshd restart

    name_list="hongyuhuai yuanhong public liangshuhua qiuyuxian liwuyu"
    for name in $name_list
    do
         useradd $name -g root
         cd /home/$name
         mkdir .ssh
         touch .ssh/authorized_keys
         chmod 700 .ssh
         chmod 600 .ssh/authorized_keys
         chown -R $name:root .ssh
         
    done

         echo "$hongyuhuai_key" > /home/hongyuhuai/.ssh/authorized_keys
         echo "$yuanhong_key" > /home/yuanhong/.ssh/authorized_keys
         echo "$public_key" > /home/public/.ssh/authorized_keys
         echo "$liangshuhua_key" > /home/liangshuhua/.ssh/authorized_keys
         echo "$qiuyuxian_key" > /home/qiuyuxian/.ssh/authorized_keys
         echo "$liwuyu_key" > /home/liwuyu/.ssh/authorized_keys
  
         sed -i '/^hongyuhuai/s/50[0-9]/0/' /etc/passwd
         sed -i '/^yuanhong/s/50[0-9]/0/' /etc/passwd
         sed -i '/^public/s/50[0-9]/0/' /etc/passwd
         sed -i '/^liangshuhua/s/50[0-9]/0/' /etc/passwd
         sed -i '/^qiuyuxian/s/50[0-9]/0/' /etc/passwd
         sed -i '/^liwuyu/s/50[0-9]/0/' /etc/passwd

########################add iptables##############################################
cat >/etc/sysconfig/iptables <<EOF
*nat
:PREROUTING ACCEPT [1:40]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [1:140]
-A INPUT -p icmp -j ACCEPT 
-A INPUT -i lo -j ACCEPT 
-A INPUT -i eth1 -j ACCEPT 
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
-A INPUT -p udp -m udp --sport 53 -j ACCEPT 
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT 
-A INPUT -s 113.108.228.44 -p udp -m udp --dport 161 -j ACCEPT 
-A INPUT -j REJECT --reject-with icmp-host-prohibited 
-A FORWARD -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW -j DROP 
-A FORWARD -f -m limit --limit 100/sec --limit-burst 100 -j ACCEPT 
-A OUTPUT -p tcp -m tcp --sport 31337 -j DROP 
-A OUTPUT -p tcp -m tcp --dport 31337 -j DROP 
COMMIT
EOF

chkconfig iptables on
/etc/init.d/iptables restart
