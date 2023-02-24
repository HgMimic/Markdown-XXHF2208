#### MySQL安装

###### 源码包安装

```shell
#安装基础依赖
$ yum -y install cmake bison ncurses-devel
$ tar -zxf ncurses-5.9.tar.gz
$ cd ncurses-5.9
$ ./configure --with-shared --without-debug --without-ada --enable-overwrite
$ make && make install
#cmake命令在mysql的5.5版本之后，取代./configure命令进行编译、安装前的环境检查；
#bison是一个自由软件，用于自动生成语法分析器程序，可用于所有常见的操作系统；
#ncurses 提供字符终端处理库，是使应用程序（如命令终端）直接控制终端屏幕显示的函数库；
#安装ncurses依赖，需要ncurses-devel和ncurses，且ncurses需要安装对应的源码包
#源码安装ncurses选项详解：
#--with-shared    生成共享库
#--without-debug  不生成 debug 库
#--without-ada    不编译为ada绑定，因为进入chroot环境不能便用ada
#--enable-overwrite 参数为定义,指定把头文件安装到/tools/include目录下

#添加mysql用户
$ useradd -s /sbin/nologin mysql

#安装MySQL软件
$ cd mysql-5.5.48
$ cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DMYSQL_USER=mysql -DMYSQL_TCP_PORT=3306
$ make && make install
#选项详解：
#-DCMAKE_INSTALL_PREFIX=/usr/local/mysql	安装位置
#-DMYSQL_UNIX_ADDR=/tmp/mysql.sock			指定socket（套接字）文件位置
#-DEXTRA_CHARSETS=all						扩展字符支持
#-DDEFAULT_CHARSET=utf8    					默认字符集
#-DDEFAULT_COLLATION=utf8_general_ci    	默认字符校对
#-DWITH_MYISAM_STORAGE_ENGINE=1   			安装myisam存储引擎
#-DWITH_INNOBASE_STORAGE_ENGINE=1    		安装innodb存储引擎
#-DWITH_MEMORY_STORAGE_ENGINE=1  			安装memory存储引擎
#-DWITH_READLINE=1    						支持readline库
#-DENABLED_LOCAL_INFILE=1   				启用加载本地数据
#-DMYSQL_USER=mysql  						指定mysql运行用户
#-DMYSQL_TCP_PORT=3306						指定mysql端口

#修改MySQL目录的用户归属
$ cd /usr/local/mysql
$ chown -R mysql data
#生成配置文件
$ cp -a lamp/mysql-5.5.48/support-files/my-medium.cnf /etc/my.cnf
#初始化数据库
$ ./scripts/mysql_install_db --user=mysql

#启动、测试
$ /usr/local/mysql/bin/mysqld_safe --user=mysql &
#设定MySQL密码
$ /usr/local/mysql/bin/mysqladmin -uroot password 123
#登录MySQL
$ /usr/local/mysql/bin/mysql -uroot -p

```

###### rpm包安装

```shell
#安装软件（c7是mariadb和mariadb-server、c6是mysql和mysql-server）
$ yum -y install mariadb-server mariadb
$ systemctl start mariadb
$ systemctl enable mariadb
$ ss -antp | grep :3306
#进入mysql
$ mysql

#查看数据库的版本
$ mysqladmin --version
#更改数据库root的登陆密码
$ mysqladmin -uroot password 新密码
#进入mysql
$ mysql -uroot -p  回车输入密码

```



#### MySQL常用操作

DQL语句、DML语句

