#### 一、安装

```shell
#nginx支持的http2的条件：nginx版本在1.9.5以上、openssl在1.0.2e以上

#安装nginx，要支持http2需要nginx在1.9.5以上、openssl在1.0.2e及以上
#如果openssl版本在1.0.2以下，需要安装源码包openssl、并在nginx的configure中写--with-openssl选项
-----------------------
#查看系统的openssl版本
$ openssl version
#若结果大于等于1.0.2，则不需要安装源码包openssl
$ yum -y install zlib zlib-devel pcre pcre-devel openssl-devel openssl

#添加nginx管理用户
$ useradd -M -s /sbin/nologin nginx

#安装nginx，要支持http2需要nginx在1.9.5以上、openssl在1.0.2e及以上
#如果openssl版本在1.0.2以下，需要在configure中写--with-openssl选项
$ cd nginx-1.13.8
$ ./configure --user=nginx --group=nginx --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-stream
$ make && make install

--------------------------------
#查看系统的openssl版本
$ openssl version
#若openssl版本小于1.0.2
#安装基础依赖、openssl解压源码包
$ yum -y install zlib zlib-devel pcre pcre-devel openssl-devel
#解压openssl，会在后面和nginx一起安装
$ tar -zxf openssl-1.0.2h.tar.gz    

#添加nginx管理用户
$ useradd -M -s /sbin/nologin nginx

#安装nginx，要支持http2需要nginx在1.9.5以上、openssl在1.0.2e及以上
#如果openssl版本在1.0.2以下，需要在configure中写--with-openssl选项
$ cd nginx-1.13.8
$ ./configure --user=nginx --group=nginx --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-stream           --with-openssl=/root/lnmp/openssl-1.0.2h 
$ make && make install

-----------------------

#查看nginx的安装条件
$ /user/local/nginx/sbin/nginx -V(大)

#检测配置文件、启动服务
$ /user/local/nginx/sbin/nginx  -t
$ /user/local/nginx/sbin/nginx
#平滑重启，热部署（注需要之前已经运行了nginx服务）
$ /user/local/nginx/sbin/nginx -s reload
或：kill -HUP $(cat /user/local/nginx/logs/nginx.pid)
或：pkill -HUP nginx

```



#### 配置文件结构

```shell
$ vim /usr/local/nginx/conf/nginx.conf
	.....     #全局块，配置影响nginx全局的属性，如用户信息、worker数等
	
	events {  #events块，配置nginx与用户的允许同时建立的网络连接数
		....
	}
	
	http {    #http块，配置代理、缓存等参数
		....       #http全局块
		server {   #server块，配置虚拟主机参数，一个http可有多server
			....
			location [pattern]{ #location块，配置请求路由及对应处理
				...
			}
			location [pattern]{
				...
			}
		}
		server {   #配置多个server块
			....
			location [pattern]{
				...
			}
			location [pattern]{
				...
			}
		}
	}
```



#### 二、统计模块

```shell
#安装时添加模块选项：--with-http_stub_status_module，nginx内置的状态监控页面，可用于监控nginx的整理访问情况
#主配置文件添加
$ vim /usr/local/nginx/conf/nginx.conf
    ....  #其他设置
	location /nginx_status{
		stub_status on;
	}
#重启服务
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

-----------------------
页面访问：http://IP/nginx_status
#结果分析：
	"Active connections"表示当前的活动连接数；
	"server accepts handled requests"表示已经处理的连接信息；
	三个数字依次表示已经处理的连接数、成功的TCP握手次数、已处理的请求数
	"Reading: 0 Writing: 1 Waiting: 0" 表示正在读取客户端的连接数、响应数据到客户端的数、等待再次请求的连接数
```



#### 三、访问控制

```shell
####基于用户名、密码的验证访问
$ vim /usr/local/nginx/conf/nginx.conf
	#在想验证的location下面添加,以根区域为例
	location / {
		root html;
		index index.html index.htm;
		#添加下面两行
		auth_basic "welcome you here";
		auth_basic_user_file /usr/local/nginx/html/a.psd;
	}
#创建认证文件，htpasswd是安装包httpd-tools拥有的命令
$ cd /usr/local/nginx
$ htpasswd -c /usr/local/nginx/html/a.psd 访问用户名

#重启服务
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

-----------------------
####基于IP地址的访问（顺序优先）
#允许所有、拒绝个别
$ vim /usr/local/nginx/conf/nginx.conf
	location / {
            root   html;
            index  index.html index.htm index.php;           
            deny 192.168.66.13;
            allow 192.168.66.0/24;
     }
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

#允许个别、拒绝所有
$ vim /usr/local/nginx/conf/nginx.conf
	location / {
            root   html;
            index  index.html index.htm index.php;
            allow 192.168.66.13;
            deny 192.168.66.0/24;        
     }
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

------------
客户机测试：
输入响应的请求资源时会弹出认证窗口
```



