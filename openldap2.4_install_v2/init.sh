#!/bin/bash
ROOT=`pwd` 
dbpack=$ROOT/pack/db-4.8.30.tar.gz
ldappack=$ROOT/pack/openldap-2.4.24.tgz
build=$ROOT/build

datef(){ date "+%Y/%m/%d %H:%M" ; }

installdb()
{
 if [[ -f $build/install_BerkeleyDB.4.8_done.tag ]];then
          echo "[$(datef)] installdb(): BerkeleyDB.4.8 installed, skin!"
          exit      
   fi
tar -zxf $dbpack -C $build
cd $ROOT/build/db-4.8.30/build_unix
../dist/configure
make && make install

echo "/usr/local/BerkeleyDB.4.8/lib"  >> /etc/ld.so.conf.d/BerkeleyDB-4.8.30.conf
/sbin/ldconfig
touch $build/install_BerkeleyDB.4.8_done.tag

}

installldap()
{
 if [[ -f $build/install_openldap-2.4.24_done.tag ]];then
          echo "[$(datef)] installldap(): openldap-2.4.24 installed, skin!"
          exit  
   fi
tar -zxvf $ldappack -C $build
cd $build/openldap-2.4.24
export CPPFLAGS="-I/usr/local/BerkeleyDB.4.8/include/"
export LDFLAGS="-L/usr/local/lib -L/usr/local/BerkeleyDB.4.8/lib -R/usr/local/BerkeleyDB.4.8/lib"
export LD_LIBRARY_PATH="/usr/local/BerkeleyDB.4.8/lib"

./configure --prefix=/usr/local/openldap-2.4.24 --enable-accesslog --enable-auditlog --with-threads
make depend
make
make install
[[ -d /data/openldapdb ]] || mkdir /data/openldapdb
\cp /usr/local/openldap-2.4.24/etc/openldap/DB_CONFIG.example /data/openldapdb/DB_CONFIG
\cp $ROOT/pack/slapd.conf /usr/local/openldap-2.4.24/etc/openldap/
\cp $ROOT/pack/openldap /etc/init.d/
touch $build/install_openldap-2.4.24_done.tag
}
post_int(){

        echo "**************** Begin post init *********************"
        if ! grep "^ldap" /etc/passwd
        then
                groupadd ldap
                useradd -g ldap -s /bin/false ldap
        fi
        [[ -d /usr/local/openldap-2.4.24 ]] && chown -R ldap:ldap /usr/local/openldap-2.4.24
	[[ -d /usr/local/var/run ]] || mkdir /usr/local/var/run && chmod 777 /usr/local/var/run
	[[ -d /data/openldapdb ]] && chown -R ldap:ldap /data/openldapdb
	[[ -d /data/log/ldap  ]] || mkdir -p /data/log/ldap && chown ldap.ldap /data/log/ldap -R
	echo "local4.*                                                /data/log/ldap/ldap.log"  >>  /etc/rsyslog.conf 
	/etc/init.d/rsyslog   restart
	chmod 755 /etc/init.d/openldap
        echo "*************** End post init ************************"
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
#echo "Starting install BerkeleyDB"
#installdb
#echo "Starting install Openldap"
#installldap
#echo "Starting post_int"
#post_int
echo "Starting finish_ins"
finish_ins
