#更新内容
1.增加初始化脚本，初始化默认安装 短信报警功能,mydumper,xtrabackupex,可以自定义安装。
2.完善报警功能,备份操作/远程同步/判断等可能出错的地方添加自定义报警。(原来b2b备份只开启了rsync失败判断动作)
3.增加一键开启或关闭报警功能。
4.添加mysql 三种备份方式（mysqldumper,mydumper,innobackupex）自定义选择，一键开启。
5.添加和完善xtrabackup2种备份方式选择，完整备份和完备+增量备份方式，缺省周一完备，周二至周日增量备份。
6.xtrabackupex备份缺省备份整库的内容，不对单库进行备份。但会对库进行判断,如果数据库不存在，则会退出备份。
7.增加对binlog文件的备份.
8.增加imexport.sh备份恢复脚本，添加备份恢复统计耗时。
9.如果是针对mysql slave机器用xtrabackup备份时先要把脚本关于--slave-info的注释打开.
10.针对xtrabackup备份方式添加对备份空间的判断。
