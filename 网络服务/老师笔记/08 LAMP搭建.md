#### 准备工作

```shell
#1.关闭SELinux和iptables
#2.配置yum源
#3.安装编译环境
$ yum -y install gcc gcc-c++ make
#4.拷贝源码包进虚拟机
#5.关闭系统默认安装的相关rpm包
```

#### 安装apache 

```bash
#安装基础依赖
$ yum -y install openssl openssl-devel zlib zlib-devel pcre pcre-devel

#解压源码包并解决依赖关系
$ tar -zxf  httpd-2.4.47.tar.gz 
$ tar -zxf  apr-1.4.6.tar.gz 
$ tar -zxf  apr-util-1.4.1.tar.gz 

#解决依赖关系
$ cp -a  apr-1.4.6       httpd-2.4.47/srclib/apr
$ cp -a  apr-util-1.4.1  httpd-2.4.47/srclib/apr-util

#安装支持http2协议的，
#需要nghttp2依赖；需要httpd版本在2.4.17以上;需要openssl在1.0.2及以上
$ cd lamp软件包存放目录
$ yum -y install libnghttp2-1.33.0-1.1.el7.x86_64.rpm
$ yum -y install libnghttp2-devel-1.33.0-1.1.el7.x86_64.rpm

#编译、安装，每步执行完用echo $?检测
#--prefix:指定安装路径, 
#enable-rewrite:开启地址重写, 
#enable-so:开启dso(动态共享对象), 
#enable-headers:允许修改http的请求头, 
#enable-expires:允许客户端缓存, 
#enable-modules=most:尽可能安装更多模块, 
#enable-deflate:开启对压缩的支持, 
#enable-ssl:开启https的支持
$ cd httpd-2.4.47
$ ./configure --prefix=/usr/local/apache2  --enable-rewrite --enable-so --enable-headers --enable-expires  --enable-modules=most --enable-deflate --enable-ssl --enable-http2 
$ make && make install

#检测配置文件、启停服务
$ /usr/local/apache2/bin/apachectl -t
$ /usr/local/apache2/bin/apachectl  stop
$ /usr/local/apache2/bin/apachectl  start

#查看服务启动情况
$ ss -antp | grep :80  #查看apache是否启动成功
$ ps -aux | grep httpd #查看是否产生进程

---------------------------
#客户端浏览器访问：
网页路径中输入：服务器IP地址

```



#### 安装MySQL

```shell
#安装基础依赖
$ yum -y install cmake bison ncurses-devel
$ tar -zxf ncurses-5.9.tar.gz
$ cd ncurses-5.9
$ ./configure --with-shared --without-debug --without-ada --enable-overwrite
$ make && make install
#cmake命令在mysql的5.5版本之后，取代./configure命令进行编译、安装前的环境检查；
#bison是一个自由软件，用于自动生成语法分析器程序，可用于所有常见的操作系统；
#ncurses 提供字符终端处理库，是 使应用程序（如命令终端）直接控制终端屏幕显示的函数库；
#安装ncurses依赖，需要ncurses-devel和ncurses，且ncurses需要安装对应的源码包
#源码安装ncurses选项详解：
#--with-shared    生成共享库
#--without-debug  不生成 debug 库
#--without-ada    不编译为ada绑定，因为进入chroot环境不能便用ada
#--enable-overwrite 参数为定义,指定把头文件安装到/tools/include目录下

#添加mysql用户
$ useradd -M -s /sbin/nologin mysql

#安装MySQL软件
$ tar -zxf mysql-5.5.48.tar.gz
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

#生成配置文件
$ cp -a support-files/my-medium.cnf /etc/my.cnf
#进入到指定的安装目录
$ cd /usr/local/mysql
#修改MySQL数据的用户归属
$ chown -R mysql data 
#初始化数据库
$ ./scripts/mysql_install_db --user=mysql

#后台启动
$ /usr/local/mysql/bin/mysqld_safe --user=mysql &
#查看启动结果、测试服务
$ ss -antp | grep :3306
----服务端就完成了
----客户端连接mysql服务
$ /usr/local/mysql/bin/mysql
mysql> show databases;

#设定MySQL密码（初始化密码，只能设置一次）
$ /usr/local/mysql/bin/mysqladmin -uroot password 123
#登录MySQL
$ /usr/local/mysql/bin/mysql -uroot -p,回车输入密码
mysql> show databases;

```