```shell
#切换数据库，用测试库进行操作
mysql> use test;
#查看该数据库下所有的数据库表
mysql> show tables;

#创建测试数据
mysql> create table xinxi(
       	id int not null,
       	xuehao varchar(6) not null,
       	name varchar(50) not null,
       	sex int(1) not null default 0,
       	birth date not null default '1999-9-9',
       	address text
       );
mysql> insert into xinxi(id,xuehao,name,address) values(1,'201201','zhao','beijing'),(2,'201202','qian','shanghai'),(3,'201203','sun','guangzhou'),(4,'201204','li',null);

------DQL--------
#查询表中所有列的数据
mysql> select * from 表名;
mysql> SELECT * FROM 表名;
#查询指定列的数据
mysql >select 列名1,列名2,... from 表名;
#查询结果指定别名
mysql> select name as 姓名, xuehao as 学号 from xinxi;
#带条件查询数据
mysql> select 指定列名或* from 表名 where 列名=值;
mysql> select 指定列名或* from 表名 where 列名1=值1 and 列名2=值2;
mysql> select 指定列名或* from 表名 where 列名1=值1 or 列名2=值2;


#查询数据的记录数
mysql> select count(*) from xinxi;
#获取结果的前几条，结果中的取值范围(n,n+m]，从第n行开始向后取m行
mysql> select * from xinxi limit 4;
mysql> select * from xinxi limit 2,4;
#where结合in、not in，同时查询指定的多条数据  -批量处理
mysql> select * from xinxi where id in(2,4);
mysql> select * from xinxi where id not in(2,4);
mysql> select * from xinxi where xuehao in('201201','201204');
#where结合between，查询指定范围的数据[2,4]
mysql> select * from xinxi where id between 2 and 4;
mysql> select * from xinxi where id not between 2 and 4;
#where查询某些字段不是null的情况
mysql> select * from xinxi where name is not null;
mysql> select * from xinxi where name is null;

#where结合like，使用通配符进行匹配查询；默认完全匹配
#常用通配符：_是代表一个字符、%是代表一个或多个字符
mysql> select * from xinxi where name like 's';
mysql> select * from xinxi where name like 's_';
mysql> select * from xinxi where name like 's__';
mysql> select * from xinxi where name like 's%';


#查询后的结果排序、默认升序排列（asc、desc）
#若排序列是数值类型，则按数字大小排序；若排序列是字符类型，则按ASCII顺序
mysql> select * from xinxi order by name;
mysql> select * from xinxi order by name asc;
mysql> select * from xinxi order by name desc;
mysql> select * from xinxi order by id desc;
mysql> select * from xinxi order by address asc, id desc;



------DML------
#查看数据库表的表结构
mysql> desc 表名;
#查看表数据
mysql> select * from xinxi;

#插入一条数据,默认给所有字段插入数据
语法：insert into 表名 values(值1,值2...);
mysql> insert into xinxi values(111,'201212','jimmy',1,'2000-7-7','hengshui');
#插入一条数据,只给必要字段插入数据【字段约束：非空约束、默认值约束】
语法：insert into 表名(字段1，字段2,...) values(值1，值2,...);
mysql> insert into xinxi(xuehao,name) values('201213','john');
#插入多条数据
mysql> insert into xinxi(xuehao,name,sex,birth) values('201220','john',0,'2011-4-23'),('201221','zhuli',1,'2013-5-28'),('201222','zhangbomeng',1,'1988-3-7');

#修改所有行的数据记录
语法：update 表名 set 字段名=值;
mysql> update xinxi set birth='1980-6-7';
#修改指定条件的数据记录
语法：update 表名 set 字段名=值 where 指定字段=指定值;
mysql> update xinxi set sex=1 where name='zhao';
mysql> update xinxi set address='dongbei' where address is null;

#删除所有记录
语法：delete from 表名;
mysql> delete from xinxi;
#删除指定记录
语法：delete from 表名 where 指定字段=指定值;
mysql> delete from xinxi where name='jimmy';


---------支持中文-----
#查看表的创建信息
mysql> show create table 表名;

#方法一：创建表时指定字符集
mysql> create table tzhong(
 id int,
 name varchar(20),
 sex int)DEFAULT CHARSET=utf8;
mysql> show create table tzhong;
mysql> insert into tzhong values(1,'哈哈哈',0);
mysql> select * from tzhong;

#方法二：修改配置文件
$ vim /etc/my.cnf
	[mysqld]
	character-set-server=utf8
$ systemctl stop mariadb
$ systemctl start mariadb

$ mysql
mysql> use test;
mysql> create table tzhong1(
id int,
name varchar(20)
);
mysql> show create table tzhong1;
mysql> insert into tzhong1 values(1,'哈哈哈');
mysql> select * from tzhong1;

```



