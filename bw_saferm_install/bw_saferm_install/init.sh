#!/bin/sh

ROOT=/data/tools/bw_saferm_install
SCRIPTS=$ROOT/scripts
PKGS=$ROOT/pkgs



datef(){ date "+%Y/%m/%d %H:%M" ; }

define_pkgs(){
	
	SAFERM=safe-rm-0.10.tar.gz
	for package in $PKGS_LIST
	do
	    if [[ ! -f $PKGS/$package ]];then
	          echo "[$(datef)] check_scripts(): $PKGS/$package not found!!!"
	          exit
	    fi
	done
}

ins_safe_rm(){
        cd $PKGS
	[[ ! -d saferm_build ]] && mkdir saferm_build
	
	if [[ -f saferm_build/install_done.tag ]];then
		echo "[$(datef)] ins_safe_rm(): saferm installed, skin!"
		return
	fi
	
	for files in safe-rm.conf
	do
		if [[ ! -f $SCRIPTS/$files ]]
		then
			echo "[$(datef)] ins_safe_rm(): $SCRIPTS/$files not found!"
			exit
		fi
	done
        
	tar xf $SAFERM -C saferm_build
	cd saferm_build/*
	cp -fv safe-rm /usr/local/bin
	ln -s /usr/local/bin/safe-rm /usr/local/bin/rm
	
	if [[ $? != "0" ]];then
		echo "[$(datef)] ins_safe_rm(): install error!"
		exit
	fi
	
	cd ../../../
	cp -fv $SCRIPTS/safe-rm.conf /etc/
	touch $PKGS/saferm_build/install_done.tag
}
finish_ins(){
        # install complete
        echo ""
        echo "###########################################################"
        echo "# [$(datef)] congratulagions!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "# [$(datef)] don't forget to modify configuration files!!!"
        echo "# [$(datef)] based on your system resources like mem size "
        echo "###########################################################"
        echo ""
}

datef
define_pkgs
ins_safe_rm
finish_ins