#### 安装php

```shell
##安装php（openssl memcache、freetype、mcrypt(libmcrypt和ltdl、mhash)、zlib、libpng、jpg/jpeg）

#安装字体库（freetype）
#FreeType库是一个开源的、高质量的且可移植的字体引擎，提供统一的接口来访问多种字体格式文件，支持单色位图、反走样位图的渲染。
$ tar -zxf freetype-2.3.5.tar.gz
$ cd freetype-2.3.5
$ ./configure --prefix=/usr/local/freetype
$ make && make install

#安装加密库（mcrypt <- mhash + libmcrypt和ltdl）
#安装libmcrypt：libmcrypt是加密算法扩展库。支持DES, 3DES, RIJNDAEL, Twofish, IDEA, GOST, CAST-256, ARCFOUR, SERPENT, SAFER+等算法。
$ tar -zxf libmcrypt-2.5.8.tar.gz
$ cd libmcrypt-2.5.8
$ ./configure --prefix=/usr/local/libmcrypt
$ make && make install
#安装libltdl：在libcrypt源码包目录中，需进入安装
$ cd libltdl
$ ./configure --enable-ltdl-install
$ make && make install
#安装mhash：mhash是基于离散数学原理的不可逆向的php加密方式扩展库，其在默认情况下不开启。mhash可以用于创建校验数值，消息摘要，消息认证码，以及无需原文的关键信息保存（如密码）等。
$ tar -zxf mhash-0.9.9.9.tar.gz
$ cd mhash-0.9.9.9
$ ./configure
$ make && make install
#安装mcypt：mcrypt 是 php 里面重要的加密支持扩展库。mcrypt库支持20多种加密算法和8种加密模式
$ tar -zxf mcrypt-2.6.8.tar.gz
$ cd mcrypt-2.6.8
$ export LD_LIBRARY_PATH=/usr/local/libmcrypt/lib:/usr/local/lib
$ ./configure --with-libmcrypt-prefix=/usr/local/libmcrypt
$ make && make install

#安装压缩库（zlib）
#安装zlib：zlib是提供数据压缩用的函式库，使用DEFLATE算法，最初是为libpng函式库所写的，后来普遍为许多软件所使用
$ tar -zxf zlib-1.2.3.tar.gz
$ cd zlib-1.2.3
$ ./configure
$ vim Makefile
	CFLAGS=-O3 -DUSE_MMAP -fPIC
  #找到CFLAGS=-O3 -DUSE_MMAP，在后面加入 -fPIC,是为了生成与位置无关的代码。程序启动时动态加载程序解析条目，为了兼容各个系统，在生成位置无关的代码的时候，应该使用-fPIC参数。
$ make && make install

#安装图片库（libpng、jpeg）
#安装libpng：libpng库被其他程序用于解码png图片
$ tar -zxf libpng-1.2.31.tar.gz
$ cd libpng-1.2.31
$ ./configure --prefix=/usr/local/libpng
$ make && make install
#安装jpeg6：提供用于解码.jpg和.jpeg图片的库文件(需手动创建目录)
$ mkdir /usr/local/jpeg6
$ mkdir /usr/local/jpeg6/bin
$ mkdir /usr/local/jpeg6/lib
$ mkdir /usr/local/jpeg6/include
$ mkdir -p /usr/local/jpeg6/man/man1   

$ yum -y install libtool*
$ tar -zxf jpegsrc.v6b.tar.gz
$ cd jpeg-6b
#复制libtool中的文件，覆盖jpeg-6b中的文件，解决64位系统中的问题
$ cp -a /usr/share/libtool/config/config.sub ./
$ cp -a /usr/share/libtool/config/config.guess ./
#--enable-shared与--enable-static参数分别为开启共享库和静态库的加载
$ ./configure --prefix=/usr/local/jpeg6 --enable-shared --enable-static
$ make && make install

#安装配置文件解析库（libxml2）              
#安装libxml2：一个c语言版的XML库，目前还支持c++、PHP、Pascal、Ruby、Tcl等语言的绑定，能在Windows、Linux、MacOsX等平台上运行、功能强大。
$ yum -y install libxml2-devel python-devel
$ tar -zxf libxml2-2.9.1.tar.gz
$ cd libxml2-2.9.1
$ ./configure --prefix=/usr/local/libxml2
$ make && make install

#安装PHP软件
$ tar -zxf php-7.0.7.tar.gz
$ cd php-7.0.7
$ ./configure --prefix=/usr/local/php/ --with-config-file-path=/usr/local/php/etc/ --with-apxs2=/usr/local/apache2/bin/apxs --with-libxml-dir=/usr/local/libxml2/ --with-jpeg-dir=/usr/local/jpeg6/ --with-png-dir=/usr/local/libpng/ --with-freetype-dir=/usr/local/freetype/ --with-mcrypt=/usr/local/libmcrypt/ --with-mysqli=/usr/local/mysql/bin/mysql_config --enable-soap --enable-mbstring=all --enable-sockets --with-pdo-mysql=/usr/local/mysql --with-gd --without-pear
$ make && make install
#选项详解：
#--with-config-file-path=/usr/local/php/etc/	指定配置文件目录
#--with-apxs2=/usr/local/apache2/bin/apxs		指定apache动态模块位置
#--with-libxml-dir=/usr/local/libxml2/			指定libxml位置
#--with-jpeg-dir=/usr/local/jpeg6/				指定jpeg位置
#--with-png-dir=/usr/local/libpng/				指定libpng位置
#--with-freetype-dir=/usr/local/freetype/		指定freetype位
#--with-mcrypt=/usr/local/libmcrypt/		    指定libmcrypt位置
#--with-mysqli=/usr/local/mysql/bin/mysql_config指定mysqli位置,mysql Improvement即mysql进阶版
#--with-gd                              		启用gd（php处理图形的扩展库），在网站中处理或生成图片
#--enable-soap									支持soap(简单对象访问协议)
#--enable-mbstring=all							支持多字节，字符串
#--enable-sockets								支持套接字
#--with-pdo-mysql=/usr/local/mysql				启用mysql的pdo（php数据对象）模块支持
#--without-pear									不安装pear(安装pear需要连接互联网)

#生成php配置文件
$ mkdir /usr/local/php/etc
$ cp -a php.ini-production /usr/local/php/etc/php.ini 

#修改apache配置文件，使其识别*.php文件，并通过php模块调用php进行页面解析
$ vim /usr/local/apache2/conf/httpd.conf
  php.so
  AddType application/x-httpd-php .php .phtml 
  AddType application/x-httpd-php-source .phps

#重启Apache服务
$ /usr/local/apache2/bin/apachectl stop  
$ /usr/local/apache2/bin/apachectl start

------------------------
#编写php界面、访问，即测试apache和php的连通性
$ vim /usr/local/apache2/htdocs/test-php.php
  <?php
		phpinfo();
  ?>
$ 浏览器输入网址访问：http://apacheServerIP/test-php.php 

-----------------------
#编写php网页中连接mysql数据库，即测试mysql和php的连通性
$ vim /usr/local/apache2/htdocs/test-php-mysql.php
<?php
	$servername = "localhost";
	$username = "root";
	$password = "123";
	// 创建连接
	$conn = mysqli_connect($servername, $username, $password);
	// 检测连接
	if ($conn) {
		echo "连接成功";
	} else {
		//die() 函数输出一条消息，并退出当前脚本,是 exit() 函数的别名。
    	die("Connection failed: " . mysqli_connect_error());
	}

	// 创建数据库
	$sql = "CREATE DATABASE  wordpress";
	if (mysqli_query($conn, $sql)) {
    	echo "数据库创建成功";
	} else {
    	echo "Error creating database: " . mysqli_error($conn);
	}
 
	mysqli_close($conn);
?>
$ 浏览器输入网址访问：http://apacheServerIP/test.php 

```

