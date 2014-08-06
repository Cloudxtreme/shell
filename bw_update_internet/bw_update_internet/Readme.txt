本脚本用于自动发布保网WEB应用，操作说明如下：
1.使用Rsync进行文件的同步,目录结构如下：
# tree /data/update/
/data/update/		-->发布主目录
|-- carimage		-->车型库图片文件RSYNC共享目录
|-- conf -> /data/update/update/package/conf/  -->配置文件RSYNC共享目录
|-- dsl			-->DSL文件RSYNC共享目录
|-- html		-->WEB页面RSYNC共享目录
|-- image		-->静态页面RSYNC共享目录
|-- mongodb		-->MONGODB数据库RSYNC共享目录
|-- mysql -> /data/update/update/package/sql/	-->Mysql SQL文件RSYNC共享目录
`-- update		-->脚本、配置文件、软件包文件存放入口
    |-- conf		-->脚本实际读取的配置文件存放目录
    |   |-- carimage.conf	-->定义更新车型库图片文件的服务器IP、图片的存放目录、备份目录
    |   |-- conf.txt		-->定义更新配置文件或单个文件的服务器IP、配置文件的存放目录、备份目录
    |   |-- dsl.conf		-->定义更新DSL文件的服务器IP、DSL文件的存放目录、备份目录
    |   |-- image.conf		-->定义更新静态图片文件的服务器IP、图片文件的存放目录、备份目录
    |   |-- mongodb.conf	-->定义更新MONGODB的服务器IP、库名、将导入的目录库名
    |   |-- mysql.conf		-->定义更新MYSQL的服务器IP、库名、用户名、密码、SQL文件
    |   |-- resin.conf		-->定义更新WEB数据的服务器IP、WEB存放目录、备份目录
    |   `-- rsync.conf		-->定义RSYNC的共享目录参数
    |-- keys		-->存放SSH私钥的目录
    |   `-- id_rsa
    |-- log		-->日志文件存放目录
    |   |-- carimage-20120512-122949.log
    |   |-- conf-20120512-125009.log
    |   |-- conf-20120512-175739.log
    |   |-- dsl-20120512-122730.log
    |   |-- image-20120512-121854.log
    |   |-- image-20120512-173806.log
    |   |-- image-20120512-174108.log
    |   |-- image-20120512-174124.log
    |   |-- image-20120512-174450.log
    |   |-- mongodb-20120512-130158.log
    |   `-- mysql-20120512-125817.log
    |-- package		-->存放需要更新的WAR包、静态图片或CARIMAGE文件压缩包、DSL文件压缩包、配置文件或其他文件、mongodb目录库压缩包、MYSQL的SQL文件
    |   |-- carimage
    |   |-- conf
    |   |-- dsl
    |   |-- image
    |   |-- mongodb
	|-- war
    |   `-- sql
    |-- template	-->脚本使用的配置文件模板，脚本执行时拷贝文件到conf目录，然后读取conf目录的配置文件
    |   |-- b2c_carimage.conf
    |   |-- b2c_conf.txt
    |   |-- b2c_dsl.conf
    |   |-- b2c_image.conf
    |   |-- b2c_mongodb.conf
    |   |-- b2c_mysql.conf
    |   |-- b2c_resin.conf
    |   `-- rsync.conf
    `-- update.sh	-->更新脚本

2.RSYNC配置文件
# cat /etc/rsyncd.conf 
port = 873
pid file = /var/run/rsyncd.pid
use chroot = yes
uid = www
gid = www
[mysql]
path = /data/update/mysql
read only = yes

[html]
path = /data/update/html
read only = yes

[image]
path = /data/update/image
read only = yes

[conf]
path = /data/update/conf
read only = yes

[carimage]
path = /data/update/carimage
read only = yes

[dsl]
path = /data/update/dsl
read only = yes

[mongodb]
path = /data/update/mongodb
read only = yes

3.约定
3.1 数据打包约定
	CARIMAGE文件、DSL文件、Mongodb目录库文件使用tar工具进行打包；
	carimage:
	cd /data/www/html/carImage
	tar -czvf carimage-20120511.tar.gz *

	DSL:
	cd /data/www/ins_share/DSLRoot
	tar -czvf dsl-20120511.tar.gz *

	Mongodb:
	/usr/local/mongodb/bin/mongodump -d insure -o /data/0416	
	cd /data/0416
	tar -czvf mongodb-20120511.tar.gz *

3.2 SSH私钥
	私钥文件名称为id_rsa，使用其他名字需要修改脚本；
	进行授权chmod 600 id_rsa
	使用后请删除key文件：rm ./keys/id_rsa
	运行脚本之前先使用私钥进行登录测试是否可以登录远程服务器，然后再执行脚本；
	ssh -i ./keys/id_rsa qiuyuxian@192.168.100.100

3.3 运行脚本
	./update.sh 业务平台  更新应用
	如：
	./update.sh b2c_com|b2c_admin|cx|t|ssogo|b2c_zw resin|image|dsl|carimage|mysql|mongodb|conf|all
	
	b2c_com：更新www.baoxian.com站点
	b2c_admin：更新admin.baoxian.com站点
	b2c_zw：更新zw.baoxian.com站点
	t：更新t.baoxian.com站点
	cx：更新cx.baoxian.com站点
	ssogo：更新ssogo.baoxian.com站点
	
	resin：更新相应站点的WEB程序
	image：更新相应站点的静态图片文件
	dsl：更新相应站点的DSL文件
	carimage：更新相应站点的carimage文件
	mysql：更新相应站点的Mysql
	mongodb：更新相应站点的Mongodb
	conf：更新相应站点的配置文件或其他文件
	all:同时更新相应站点的WEB程序和静态图片文件