DDL语句

```shell
------数据库操作------
#查看数据库
mysql> show databases;
#创建数据库
mysql> create database 数据库名；
#切换数据库
mysql> use 数据库名；
#删除数据库
mysql> drop database 数据库名；


------数据表操作------
#创建数据库表语法
语法:create   table  表名(
	字段1   数据类型  非空约束   默认值约束, 
	字段2   数据类型  非空约束   默认值约束, 
	 …
    字段n   数据类型  非空约束   默认值约束
   ); 
mysql> create table t1 ( 
	xingming varchar(20), 
	xingbie int(1), 
	xuehao int, 
	birth datetime 
	);
#查看表结构
mysql> desc t1;
#插入数据
mysql> insert into t1 values('jimmy', 0, 2102001, '2020-9-3');
mysql> insert into t1 values('jimmy', 0, 2102001, null);
mysql> insert into t1 values('jimmy', 0, null, null);
mysql> insert into t1(xingming) values('jimmy');
mysql> insert into t1 values('jimmy', null, null, null)
mysql> insert into t1 values('null', null, null, null);
mysql> select * from t1;
#删除数据表
mysql> drop table t1;

#表内数据的域完整性：数据类型 非空约束(not null)、默认值约束(default)
#非空约束不设、默认是yes即可空；默认值约束不设、默认是null即空值。
mysql> create table t2 (  
	xingming varchar(20) not null,  
	xingbie int(1) not null,  
	xuehao int not null,  
	birth datetime  
	);
mysql> desc t2;
mysql> insert into t2 values('jimmy', 0, 2102001, '2020-9-3');
mysql> insert into t2 values('jimmy', 0, 2102001, null);
mysql> insert into t2(xingming,xingbie,xuehao) values('jimmy', 0,2102001);

#表内数据的实体（记录、行）完整性：主键约束(primary key)、唯一约束(uniqe key)、自动增长列(auto_increment)
#给某列设置自增时，该列必须是主键
mysql> create table t3 (  
	xingming varchar(20) not null,  
	xingbie int(1) not null default 0,  
	xuehao int not null,  
	birth datetime  
	);
mysql> desc t3;
mysql> insert into t3 values('jimmy', 0, 2102001, '2020-9-3');
mysql> insert into t3 values('jimmy', 0, 2102001, null);
mysql> insert into t3(xingming,xuehao) values('jimmy', 2102001);

-----
#表结构修改
mysql> create table t11(
 id int,
 name varchar(20),
 sex int);
#修改表名：把表名t1修改为xinxi
语法：alter table 旧表名 rename 新表名;
mysql> alter table t11 rename xinxi;
#增加列：给xinxi表添加出生日期birth列
语法：alter table 表名 add 列名 数据类型 [约束 默认值];
mysql> alter table xinxi add birth datetime; （添加到最后位置）
mysql> alter table xinxi add date year first; （添加到第一个字段）
mysql> alter table xinxi add date year after age; （添加到指定字段后面）
#删除列：删除xinix表中的birth列
语法：alter table 表名 drop 列名；
mysql> alter table xinxi drop birth;
#修改列名：把xinxi表里的id改成xuehao
语法：alter table 表名 change 旧列名 新列名 数据类型 [约束 默认值];
mysql> alter table xinxi change id xuehao int not null;
#修改列的类型：把xinxi表里的sex列限制1位长度、name列设为为空
语法：alter table 表名 modify 列名 数据类型 [约束 默认值];
mysql> alter table xinxi modify sex int(1);
mysql> alter table xinxi modify name varchar(20) not null;
----------------------------------------

#表内数据的实体（记录、行）完整性：主键约束(primary key)、唯一约束(uniqe key)、自动增长列(auto_increment)
#给某列设置自增时，该列必须是主键
#查看约束信息
mysql> desc xinxi;

------主键---
#添加约束：添加xuehao主键
语法：alter table 表名 add primary key(字段名);
mysql> alter table xinxi add primary key(xuehao); 
#删除主键约束：
语法：alter table 表名 drop primary key;
mysql> alter table xinxi drop primary key;

#创建数据表时指定实体约束，建表时指定主键
mysql> create table t5 ( 
	id int primary key, 
	name varchar(20)  , 
	birth datetime, 
	work year
	);
mysql> create table t4 ( 
	id int, 
	name varchar(20), 
	birth datetime, 
	work year , 
	primary key(id)
	);
	
------唯一键---	
#创建唯一键约束，一张表可以有多个唯一键、唯一键可以建在一列多列上
#查看表的约束情况
mysql> show keys|index from xinxi;
#添加约束：添加name唯一键
语法：alter table 表名 add unique key(字段名);
mysql> alter table xinxi add unique key(name);
#删除唯一键约束，需要用约束名来删除
语法：alter table 表名 drop index 索引名;
语法：drop index 约束名 on 表名;
mysql> drop index name on xinxi;

#索引：类似书的目录，提高数据查询的速度；存取结构受存储引擎影响
mysql> create index 索引名 on xinxi(xuehao);
mysql> show index|indexes|keys from xinxi;
mysql> drop index 索引名 on xinxi;


约束：
1.约束是用于限制加入表的数据；可以在创建表的时候规则约束、也可以在建完表后进行调整。
2.常见约束：
  域约束：非空（not null）、默认值（default）
  实体约束：主键、唯一键
  表间约束：外键

```



