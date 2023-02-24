#### 一、源码包安装

```shell
#安装基础依赖
$ yum -y install openssl openssl-devel zlib zlib-devel pcre pcre-devel
#安装支持http2协议的，
#需要nghttp2依赖；需要httpd版本在2.4.17以上;需要openssl在1.0.2及以上
$ yum -y install libnghttp2-1.33.0-1.1.el7.x86_64.rpm
$ yum -y install libnghttp2-devel-1.33.0-1.1.el7.x86_64.rpm

#解压源码包并解决依赖关系
$ tar -zxf  httpd-2.4.47.tar.gz 
$ tar -zxf  apr-1.4.6.tar.gz 
$ tar -zxf  apr-util-1.4.1.tar.gz 

#解决依赖关系
$ cp -r  apr-1.4.6       httpd-2.4.47/srclib/apr
$ cp -r  apr-util-1.4.1  httpd-2.4.47/srclib/apr-util

#编译、安装，每步执行完用echo $?检测
#--prefix:指定安装路径, enable-rewrite:开启地址重写, enable-so:开启dso(动态共享对象), enable-headers:允许修改http的请求头, enable-expires:允许客户端缓存, enable-modules=most:尽可能安装更多模块, enable-deflate:开启对压缩的支持, enable-ssl:开启https的支持
$ cd httpd-2.4.47
$ ./configure --prefix=/usr/local/apache2  --enable-rewrite --enable-so --enable-headers --enable-expires  --enable-modules=most --enable-deflate --enable-ssl --enable-http2 
$ make && make install


#检测配置文件、启停服务
$ /usr/local/apache2/bin/apachectl 
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start

#添加或修改网页
$ vim /usr/local/apache2/htdocs/index.html 
	hello~
	
	
—————————————————————————————————————————————————————
客户端测试
#客户端界面访问测试：
http://服务器IP/index.html

#命令行使用curl，它是一个命令行访问URL的工具
$ curl localhost

```



#### 二、服务配置参数

```shell
#若访问目录下没有默认网页，允许该目录下所有文件以软链接方式访问
$ vim /usr/local/apache2/conf/httpd.conf
	#修改对应网页的设置
	<Directory "/usr/local/apache2/htdocs">
		#若不存在默认界面，访问网页目录下所有文件的链接
		Options Indexes FollowSymLinks
		
		AllowOverride None
		Require all granted
	</Directory>
	
	#默认缺省界面设置
	<IfModule dir_module>
    	DirectoryIndex index.html index.php
	</IfModule>

#删除网站目录下，默认的缺省界面
$ cd /usr/local/apache2/htdocs
$ rm -rf index.html

#重启服务
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start

##在浏览器访问:  http://serverIP/

-------------------------------
#若访问目录下没有默认网页，拒绝访问
$ vim /usr/local/apache2/conf/httpd.conf
	#修改对应网页的设置
	<Directory "/usr/local/apache2/htdocs">
		#若不存在默认界面，则拒绝访问
		Options None
		
		AllowOverride None
		Require all granted
	</Directory>

#删除网站目录下，默认的缺省界面
$ cd /usr/local/apache2/htdocs
$ rm -rf index.html


#重启服务
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start

##在浏览器访问:  http://serverIP/

```



####  三、用户访问功能搭建

###### 指定用户访问，给某个网页设置ACL

```shell
#指定目录下创建权限文件,本例子是加在网页根目录，访问任何页面都要求验证用户
$ cd /usr/local/apache2/htdocs
$ vim .htaccess
	AuthName "Welcome to kernel"
	#提示信息
	AuthType basic
	#加密类型
	AuthUserFile /usr/local/apache2/htdocs/apache.passwd
	#密码文件，文件名自定义。（使用绝对路径）
	require valid-user
	#允许密码文件中所有用户访问
	
#创建指定的密码文件、添加允许访问的用户（与系统用户无关）
#注：-c创建密码文件和添加第一个用户、-m添加更多用户；
$ cd /usr/local/apache2
$ ./bin/htpasswd -c  htdocs/apache.passwd 访问用户名1
$ ./bin/htpasswd -m  htdocs/apache.passwd 访问用户名2

#编辑配置文件，在需要登录认证的目录标签中添加：
$ vim /usr/local/apache2/conf/httpd.conf
	<Directory "/usr/local/apache2/htdocs"> 
	#声明被保护目录，没有开启虚拟主机时默认是htdocs目录即可，只要在对应的权限控制目录下创建.htaccess文件即可
		Options Indexes FollowSymLinks
		 #开启权限认证文件.htaccess
		AllowOverride All		     
		Require all granted
	</Directory>

#重启服务、验证（访问界面后输入用户名和密码才能看到内容）
$ /usr/local/apache2/bin/apachectl -t
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start


------------------
实验：添加在网页目录下的子目录下，则界面只访问该目录下页面时需要验证用户；其他页面可以直接访问

```



###### 指定IP拒绝访问

