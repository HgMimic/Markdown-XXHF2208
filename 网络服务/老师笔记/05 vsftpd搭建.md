#### 匿名用户登录及设置

###### 服务器端

```shell
#安装软件
$ yum -y install vsftpd      
#开启服务
$ systemctl start vsftpd
#通过端口验证开启成功，结果中可以看到用来监听的21端口
$ ss -antp | grep vsftpd    

#去掉前面的注释来增加匿名用户的权限
#注意此时应该先把要上传共享目录的文件系统权限设置上
$ vim /etc/vsftpd/vsftpd.con
	anon_upload_enable=YES         #设置上传权限
	anon_mkdir_write_enable=YES    #设置创建目录权限
	anon_other_write_enable=YES    #设置其他写入权限
	
```

###### 客户端

```shell
#安装连接命令
$ yum -y install ftp
#连接ftp服务器
$ ftp  ftp服务器IP
	输入用户名：ftp 或 anonymous
	输入密码：随便输入、一般输空直接回车
ftp> pwd          #查看当前位置，在匿名用户的共享根目录即/var/ftp
ftp> get 文件名    #从共享目录下载文件到客户端的当前位置
ftp> put 文件名    #向共享目录上传文件、默认没有
ftp> mkdir 目录名  #在共享目录中创建目录的权限、默认没有
ftp> rename、delete等 #在共享目录的其他写权限、默认没有

#windows客户端
在文件资源管理器的地址栏中，输入：ftp://vsftpd服务IP/

```



#### 本地用户登录及设置

###### 服务器

```shell
#安装软件
$ yum -y install vsftpd      
#开启服务
$ systemctl start vsftpd
#通过端口验证开启成功，结果中可以看到用来监听的21端口
$ ss -antp | grep vsftpd    

#禁锢本地用户只能在自己的家目录范围
#注意此时应该先把要上传共享目录的文件系统权限设置上
$ vim /etc/vsftpd/vsftpd.conf
	chroot_local_user=YES         #禁锢本地用户在家目录
	allow_writeable_chroot=YES    #禁锢本地用户后允许写权限，CentOS6.8系统上不用添加这条设置
	
#注意
vsftpd服务在验证用户时，会查询该用户的shell类型，
即若用户的shell类型不在/etc/shells文件中，则vsftpd服务拒绝登录；
CentOS7.6中/etc/shells中默认不包含/sbin/nologin类型，需要添加上。

```

###### 客户端

```shell
#安装连接命令
$ yum -y install ftp
#连接ftp服务器
$ ftp  ftp服务器IP
	输入用户名：vsftpd服务的用户名
	输入密码：vsftpd服务该用户的密码
ftp> pwd             #查看当前位置，在本地用户的家目录即/home/用户名
ftp> get 文件名       #从共享目录下载文件到客户端的当前位置
ftp> put 文件名       #向共享目录上传文件、默认有权限
ftp> mkdir 目录名     #在共享目录中创建目录的权限、默认有权限
ftp> rename、delete等 #在共享目录的其他写权限、默认有权限

#windows客户端
在文件资源管理器的地址栏中，输入：ftp://vsftpd服务IP/
右键登录

```



#### 虚拟用户搭建