DCL语句

```shell
#数据库连接
语法1：mysql -u用户名  -p密码 -P端口  -h主机 
语法2：mysql -u用户名  -p密码  -S(大) 套接字
#本机连接
$ mysql
$ mysqladmin -u用户名 password 密码值
$ mysql -u用户名 -p密码
#可以登录的用户存储在数据库mysql中的user表中
mysql> use mysql
mysql> select  user,host  from  user; 

#创建远程连接用户
mysql> create user '用户名'@'登录地址' identified by '用户密码';
#新用户登录、默认只拥有test数据库权限
$ mysql -h服务器IP  -P端口 -u用户名 -p密码
#删除用户
mysql> drop user '用户名'@'登录地址';

-----------------------------
#数据库授权
$ mysql -uroot -p密码
#给存在的用户授权
mysql> grant all (privileges) on 数据库名.数据库表 to '用户名'@'登录地址';
#查看用户的授权情况
mysql> show grants for '用户名'@'登录地址';
#创建新用户的同时直接授权
mysql> grant all on 数据库名.数据库表 to '用户名'@'登录地址' identified by '用户密码';
#取消授权
mysql> revoke all on 数据库名.数据库表 from '用户名'@'登录地址';

all (privileges)：授权服务器的所有权限
select：授权读取行的权限
insert：授权插入行的权限
update：授权更新行的权限
delete：授权删除行的权限
create：授权创建数据库、表、视图的权限
alter：授权修改表结构的权限
drop：授权删除数据库、表、视图的权限
replication slave：授权主从复制权限
replication client：授权查看主|从|二进制日志状态的权限
execute:授权执行存储过程的权限
create view、show view、trigger等

```



高级语法