#### 三、虚拟主机（基于域名）

```shell
#在主配置文件中，添加不同的server区域
$ vim /usr/local/nginx/conf/nginx.conf
	server {
		listen 80;
		server_name www.new.com;
		location / {
			root  html/new;
			index index.html index.htm index.php;
		}
	}
	
	server {
		listen 80;
		server_name www.old.com;
		location / {
			root  html/old;
			index index.html index.htm index.php;
		}
	}
#新建站点和访问界面、并赋予nginx权限
$ cd /usr/local/nginx/html
$ mkdir old
$ mkdir new
$ echo "new pages~" > new/index.html
$ echo "old pages~" > old/index.html

#重启服务
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

——————————————————————————
客户端测试
$ vim /etc/hosts
	IP地址  www.new.com
	IP地址  www.old.com
$ curl www.new.com
$ curl www.old.com

```



#### 四、域名跳转（old -> new）

```shell
#基于上面的虚拟主机实验
$ vim /usr/local/nginx/conf/nginx.conf
	server {
		listen 80;
		server_name www.new.com;
		location / {
            root  html/new;
            index index.html index.htm index.php;
		}
	}
	
	server {
		listen 80;
		server_name www.old.com;
		location / {
			rewrite ^(.*)$  http://www.new.com$1 permanent;
		}
	}

#重启服务
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

——————————————————————————
客户端测试
$ vim /etc/hosts
$ curl www.new.com
$ curl www.old.com
#此时访问原来的也可以,其网页位置在html根目录
$ curl localhost

```



#### 五、实现https加密

```shell
#生成证书,默认路径在PREFIX/conf目录下
$ cd /usr/local/nginx/conf  
$ openssl genrsa -out cert.key 1024 
#建立服务器私钥，生成RSA密钥
$ openssl req -new -key cert.key -out cert.csr 
#需要依次输入国家，地区，组织，email。最重要的是有一个common name，可以写你的名字或者域名。如果为了https申请，这个必须和域名吻合，否则会引发浏览器警报。生成的csr文件交给CA签名后形成服务端自己的证书
$ openssl x509 -req -days 365 -sha256 -in cert.csr -signkey cert.key -out cert.pem 

#修改主配置文件，修改server端口为443、添加验证配置
$ vim /usr/local/nginx/conf/nginx.conf
	server{
		listen 443;
		server_name www.new.com; 
		
		ssl on; 
		ssl_certificate  cert.pem;     
		ssl_certificate_key  cert.key; 
		
		ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        ssl_ciphers  HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers  on;
        
        location / {
            root  html/new;
            index index.html index.htm index.php;
		}
	}

#重启服务
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

```



#### 六、跳转（80 -> 443）

```bash
#修改主配置文件，修改server端口为443、添加验证配置
$ vim /usr/local/nginx/conf/nginx.conf
	server {
        listen       80;
        server_name  ${访问的域名};
        location / {
                rewrite ^(.*)$ https://$host$1 permanent;
        }
   }

	server{
		listen 443;
		server_name ${访问的域名};
		
		ssl on; 
		ssl_certificate  cert.pem;     
		ssl_certificate_key  cert.key; 
		
		ssl_session_timeout 5m;  
		
		ssl_ciphers HIGH:!RC4:!MD5:!aNULL:!eNULL:!NULL:!DH:!EDH:!EXP:+MEDIUM; 			 ssl_prefer_server_ciphers on;
		
		location / {
            root  html/new;
            index index.html index.htm index.php;
		}
	}

#重启测试
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload
#界面访问http的域名自动跳转到对应的https域名

```



#### 扩展：http2

