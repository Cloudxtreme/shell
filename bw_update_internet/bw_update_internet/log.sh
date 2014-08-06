#!/bin/bash
PATH=/usr/local/mysql/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
read -p "please enter you ssh name:" SSH_NAME 
read -p "please enter you ssh password:" SSH_PASSWORD

export PATH
 expect -c "
                spawn /usr/bin/ssh -o StrictHostKeyChecking=no -i /data/update/update/huanggaoming  $SSH_NAME@113.108.228.38
                set timeout -1
                expect \"\*Enter passphrase\*:\"
                send \"$SSH_PASSWORD\r\"
                expect \"\*]*\"
		send \"sudo su\r\"
                      
            "