```shell
-----------------外键-----
#多表级联
#准备数据表xinxi、paihangbang，及若干数据
mysql> create table  xinxi(
 id int auto_increment,
 name varchar(20) not null,
 sex int(1) not null default 0,
 birth datetime,
 primary key(id)
 );   
mysql> alter table xinxi add unique key(name);
mysql> insert into xinxi(name,sex,birth) values('xiaozhan',0,'1990-1-1'),('luhan',0,'1990-4-20'),('liying',1,'1988-1-1'),('baby',1,'1989-1-1');

mysql> create table paihangbang(
 id int not null, 
 score int, 
 rank int, 
 name varchar(20) 
 );
mysql> insert into paihangbang values(1,100,1,'xiaozhan'),(2,98,2,'luhan'),(3,97,3,'tangyan'),(4,96,4,'liying');

#用共有的字段连接两张表,inner join两边都有记录、left join以主表记录为准、right join以副表记录为准
语法：select * from 主表名 inner|left|right join 副表名 on 主表.字段=副表.字段;
mysql> select * from xinxi inner join paihangbang on xinxi.name=paihangbang.name;
mysql> select * from xinxi left join paihangbang on xinxi.name=paihangbang.name;
mysql> select * from xinxi right join paihangbang on xinxi.name=paihangbang.name;

#外键约束，参照完整性，用来在两个表的数据之间建立连接；
#一张表可以设置多个外键，一个外键可以加载单列或多列上；
#外键是表中的一个字段、不一定是本表的主键，但需要对应另一个表的唯一键；
#外键定义后，不允许删除另一个表中有关联的行；
#关联的两张表的字段类型、字符集需要相同；
语法：ALTER TABLE <数据表名> ADD CONSTRAINT <索引名>
FOREIGN KEY(<列名>) REFERENCES <主表名> (<列名>);

级联关系：
#想删除主表的字段，需要把该字段上关联的外键先删除；
#想添加从表的字段，需要在主表的数据范围里面

#查看外键
mysql> show create table 表名;
#删除外键
语法：ALTER TABLE <表名> DROP FOREIGN KEY <外键约束名>;  #删约束
语法：drop index 约束名 on 表名; #删外键索引

----------------视图---------
#视图：将查询结果集的sql语句封装成一张可视化的表，动态SQL语句、根据数据表的数据而更新
语法：create view 视图名 as 查询语句;
mysql> create view get_by_id_view as select * from xinxi order by id desc;
mysql> select * from get_by_id_view;
mysql> alter view get_by_id_view as select * from xinxi;
mysql> drop view get_by_id_view;
#查看视图
mysql> use 数据库名 
mysql> show create view 视图名;

--------------存储过程-------------
#存储过程(stored procedure)：是将一组SQL语句作为一个整体来执行的数据库对象，通过被调用来运行；
#和函数一样，是一条或多条SQL语句的集合，区别函数是已经定义好的、存储过程是用户自己定义的；

#调用函数
mysql> select count(*) from 表名;
mysql> select avg(列名) from 表名 ;
#avg()获取平均值、min()获取最小值、max()获取最大值、sum()求和等 

#--是注释
#将语句的结束符号从分号;临时改为两个$$(可以是自定义)
mysql> delimiter $$   
#定义存储过程
mysql> create procedure delete_data()
      begin       #开启事务
      	delete from xinxi;  #要执行的语句1
      	delete from t11;    #要执行的语句2
      end $$      #结束事务
#调用存储过程
mysql> call delete_data;
#将语句的结束符号改回;
mysql> delimiter ;

#查看所有存储过程
mysql> show procedure status;
#查看存储过程内容
mysql> show create procedure delete_data;
#删除存储过程
mysql> drop procedure delete_data;


#事务的特点、事务的隔离级别
#查看mysql的隔离级别
mysql> show variables like 'tx_isolation';
或：mysql> select @@tx_isolation;
Variable_name | Value           |
+---------------+-----------------+
| tx_isolation  | REPEATABLE-READ

#修改默认存储引擎
$ vim /etc/my.cnf
	[mysqld]
	default-storage-engine=INNODB
	
```



#### MySQL运维操作