```shell
#注：1、安装时有--with-http_v2_module参数

#生成证书,默认路径在PREFIX/conf目录下
$ cd /usr/local/nginx/conf  
$ openssl genrsa -out cert.key 1024 
#建立服务器私钥，生成RSA密钥
$ openssl req -new -key cert.key -out cert.csr 
#需要依次输入国家，地区，组织，email。最重要的是有一个common name，可以写你的名字或者域名。如果为了https申请，这个必须和域名吻合，否则会引发浏览器警报。生成的csr文件交给CA签名后形成服务端自己的证书
$ openssl x509 -req -days 365 -sha256 -in cert.csr -signkey cert.key -out cert.pem 

#修改主配置文件，修改server端口为443、添加验证配置
vim /usr/local/nginx/conf/nginx.conf
	server{
		#listen的值加上ssl、http2
		listen 443 ssl http2;
		server_name ${访问的域名};
		
		ssl on; 
		ssl_certificate  cert.pem;     
		ssl_certificate_key  cert.key; 
		
		ssl_session_timeout 5m; 
		
		ssl_ciphers HIGH:!RC4:!MD5:!aNULL:!eNULL:!NULL:!DH:!EDH:!EXP:+MEDIUM; 			ssl_prefer_server_ciphers on;
		
		location / {
            root  html/new;
            index index.html index.htm index.php;
		}
	}

#重启服务
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

```



#### 七、反向代理

###### nginx代理服务器

```shell
#主配置文件对应的location下面添加代理网站proxy_pass
$ vim /usr/local/nginx/conf/nginx.conf
	server{
		....    #其他配置
		location / {
			#此处填写真实服务器的IP地址，代理其他主机
			#也可填本机其他域名，实现跳转
			proxy_pass http://192.168.88.100:80;			
		}
	}
	
#重启服务
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

```

###### 后台真实服务器

```shell
#配置任何web服务都可，本例配置apache服务
$ yum -y install httpd
$ echo "pages from real server~" > /var/www/html/index.html
$ systemctl start httpd

```

###### 测试机

```shell
#访问nginx所在机器的IP或域名，出现Apache里的界面内容
```



#### 八、负载均衡

```shell
#主配置文件对应的location下面添加代理网站proxy_pass
$ vim /usr/local/nginx/conf/nginx.conf
	#此标签在server标签前添加
	upstream hongfu {		
       #权重越大，访问它的次数就越多
		server 192.168.88.100:80 weight=1;
		server 192.168.88.200:80 weight=1;
	}
	
	server {
		listen 80;
		server_name www.new.com;
		#修改自带的location /的标签，将原内容删除，添加下列两项
		location / {
			#添加反向代理，代理地址填写upstream声明的名字
			proxy_pass http://hongfu;	
			#重写请求头部，保证网站所有页面都可访问成功（有的后端真实服务器会设置类似防盗链或者根据请求中host来进行路由判断等时，会报400）
			proxy_set_header Host $host;		
		}
	}
	
#重启服务
$ /usr/local/nginx/sbin/nginx -t
$ /user/local/nginx/sbin/nginx -s reload

------------------
配置被代理的真实服务器
#server 192.168.88.100:80
$ yum -y install httpd
$ echo "pages from 88.100~" > /var/www/html/index.html
$ systemctl start httpd

#server 192.168.88.200:80
$ yum -y install httpd
$ echo "pages from 88.200~" > /var/www/html/index.html
$ systemctl start httpd

----------------
客户端测试
#多次请求www.new.com，可以看到得到的数据一次来自server1、一次来自server2
$ vim /etc/hosts
$ curl www.new.com
$ curl www.new.com




----------------
# nginx默认支持的负载均衡算法：轮询、加权轮询、ip_hash(ip绑定)
问题：ip_hash算法可以解决客户端与多台服务器重新建立连接的问题，能将同一个客户端的ip经过hash算法，固定分配到一个RS；但是其算法针对ip的前三位进行hash，即同一个网段会分配到同一个RS，造成负载不均。
解决：可以通过修改nginx源代码、重新编译安装方式改进（对客户端ip的四位进行hash）
实现：
$ tar -zxf nginx-1.13.8.tar.gz
$ cd nginx-1.13.8/src/http/modules/
$ vim ngx_http_upstream_ip_hash_module.c 
	static u_char ngx_http_upstream_ip_hash_pseudo_addr[4];  -80行
	iphp->addrlen = 4;      -124行
    iphp->addrlen = 4;      -137行
$ cd nginx-1.13.8
$ ./configure --user=nginx --group=nginx --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module  --with-stream   
$ make && make install
$ 配置nginx的ip_hash负载均衡
$ 启动nginx服务及后端apache服务
------
测试：切换不同的客户端，可以看到会被固定分配到不同的RS上

```



#### 安装rpm的nginx

```shell
#网络下载安装
$ rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
$ yum -y install nginx

#nginx参数的默认位置
$ whereis nginx
$ ls /usr/share/nginx
$ ls /etc/nginx

#启动nginx
$ systemctl start nginx

#功能搭建:跳转、加密、虚拟主机

```