```shell
#允许所有、拒绝个别
$  vim /etc/httpd/conf/httpd.conf
	<Directory />
		AllowOverride none
    	Require all denied
   		deny from 192.168.66.13
	</Directory>
$ systemctl restart httpd

#允许个别、拒绝所有
$  vim /etc/httpd/conf/httpd.conf
	<Directory />
		AllowOverride none
    	Require all denied
   		allow from 192.168.66.13
   		deny from 192.168.66.0/24
	</Directory>
	
$ systemctl restart httpd

-----------------
指定的客户端上测试

```



#### 四、虚拟主机功能搭建（基于域名）

```shell
#主配置文件开启虚拟主机模块的关联配置文件
$ vim /usr/local/apache2/conf/httpd.conf
	Include conf/extra/httpd-vhosts.conf  #取消注释
	LoadModule vhost_alias_module modules/mod_vhost_alias.so
	
#编辑虚拟主机配置文件、添加相应的标签
$ vim /usr/local/apache2/conf/extra/httpd-vhosts.conf
	#有几个虚拟机主机添加几组下面的标签
	
	#配置sina虚拟主机
  	<VirtualHost *:80>				    #虚拟主机标签（ip、端口）
		ServerAdmin webmaster@old.com	#管理员邮箱
		DocumentRoot "/usr/local/apache2/htdocs/old" #网站主目录
		ServerName www.old.com			 #完整域名
		ErrorLog "logs/old-error_log"	 #错误日志
		CustomLog "logs/old-access_log" common	 #访问日志
  	</VirtualHost>
  	#设置old虚拟主机的权限，若与主配置文件中配置相同、可省略
  	<Directory "/usr/local/apache2/htdocs/old">
  		Options Indexes FollowSymLinks
  		AllowOverride All
  		Require all granted
  	</Directory>
  	
  	#配置souhu虚拟主机
  	<VirtualHost *:80>			     #虚拟主机标签（ip、端口）
		ServerAdmin webmaster@new.com	 #管理员邮箱
		DocumentRoot "/usr/local/apache2/htdocs/new"#网站主目录
		ServerName www.new.com		 #完整域名
		ErrorLog "logs/new-error_log"	 #错误日志
		CustomLog "logs/new-access_log" common	  #访问日志
  	</VirtualHost>
  	#设置new虚拟主机的权限，若与主配置文件中配置相同、可省略
  	<Directory "/usr/local/apache2/htdocs/new">
  		Options Indexes FollowSymLinks
  		AllowOverride All
  		Require all granted
  	</Directory>
 
#创建网页目录
$ cd /usr/local/apache2/htdocs
$ mkdir old
$ echo "old pages" > old/index.html
$ mkdir new
$ echo "new pages" > new/index.html
  	
#重启服务、验证（访问界面后输入用户名和密码才能看到内容）
$ /usr/local/apache2/bin/apachectl -t
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start

---------------------
#客户端配置
1.更改hosts文件，添加服务器IP 指定的域名
2.界面访问指定域名

```





#### 五、地址跳转（基于域名的虚拟主机基础上，www.souhu.com --> www.sina.com）

```shell
#主配置文件开启重定向模块   
$ vim /usr/local/apache2/conf/httpd.conf
	LoadModule rewrite_module modules/mod_rewrite.so   #取消注释

#地址跳转的可用参数，参考：http://httpd.apache.org/docs/2.4/mod/mod_rewrite.html

#方法一：1.在需要进行跳转的目录下添加.htaccess权限文件；
#     2.保证包含该.htaccess权限文件的目录的AllowOverride All是打开的；
$ cd /usr/local/apache2/htdocs/old
$ vim .htaccess
	RewriteEngine on
	RewriteCond %{HTTP_HOST} www.old.com 
	RewriteRule ^(.*)$ http://www.new.com/$1 [R=permanent,L]
#解释1：$1是前面用正则截取的客户端请求路径中部分
	#如：客户端请求：http://www.old.com/1.html,则正则截取到1.html,则$1的值是1.html，则跳转到http://www.new.com/1.html
	#规则中用正则匹配多个时，即多个()，则跳转后可以用$1、$2等接收
#解释2：匹配规则RewriteRule的格式：
	#RewriteRule Pattern Substitution [flags]
	#RewriteRule  正则匹配   匹配的替换  限制参数
	#参数中:R(Redirect,重定向方式)、L（last，结尾规则即匹配到此就结束）等


#检查下AllowOverride All是打开的（改htdocs下的可以，自己写old的Directory并修改也可以）
$ vim /usr/local/apache2/conf/httpd.conf
	<Directory "/usr/local/apache2/htdocs">
  		Options Indexes FollowSymLinks
  		AllowOverride All        #由None改成All
  		Require all granted
  	</Directory>
  	

#方法二：为要跳转的网站根目录写Directory标签
$ vim usr/local/apache2/conf/extra/httpd-vhosts.conf
	<Directory "/usr/local/apache2/htdocs/old">
  		RewriteEngine on
		RewriteCond %{HTTP_HOST} www.old.com 
		RewriteRule ^(.*)$ http://www.new.com/$1 [R=permanent,L]
  	</Directory>
  	

#重启服务、验证（访问界面后输入用户名和密码才能看到内容）
$ /usr/local/apache2/bin/apachectl -t
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start

--------------
#客户端访问
客户端访问www.souhu.com自行跳转到www.sina.com界面；
此跳转能在浏览器中正常体现；在字符终端访问返回301网页；

```