```shell
1.修改数据库的登录密码
#设置初始密码
$ mysqladmin -u用户名 password 密码

#更改自己的密码，所有用户都可以使用
$ mysqladmin -u用户名 -p, 回车输入密码
mysql> set password = password('密码');

#管理员root修改其他用户的登录密码（localhost、root=mysql数据库中管理员）
mysql> set password for '用户名'@'登录地址'=password("密码");

#更改数据记录
mysql> update user set password=password('新密码') where User='用户名' and Host='登录地址';  
mysql> flush privileges;  #或重启服务
-------------------------------

2.忘记数据库的登录密码
$ vim /etc/my.cnf
	#mysql默认启动区域
	[mysqld] 
    #添加跳过权限表验证
	skip-grant-table  
    
	#mysql安全启动区域，增加了一些安全特性，如发现错误时重启服务、将运行时间写入错误日志文件
	#以后使用的趋势，兼容过去的mysqld，也会读取mysqld的配置
	[mysqld_safe] 
	
#启动mysql服务
#rpm包的mysql重启服务，默认使用的是安全启动
$ systemctl restart mariadb
$ ss -antp | grep :3306
#直接无密码进入mysql即可
$ mysql    

#数据库重设密码
mysql> update user set password=password('新密码') where User='用户名' and Host='登录地址';    
#退出数据库，把配置文件添加的行去掉，重启数据库即可
$ vim /etc/my.cnf
	#去掉skip-grant-table
$ systemctl restart mariadb

---------------------------------

3.数据库备份
#复制数据文件
$ cp -a /usr/local/mysql/data  备份目录
$ cp -a /var/lib/mysql  备份目录

#mysqldump命令备份、mysql还原
#备份一个数据库，touch 44_$(date +"%y-%m-%d").txt
$ mysqldump -u用户名 -p密码 要备份的数据库名 > 文件名.sql
#备份一个数据库表
$ mysqldump -u用户名 -p密码 要备份的数据库名 表名 > 文件名.sql
#备份多个数据库
$ mysqldump -u用户名 -p密码 --databases 数据库名1 数据库名2 > 文件名.sql
#备份所有数据库
$ mysqldump -u用户名 -p密码 --all-databases > 文件名.sql

#还原，注意恢复备份的是一个数据库的时候需要手动创建数据库、再指定还原
$ mysql -u用户名 -p密码 要还原到的数据库名 < 文件名.sql
#还原多个数据库
$ mysql -u用户名 -p密码 < 文件名.sql

#其他选项参数：
$ mysqldump -help
#-A(--all-databases)、-B(--databases)、-d(--no-data)、-t(--no-create-info)


#二进制日志文件备份、恢复数据
mysql> show variables like '%log%';

#开启二进制日志配置、产生二进制日志
$ vim /etc/my.cnf
	log-bin=mysql-bin
$ systemctl restart mariadb
#查看二进制日志、恢复数据
$ cd /var/lib/mysql/
#查看二进制日志文件
$ mysqlbinlog mysql-bin.000001

mysql> show binlog events in '二进制文件名';
#指定二进制事件的起止位置进行数据恢复
$ mysqlbinlog --start-position 421 --stop-position 612
mysql-bin.000001 | mysql -uroot -p 123

```



####  MySQL集群搭建

##### MySQL主从（从）搭建

###### 主服务器

```shell
#安装mysql、启动服务
$ yum -y install mariadb mariadb-server
#配置主配置文件：打开二进制日志、设置id值
$ vim /etc/my.cnf
	log-bin=mysql-bin
	server-id=1
$ systemctl restart mariadb
$ mysqladmin -uroot password 123

#创建用于同步的用户、并授权
$ mysql -uroot -p123
mysql> grant all on *.* to 'rsyncer'@'%' identified by '123';
#查看当前服务器的日志文件及偏移量
mysql> show master status;

```

###### 从服务器

```shell
#安装mysql、启动服务
$ yum -y install mariadb mariadb-server
#配置主配置文件：设置id值
$ vim /etc/my.cnf
	server-id=2
$ systemctl restart mariadb
$ mysqladmin -uroot password 123

#设置同步
$ mysql -uroot -p123
mysql> change master to master_host='主服务器IP',master_user='用户',master_password='用户密码',master_log_file='二进制文件',master_log_pos=偏移量;

 change master to master_host='192.168.66.24',master_user='tongbu',master_password='123',master_log_file='mysql-bin.000004',master_log_pos=775;

#开启同步
mysql> start slave;

#查看同步状态
mysql> show slave status\G;

#关闭同步，重新做change master to需要先关掉slave；
mysql> stop slave;

结果注：
1.若IO线程是no，则change master to出了问题；
2.若sql线程是no，则同步的数据出了问题；
```

###### 测试

