#!/bin/bash
flist="["
while read line
    do  
        #tr -d "\012" $line
        #echo "[""'"$line"'"
        #$str="[""'"$line"'"
        flist=$flist"'"$line"'"","
        #$str="${line}"
    done < file.txt
flist=${flist%,*}"]"
echo $flist 
