#!/bin/sh 

sendMail(){

SENDER="support@uwan.com"
TO_WHO="support@cndw.com"
SMTP_SVR="121.9.245.25"
SMTP_USR="support@uwan.com"
SMTP_PSW="SWH2pJi1yAo0NCKNaH"

# usage: sendMail SUBJECT MAIL_FILE
local _SUBJECT=$1
local _MAIL_FILE=$2

env MAILRC=/dev/null from=$SENDER smtp=$SMTP_SVR \
smtp-auth-user=$SMTP_USR smtp-auth-password=$SMTP_PSW smtp-auth=login \
nail -n -s "$_SUBJECT" "$TO_WHO" < $_MAIL_FILE

}

pschecklog(){

PSLOG=/data/log/ps.log
MAIL_TMP=/data/log/mail.tmp
ps auxwwwf |egrep -v "snmpd|php|mysqld|nginx|java|memcached" > $PSLOG
echo -e "#############\n ps chek report \n#############\n" >> $MAIL_TMP
cat $PSLOG >> $MAIL_TMP
echo"" >> $MAIL_TMP
echo -e "#############\n last chek report \n#############\n" >> $MAIL_TMP
last | head -25 >> $MAIL_TMP


}

pschecklog

HOST_NAME=$(hostname)
for iface in eth0 eth0:1 eth1
do
     ETH_IF=$(ifconfig $iface | awk -F: '/inet addr/{split($2,a," ") ; print a[1]}')
     [[ ! -z $ETH_IF ]] && break
done
TITLE="${HOST_NAME}(${ETH_IF}): ps and last report"
sendMail "$TITLE" $MAIL_TMP