```shell
打开salve同步时,在主服务器内创建数据库、插入数据，在从服务器上可以查询到；
关闭slave后，在主服务器上的操作，在从服务器查询不到，两个服务器数据不一致；
```

———————————————————————————

##### MySQL主主搭建

###### 主1服务器

```shell
#安装mysql、启动服务
$ yum -y install mariadb mariadb-server
#配置主配置文件：打开二进制日志、设置id值
$ vim /etc/my.cnf
	log-bin=mysql-bin
	server-id=11
	
	#设置同步参数
	#设置要同步的数据库，如果是主从，在从的一方写
	replicate-do-db=test  
	#忽略、不同步的数据库(数据库名后不要有空格)
	replicate-ignore-db=mysql
	replicate-ignore-db=information_schema 

	
	 #主键的每次增长值、初始值
	auto-increment-increment=2
	auto-increment-offset=1 
$ systemctl restart mariadb
$ mysqladmin -uroot password 123

#创建用于同步的用户、并授权
$ mysql -uroot -p123
mysql> grant all on *.* to 'rsyncer1'@'%' identified by '123';
#查看当前服务器的日志文件及偏移量
mysql> show master status;

#作为主2服务器的从服务器
mysql> change master to master_host='主2服务器IP',master_user='rsyncer2',master_password='123',master_log_file='二进制文件',master_log_pos=偏移量;

mysql> start slave;
mysql> show slave status\G;

```

###### 主2服务器

```shell
#安装mysql、启动服务
$ yum -y install mariadb mariadb-server
#配置主配置文件：打开二进制日志、设置id值
$ vim /etc/my.cnf
	log-bin=mysql-bin
	server-id=12
	
	#设置同步参数,从主的二进制日志中拿到从的中继日志的时候
	#设置要同步的数据库
	replicate-do-db=test  
	#忽略、不同步的数据库 
	replicate-ignore-db=mysql 
	replicate-ignore-db=information_schema 
	
	 #主键的每次增长值、初始值
	auto-increment-increment=2
	auto-increment-offset=2
$ systemctl restart mariadb
$ mysqladmin -uroot password 123

#创建用于同步的用户、并授权
$ mysql -uroot -p123
mysql> grant all on *.* to 'rsyncer2'@'%' identified by '123';
#查看当前服务器的日志文件及偏移量
mysql> show master status;

#作为主1服务器的从服务器
mysql> change master to master_host='主1服务器IP',master_user='rsyncer1',master_password='123',master_log_file='二进制文件',master_log_pos=偏移量;
mysql> start slave;
mysql> show slave status\G;

```

###### 测试

```shell
在两个服务器的任何一边进行操作，都会同步到对方；
```

————————————————————————

##### MySQL读写分离

###### 主服务器

```shell
#安装mysql、启动服务
$ yum -y install mariadb mariadb-server
#配置主配置文件：打开二进制日志、设置id值
$ vim /etc/my.cnf
	log-bin=mysql-bin
	server-id=1
$ systemctl restart mariadb
$ mysqladmin -uroot password 123

#创建用于同步的用户、并授权
$ mysql -uroot -p123
mysql> grant all on *.* to 'rsyncer'@'%' identified by '123';

#查看当前服务器的日志文件及偏移量
mysql> show master status;
```

###### 从服务器

```shell
#安装mysql、启动服务
$ yum -y install mariadb mariadb-server
#配置主配置文件：打开二进制日志、设置id值
$ vim /etc/my.cnf
	log-bin=mysql-bin
	server-id=2
$ systemctl restart mariadb
$ mysqladmin -uroot password 123

#设置同步
$ mysql -uroot -p123
mysql> change master to master_host='主服务器IP',master_user='用户',master_password='用户密码',master_log_file='二进制文件',master_log_pos=偏移量;

change master to master_host='192.168.66.24',master_user='ll',master_password='123',master_log_file='mariadb-bin.000001',master_log_pos=245;

#开启同步
mysql> start slave;

#查看同步状态
mysql> show slave status\G;

```

###### 搭建中间Amoeba