#### 优化PHP、添加扩展模块

```shell
#安装openssl扩展:OpenSSL 是一个强大的安全套接字层密码库，囊括主要的密码算法、常用的密钥和证书封装管理功能及SSL协议，并提供丰富的应用程序供测试或其它目的使用。
$ cd 解压目录/php-7.0.7/ext/openssl
$ mv config0.m4 config.m4
$ /usr/local/php/bin/phpize  #将信息输出
$ ./configure --with-openssl --with-php-config=/usr/local/php/bin/php-config
$ make && make install

#安装zlib扩展：
$ cd php-7.0.7/ext/zlib/
$ mv config0.m4 config.m4
$ /usr/local/php/bin/phpize
$ ./configure --with-zlib --with-php-config=/usr/local/php/bin/php-config
$ make && make install

#安装memcache：Memcache是一个高性能的分布式的内存对象缓存系统，通过在内存里维护一个统一的巨大的hash表，它能够用来存储各种格式的数据，包括图像、视频、文件以及数据库检索的结果等。简单的说就是将数据调用到内存中，然后从内存中读取，从而大大提高读取速度。
$ unzip 解压目录/pecl-memcache-php7.zip
$ cd pecl-memcache-php7
$ /usr/local/php/bin/phpize
$ ./configure --with-php-config=/usr/local/php/bin/php-config
$ make && make install
#安装memcache服务,需要依赖libevent-devel，CentOS6和CentOS7不同
$ cd 解压目录
$ yum -y install libevent 
$ yum -y install libevent-devel-2.0.21-4.el7.x86_64.rpm
$ tar -zxf memcached-1.4.17.tar.gz
$ cd memcached-1.4.17
$ ./configure --prefix=/usr/local/memcache
$ make && make install
#启动memcache
$ useradd -s /sbin/nologin memcache
$ /usr/local/memcache/bin/memcached -umemcache &
$ ss -antp | grep :11211

#修改PHP配置文件，使其识别和调用openssl和memcache两个模块
$ vim /usr/local/php/etc/php.ini
	extension_dir="/usr/local/php/lib/php/extensions/no-debug-zts-20151012/"

	#取消分号注释，并添加以上路径（此路径来自于模块安装命令的结果）
	extension="openssl.so";
	extension="memcache.so";
	extension="zlib.so";
	#添加以上三个库文件的调用

#重启Apache服务
$ /usr/local/apache2/bin/apachectl stop  
$ /usr/local/apache2/bin/apachectl start
#刷新test-php.php界面，查看是否有openssl、memcache、zlib模块

```



