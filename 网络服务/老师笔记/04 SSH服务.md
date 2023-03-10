#### 一、密码验证方式 

```shell
#客户机想连接服务器，需要在客户机上执行：
$ ssh 远程连接使用的服务器端用户名@服务器端的IP地址
或：
$ ssh 服务器端的IP地址
	#该省略模式，默认以当前客户机上的同名用户远程登录服务器
```



#### 二、密钥验证方式

```shell
1、ssh-keygen -t rsa -b 2048   
	# 客户端生成密钥对文件。-t指定加密类型（rsa或dsa）、-b指定密钥对加密长度
	#交互1：密钥对保存位置，默认在该用户家目录的.ssh目录下
	#交互2：是否对密钥文件加密。若加密在调用密钥文件时需要先验证密钥密码再使用密钥文件；若不加密则密钥文件可直接调用、整个登录过程不用输入任何密码，即免密登录
	
2、ssh-copy-id 用户名@ip地址
	#将公钥文件上传到服务器。-i指定上传的公钥文件位置和文件名，默认是id_rsa.pub
	
3、ssh 用户名@IP地址
	#客户端尝试登录服务器   
    
```

##### 注：密钥对验证优先级大于账号密码验证



#### 三、特定功能配置

```shell
$ vim /etc/ssh/sshd_config
	#取消dns验证、缩短连接时间
	UseDNS no
	#禁止密码验证
	PasswordAuthentication no
	#禁止使用root远程登录
	PermitRootLogin no
	#修改默认端口，连接时指定-p参数
	Port 59527     
	#限制监听地址
	ListenAddress 服务器端ip
```