```shell
#安装jdk，因为Amoeba是java语言写的,运行时一定需要JAVA_HOME的环境变量
$ java -version
#安装jdk指定版本、覆盖系统默认安装的
$ tar -zxf jdk-11.0.11_linux-x64_bin.tar.gz 
$ cp -a jdk-11.0.11 /usr/local/jdk11
#配置环境变量,注意默认安装的jdk在/usr/bin下
$ vim /etc/profile      
	export JAVA_HOME=/usr/local/jdk11 
	export JAVA_BIN=$JAVA_HOME/bin 
	export PATH=$JAVA_BIN:$PATH 
#让配置文件生效
$ source /etc/profile
#测试java环境，查看版本
$ java -version    

#安装Amoba
$ mkdir /usr/local/amoeba
$ unzip amoeba-mysql-1.3.1-BETA.zip -d /usr/local/amoeba/
$ cd /usr/local/amoeba

#修改bin下的amoeba的DEFAULT_OPTS，支持64位
$ vim bin/amoeba
	#DEFAULT_OPTS="-server -Xms256m -Xmx256m -Xss128k"
	DEFAULT_OPTS="-server -Xms256m -Xmx256m -Xss256k"
#修改conf配置文件amoeba.xml，配置各服务

$ vim conf/amoeba.xml
	#配置上层调用amoeba的配置
	<server>
		<property name="port">8066</property>
		<property name="ipAddress">192.168.66.13</property>
		<property name="user">root</property>
		<property name="password">123</property>
	</server>
	#配置进程信息
	 <connectionManagerList>
        <connectionManager name="defaultManager" class="com.meidusa.amoeba.net.MultiConnectionManagerWrapper">
         	<property name="subManagerClassName">com.meidusa.amoeba.net.AuthingableConnectionManager</property>
         	#取消下行注释
            <property name="processors">5</property>
         </connectionManager>
     </connectionManagerList>

	#配置mysql服务器（ip地址、连接用户）
	<dbServerList>
        <dbserver name="server1">
			<property name="port">3306</property>
			<property name="ipAddress">192.168.66.22</property>
			<property name="schema">test</property>
			<property name="user">amoeba</property>
			<property name="password">123</property>
        </dbserver>
        <dbserver name="server2">
			<property name="port">3306</property>
			<property name="ipAddress">192.168.66.23</property>
			<property name="schema">test</property>
			<property name="user">amoeba</property>
			<property name="password">123</property>
        </dbserver>

        #分配mysql服务的负载情况(有多个读时需设置)
        <dbserver name="master" virtual="true">
			<poolConfig class="">
				<property name="loadbalance">1</property>
				<property name="poolNames">server1</property>
			</poolConfig>
        </dbserver>
        <dbserver name="slave" virtual="true">
			<poolConfig class="">
				<!-- Load balancing strategy: 1=ROUNDROBIN , 2=WEIGHTBASED , 3=HA-->  
				<property name="loadbalance">1</property>
				<property name="poolNames">server2</property>
			</poolConfig>
        </dbserver>
	<dbServerList>
	#分配默认池、读写池
	<queryRouter class="">
		<property name="defaultPool">master</property>
        <property name="writePool">master</property>
        <property name="readPool">slave</property>
	</queryRouter>
	
#保存配置文件，启动amoeba
#方法一：脱离终端的后台运行，日志会输出在当前目录下的nohup.out文件里
$ nohup bash -x /usr/local/amoeba/bin/amoeba &
#方法二：chmod运行，会把部分输出日志打在控制台上
$ chmod +x /usr/local/amoeba/bin/amoeba 
$ /usr/local/amoeba/bin/amoeba start &

#关闭amoeba
$ kill amoeba的进程号

其中，nohup是不挂起的意思
含义：该命令会在你退出账号或关闭终端后仍继续运行相应的进程；
格式：nohup command &
结果：会把命令日志输出到当前目录的nohup.out文件里

```

###### 测试

```shell
#安装mysql客户端
1.连接中间件（-h192.168.66.13 -P6088 -uroot -p123）
2.进行读写操作、查看结果
3.关掉slave同步，再进行读写操作、查看结果

```