#### 六、结合openssl实现https

```shell
#前提：安装apache的时候需要添加选项(--enable-ssl)、安装了基础依赖(openssl、openssl-devel)
#修改主配置文件开启ssl模块、开启加载ssl关联的配置文件
$ vim /usr/local/apache2/conf/httpd.conf
	LoadModule ssl_module modules/mod_ssl.so  #取消注释
	Include conf/extra/httpd-ssl.conf         #取消注释
	#加载缓存模块
	LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
	
#修改ssl关联的配置文件(改域名、关缓存)
$ vim /usr/local/apache2/conf/extra/httpd-ssl.conf
	<VirtualHost _default_:443>
        #改域名
        DocumentRoot "/usr/local/apache2/htdocs/new"
        ServerName  www.new.com:443
        ServerAdmin webmaster@new.com
        ErrorLog "logs/new-https-error_log"
        CustomLog "logs/new-https-access_log" common
	</VirtualHost>
	
#创建证书，配置文件指定默认在配置文件所在目录
$ cd /usr/local/apache2/conf  
$ openssl genrsa -out server.key 1024	  	
$ openssl req -new -key server.key -out server.csr     
$ openssl x509 -req -days 365 -sha256 -in server.csr -signkey server.key -out server.crt 	

#重启服务、验证（访问界面后输入用户名和密码才能看到内容）
$ /usr/local/apache2/bin/apachectl -t
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start

-----------------------
#客户端访问
浏览器地址栏输入：https://www.new.com  - 高级-继续访问

```



#### 七、地址跳转（端口跳转，www.new.com的80 --> 443）

```shell
#主配置文件开启重定向模块
$ vim /usr/local/apache2/conf/httpd.conf
	LoadModule rewrite_module modules/mod_rewrite.so   #取消注释
	
#在需要进行跳转的目录下添加权限文件
$ cd /usr/local/apache2/htdocs/new
$ vim .htaccess
	RewriteEngine on          
    #判断站点访问端口，不是443的时候，进行处理；HTTP_PORT是80
	RewriteCond %{SERVER_PORT} !443                  
	RewriteRule ^(.*)$ https://www.new.com/$1 [R=permanent,L]

#重启服务、验证（访问界面后输入用户名和密码才能看到内容）
$ /usr/local/apache2/bin/apachectl -t
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start

--------
#方法二：.htaccess文件的替代写法
<Directory "/usr/local/apache2/htdocs/new">
	RewriteEngine on				 #开启转发规则
   	RewriteCond %{SERVER_PORT} !443  #检查访问端口只要目标不是443的
    RewriteRule ^(.*)$ https://%{SERVER_NAME}/$1 [R=301,L]	 #全都使用https重新访问
</Directory>

```



#### 八、http2

```shell
#环境要求：
1.httpd软件包在2.4.17以上，否则不支持mod_http2
2.需要依赖nghttp2在1.2.1以上
3.需要依赖openssl在1.0.2以上
4.需要在configure时指定--enable-http2选项

#结合ssl、配置端口跳转
$ vim /usr/local/apache2/conf/httpd.conf
	#开启HTTP/2.0模块、SSL模块
	LoadModule http2_module modules/mod_http2.so  #加载http2模块
	LoadModule ssl_module modules/mod_ssl.so
	Include etc/extra/httpd-ssl.conf
	#加载缓存模块
	LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
	
#配置ssl子文件
$ vim /usr/local/apache2/conf/extra/httpd-ssl.conf
	DocumentRoot "/usr/local/apache2/htdocs"
	ServerName www.linuxlc.com:443
	ServerAdmin you@example.com
	ErrorLog "/usr/local/apache2/logs/error_log"
	TransferLog "/usr/local/apache2/logs/access_log"
	
	Protocols h2 http/1.1    #支持的协议增加h2
	
	SSLEngine on
	
#创建证书
$ cd /usr/local/apache2/conf/
$ openssl genrsa -out server.key 1024
$ openssl req -new -key server.key -out server.csr
$ openssl x509 -req -days 365 -sha256 -in server.csr -signkey server.key -out server.crt
	
#重启服务
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start

-----------------
客户端测试；
https://IP
http://IP/xx.html  -- 跳转到https，查看开发者工具，右键勾选Protocol，看到h2

----------创建.htaccess文件等价于对应目录添加Directory
#添加80-443跳转：
$ vim  /usr/local/apache2/conf/httpd.conf
	#开启跳转
	LoadModule rewrite_module modules/mod_rewrite.so
	#端口跳转（80-443）
	<Directory "/usr/local/apache2/htdocs">
    	RewriteEngine on
    	RewriteCond %{SERVER_PORT} !443
    	RewriteRule ^(.*)$ https://%{SERVER_NAME}/$1 [R=301,L]
	</Directory>
#重启服务
$ /usr/local/apache2/bin/apachectl stop
$ /usr/local/apache2/bin/apachectl start

```

