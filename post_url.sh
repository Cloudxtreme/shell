#!/bin/bash

while read line
    do
        #eval $(echo $line) |eval $(awk '{print "i1="$1";i2="$2}') 
        #echo $line |awk '{print $1}'|read e
        eval $(echo $line |awk '{printf("x=%s\ny=%s",$1,$2);}')
        #echo "curl -X POST 'http://carbiz5.baoxian.in/transactionService/transaction/cancel/${y}/${x}'"
        curl -X POST "http://carbiz5.baoxian.in/transactionService/transaction/cancel/${y}/${x}"
        sleep 5
    done < file.txt