```shell
#创建本地的代理用户（可将虚拟用户的家目录设置为指定的共享目录）
$ useradd -d /shares -s /sbin/nologin  virtual
$ chmod 755 /shares

#创建被代理的账号信息、并更改成数据库文件（注：不能有空格）
$ cd /etc/vsftpd
#该文件名可以随便定义，文件内容格式：奇数行用户，偶数行密码
$ vim user.list
	username
	password
#将用户密码的存放文本转化为数据库类型，并使用hash加密
$ db_load -T -t hash -f /etc/vsftpd/user.list user.db
#-T就是这指定把普通文件转换为数据库文件，-t指定转换的数据库类型，这是hash，把一串较复杂的转换为较短且唯一的值，-f要转换的文件
#修改文件权限为600，保证其安全性
$ chmod 600 user.*

#更改vsftpd的认证方式
$ cd /etc/pam.d
$ cp vsftpd vsftpd.virtual
$ vim vsftpd.virtual
	#认证    需要        模块            数据文件路径，省略最后的.db
	auth    required pam_userdb.so  db=/etc/vsftpd/user
	account required pam_userdb.so  db=/etc/vsftpd/user

#更改主配置文件（注；不能有空格）
$ vim /etc/vsftpd/vsftpd.conf
	chroot_local_user=YES      (已存在、可选设)
	allow_writeable_chroot=YES

	pam_service_name=vsftpd.virtual
	userlist_enable=YES
	tcp_wrappers=YES
	guest_enable=YES
	guest_username=virtual
	user_config_dir=/etc/vsftpd/virtual_config
	
#该虚拟用户配置文件以被代理的用户名为文件名，内容为权限，可单独设置某一个权限、每个用户单独设置
#注：此时的共享目录是虚拟用户的家目录；内容不能有空格
$ cd /etc/vsftpd
$ mkdir virtual_config
$ cd virtual_config
$ touch laow
	anon_upload_enable=YES                   #能上传文件
	local_root=/shares/yunwei
	#shares目录是最大的目录，里面可以设置yunwei、kaifa子目录、需自己添加
	
$ touch laoli
	anon_upload_enable=YES                   #能上传文件
	anon_mkdir_write_enable=YES              #能创建文件夹
	anon_other_write_enable=YES	             #其他写入权限，如：改名、删除

#重启服务
$ systemctl restart vsftpd

```



#### FTP加密传输

```shell
$ cd /etc/ssl/certs
#安装加密算法的依赖包openssl
$ yum -y install openssl openssl-devel

#创建证书
#-req：证书签名请求（Certificate Signing Request）
#-new：表示生成一个新的证书签署请求；
#-x509：专用于生成CA自签证书的目录，指定生成证书的格式
#-nodes 给当前主机的私钥创建证书
#-key：指定生成证书用到的私钥文件；
#-out FILNAME：指定生成的证书的保存路径；
#-keyout FIENAME：用自己定义的密钥进行加密；
#-days：指定证书的有效期限，单位为day，默认是365天；

#生成服务器公钥、采用rsa算法
$ openssl genrsa -out vsftpd.key 1024 
#根据服务器公钥，输入国家、地区、组织等证书信息，创建服务器自己的证书，生成csr文件、交给CA签名
$ openssl req -new -key vsftpd.key -out vsftpd.csr
#使用CA服务器签发证书，设置证书有效期等信息---模拟
$ openssl x509 -req -days 365 -sha256 -in vsftpd.csr -signkey vsftpd.key -out vsftpd.crt
#修改证书文件的权限
$ chmod 500 /etc/ssl/certs/vsftpd.crt

#vsftpd配置文件添加加密设置，man vsftpd.conf
$ vim /etc/vsftpd/vsftpd.conf
	ssl_enable=YES
    #启用ssl认证、虚拟机版本不同支持的ssl版本不同
    ssl_tlsv1=YES
    ssl_sslv2=YES
    ssl_sslv3=YES
    #开启tlsv1、sslv2、sslv3都支持，转换成使用tls1.2
    allow_anon_ssl=YES
    #允许匿名用户{虚拟用户}
    force_anon_logins_ssl=YES
    force_anon_data_ssl=YES
    #匿名登录和传输时强制使用ssl
    force_local_logins_ssl=YES
    force_local_data_ssl=YES
    #本地登录和传输时强制使用ssl
    rsa_cert_file=/etc/ssl/certs/vsftpd.crt
    #rsa格式的证书
    rsa_private_key_file=/etc/ssl/certs/vsftpd.key
    #rsa格式的公钥
    
 $ systemctl restart vsftpd
 
```

