#### 一、DNS基本功能搭建（服务器+测试机）

##### 	服务器配置

```shell
#安装软件bind
$ yum -y install bind

#配置主配置文件(注：每行的分号)
$ vim /etc/named.conf
	#监听的连接服务器网卡：
	listen-on port 53 {any;}
	#监听的客户端的请求地址，如指定网段：20.20.20.x/24;
	allow-query {any;}
	
#配置区域配置文件（注：备份文件、只留一个正向和反向配置块）	
$ vim /etc/named.rfc1912.zones
	#正向区域：
		zone "要解析成的域名，如hongfu.com" IN {
			type master；
			file "正向的数据配置文件名";
			allow-update {none;};
		}
	#反向区域：
		zone "解析网段的倒序(如：66.168.192).in-addr.arpa" IN {
			type master；
			file "反向的数据配置文件名"；
			allow-update {none;};
		}
		
#配置数据文件
$ cd /var/named/
#修改了默认的数据文件名，需要cp -a创建对应的文件，若没改跳过
$ cp -a named.localhost 正向的数据配置文件名
$ cp -a named.loopback  反向的数据配置文件名	
#配置数据文件
$ vim 正向的数据配置文件名  #注：写域名最后加上根域
	$TTL 1D
	@       IN SOA  要解析成的域名.(如hongfu.com.) rname.invalid. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        	NS      dns.要解析成的域名.   #配置dns服务器的域名
	dns     A       192.168.66.74       #配置正向解析记录
	www     A       192.168.66.74 
	
	
	
$ vim 反向的数据配置文件名  #注：写域名最后加上根域
	$TTL 1D
	@       IN SOA  要解析成的域名. rname.invalid. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        	NS      dns.要解析成的域名.   #配置dns服务器的域名
	74      PTR     dns.要解析成的域名.   #配置反向解析记录，只输入ip最后一位
	
#启动dns服务
$ systemctl start named

```

##### 	测试机配置

```shell
# 测试机（服务器本机或其他机器）在网卡配置中添加DNS1
$ vim  /etc/sysconfig/network-scripts/ifcfg-ens33
	DNS1 = dns服务器ip
$ systemctl restart network
#注意：没有设/etc/hosts,并且配置的dns服务器在/etc/resolv.conf生效
$ nslookup 要解析的域名

```





#### 二、DNS主从服务搭建（主服务器+从服务器+测试机）

##### 	主服务器配置

```shell
$ yum -y install bind
$ vim /etc/named.conf
	listen-on port 53 {any;}
	allow-query {any;}     
$ vim /etc/named.rfc1912.zones
	#正向区域：
		zone "要解析成的域名" IN {
			type master；
			file "正向的数据配置文件名";
			#添加将数据同步到从服务的配置
			allow-transfer {从服务器ip;};
			#添加实时同步配置
			allow-update {从服务器ip;};
        	also-notify {从服务器ip;};
		}
	#反向区域：
		zone "解析网段的倒序.in-addr.arpa" IN {
			type master；
			file "反向的数据配置文件名"；
			#添加将数据同步到从服务的配置
			allow-transfer {从服务器ip;};
			#添加实时同步配置
			allow-update {从服务器ip;};
        	also-notify {从服务器ip;};
		}
$ cd /var/named  
#数据配置文件同上
```

##### 	从服务器配置

```shell
$ yum -y install bind
$ vim /etc/named.conf
	listen-on port 53 {any;}
	allow-query {any;}
$ vim /etc/named.rfc1912.zones
	#正向区域：
		zone "要解析成的域名" IN {
			type slave；
			masters { 主服务器ip; };
			file "slaves/正向的数据配置文件名(和master名相同)";
			masterfile-format text;
		}
	#反向区域：
		zone "解析网段的倒序.in-addr.arpa" IN {
			type slave；
			masters { 主服务器ip; };
			file "slaves/反向的数据配置文件名(和master名相同)";
			masterfile-format text;
		}
#无需配置数据文件，启动服务自动同步到指定文件中！

```

##### 	测试机

```shell
#修改网卡配置，添加DNS1=从服务器ip
$ vim  /etc/sysconfig/network-scripts/ifcfg-ens33
	DNS1 = 从dns服务器ip
$ systemctl restart network

#1.测试master已有数据记录的解析
#查看从服务器的数据文件
$ cd /var/named/slaves
#测试正向解析
$ nslookup 要解析的域名

#2.测试master添加新数据的同步并解析
#master上添加新数据、同时修改数据文件的序列号
$ vim 正向的数据配置文件名 
	$TTL 1D
	@       IN SOA  要解析成的域名.(如hongfu.com.) rname.invalid. 	(
                                        1       ; serial 
                                   #序列号每次数据修改都需要增加
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        	NS      dns.要解析成的域名.   
	dns     A       192.168.66.75    
    www     A       192.168.66.75  #添加或修改一条数据
#重启named服务
$ systemctl restart named

#从服务器上不需要做任何修改，查看数据文件可以数据被同步过来了
#客户机上能正常解析出新增或更改的域名
$ nslookup 要解析的域名

```





#### 三、DNS缓存服务搭建（主服务器+缓存服务器+测试机）

##### 	主服务器

```shell
#同主从实验中的主服务器配置
```

##### 	缓存服务器