#### 搭建网站

```shell
#将php项目拷贝到网站目录下（/usr/local/apache2/htdocs/**）；使用phpMyAdmin或命令行创建网站所需的数据库
#搭建wordpress：WordPress是一款个人博客系统，并逐步演化成一款内容管理系统软件，它是使用PHP语言和MySQL数据库开发的,用户可以在支持 PHP 和 MySQL数据库的服务器上使用自己的博客。
$ tar -zxf wordpress-4.7.4-zh_CN.tar.gz
$ cp -a wordpress /usr/local/apache2/htdocs/
$ useradd -M -s /sbin/nologin apache
$ chown -R apache:apache /usr/local/apache2/htdocs
$ vim /usr/local/apache2/conf/httpd.conf
	User apache
	Group apache
	
	<IfModule dir_module>
    	DirectoryIndex index.html index.php  #默认界面改为index.php
	</IfModule>
#重启apache服务
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start
$ 进入数据库创建wordpress数据库
#界面访问 http://serverIP/wordpress/index.php

#网站测试：
改主题、写文章（若写的文章是中文主题，需要联网添加Pinyin Permalink插件、并启用）

```



#### 设置相关的服务开机自启

```shell
#设置apache、mysql、memcache（安装了优化PHP部分）开机自启
$ vim /etc/rc.local
	/usr/local/apache2/bin/apachectl start
	/usr/local/mysql/bin/mysqld_safe --user=mysql &
	/usr/local/memcache/bin/memcached -umemcache &    
$ chmod +x /etc/rc.d/rc.local 

```





——————————————

###### 用rpm包搭建LAMP环境：

```shell
$ yum -y install mariadb mariadb-server php php-mysqli php-pdo httpd
```