```shell
#安装缓存软件
$ yum -y install dnsmasq
#配置缓存
$ vim /etc/dnsmasq.conf
	domain=要解析的域名
	server=主dns服务器ip
	cache-size=15000
#启动服务
$ systemctl start dnsmasq 

1.缓存服务器拿客户机测；2.服务默认安装并开启，C6改完配置重启；C7生效 pkill 进程名，再启动

```

##### 	测试机

```shell
#修改网卡配置，添加DNS1=缓存服务器ip
$ vim  /etc/sysconfig/network-scripts/ifcfg-ens33
	DNS1 = 缓存dns服务器ip
$ systemctl restart network
#关闭主服务器，仍能解析主服务器解析过的域名,但提示不权威，因为使用的缓存
$ nslookup 要解析的域名

```





#### 四、智能DNS搭建(DNS服务+内网测试机+外网测试机)

##### 实验环境

```shell
DNS服务器：
	ens33（vmnet1）：192.168.66.75
	ens34（vmnet2）：192.168.99.75
内网测试机：
	ens33（vmnet1）：192.168.66.xx 
	网关和DNS1都设置为DNS服务器的内网IP（192.168.66.75）
外网测试机：
	ens34（vmnet2）：192.168.99.xx
	网关和DNS1都设置为DNS服务器的外网IP（192.168.99.75）
	
----------------------------	
网站服务器：
	ens33（vmnet1）：192.168.66.77
	ens34（vmnet2）：192.168.99.77
	
```

##### 服务器配置

```shell
#按上面的实验环境，配置相应的物理网卡和网卡信息

#安装dns软件包
yum -y install bind
#修改主配置文件
vim /etc/named.conf
	view lan{
		match-clients{192.168.66.0/24;};
		zone "." IN {
			type hint;
			file "named.ca";
		};
		include "/etc/lan.zones";
	};
	view wan{
		match-clients{any;};
		zone "." IN {
			type hint;
			file "named.ca";
		};
		include "/etc/wan.zones";
	};
	#include "/etc/named.rfc1912.zones"; #注释掉默认的区域配置文件

#配置区域文件、配置同上
$ cp -a /etc/named.rfc1912.zones /etc/lan.zones
$ cp -a /etc/named.rfc1912.zones /etc/wan.zones
$ vim /etc/lan.zones
	zone "hongfu.com" IN {
        type master;
        file "hongfu.zheng.lan";
        allow-update { none; };
	};
	zone "66.168.192.in-addr.arpa" IN {
        type master;
        file "hongfu.fan.lan";
        allow-update { none; };
	};
$ vim /etc/wan.zones
	zone "hongfu.com" IN {
        type master;
        file "hongfu.zheng.wan";
        allow-update { none; };
	};
	zone "99.168.192.in-addr.arpa" IN {
        type master;
        file "hongfu.fan.wan";
        allow-update { none; };
	};

#配置数据文件
$ cd /var/named
$ cp -a named.localhost hongfu.zheng.lan
$ cp -a named.loopback hongfu.fan.lan
$ cp -a named.localhost hongfu.zheng.wan
$ cp -a named.loopback hongfu.fan.wan
$ vim hongfu.zheng.lan
	$TTL 1D
	@       IN SOA  hongfu.com. rname.invalid. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        	NS      dns.hongfu.com.
	www     A       192.168.66.77
	dns     A       192.168.66.75
$ vim hongfu.fan.lan
	$TTL 1D
	@       IN SOA  hongfu.com. rname.invalid. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        	NS      dns.hongfu.com.
	75      PTR     dns.hongfu.com.
	77      PTR     www.hongfu.com.
$ vim hongfu.zheng.wan
	$TTL 1D
	@       IN SOA  hongfu.com. rname.invalid. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        	NS      dns.hongfu.com.
	www     A       192.168.99.77
	dns     A       192.168.99.75
$ vim hongfu.fan.wan
	$TTL 1D
	@       IN SOA  hongfu.com. rname.invalid. (
                                        0       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        	NS      dns.hongfu.com.
	75      PTR     dns.hongfu.com.
	77      PTR     www.hongfu.com.

#重启服务
$ systemctl restart named
$ ss -antp | grep :53
```

##### 内网测试机

```shell
#按上面的实验环境，配置相应的物理网卡（vmnet1）和网卡信息

#配置网卡信息
$ vim /etc/sysconfig/network-scripts/ifcfg-eth0
	IPADDR=192.168.66.xx
	GATEWAY=192.168.66.75
	DNS1=192.168.66.75
$ service network restart

#测试DNS解析功能
$ nslookup 配置的域名

```

##### 外网测试机

```shell
按上面的实验环境，配置相应的物理网卡（vmnet3）和网卡信息

#配置网卡信息
$ vim /etc/sysconfig/network-scripts/ifcfg-eth0
	IPADDR=192.168.99.xx
	GATEWAY=192.168.99.75
	DNS1=192.168.99.75
$ service network restart

#测试DNS解析功能
$ nslookup 配置的域名

```

——————————————————

##### 网站服务器

```shell
#按上面的实验环境，配置相应的物理网卡和网卡信息

#安装httpd服务
$ yum -y install httpd
$ systemctl start httpd
$ ss -antp | grep :80
$ cd /var/www/html   #写测试界面
	echo "test pages~" > index.html
$ curl localhost    #模拟浏览器访问网站

```

