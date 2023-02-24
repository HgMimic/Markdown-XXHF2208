#### 一、基本功能搭建（服务器+ 客户机）

###### 	服务器端

```shell
#关闭使用网卡自带的dhcp服务功能

#安装软件包
$ yum -y install dhcp
#生成配置文件
$ cp -a /usr/share/doc/dhcp-4.*.*/dhcpd.conf.sample  /etc/dhcp/dhcpd.conf
#修改配置文件
$ vim /etc/dhcp/dhcpd.conf
	subnet 192.168.66.0 netmask 255.255.255.0｛
		#设置地址范围（必填）
		range  192.168.66.3 192.168.66.254; 
        #设置DNS的地址
		option domain-name-servers 8.8.8.8; 
		#设置DNS的域名
		option domain-name "kernel.com";
        #设置网关地址
		option routers  192.168.66.1; 
        #设置广播地址
		option broadcast-address 192.168.66.255; 
		#设置租约时间
		default-lease-time 600;             
		max-lease-time 7200;
	｝
#重启服务
$ systemctl start dhcpd
#验证服务开启状态
$ ss -antup | grep dhcp   #查看端口是否开启
$ ps aux | grep dhcp      #查看进程是否开启

```

###### 	客户端

```shell
#和dhcp服务器使用同一个虚拟网卡

#设置网卡、将获取IP地址的方式设置为dhcp
$ vim  /etc/sysconfig/network-scripts/ifcfg-eth0
	BOOTPROTO=dhcp
	去掉IPADDR、NETWORK等	
# 重启网卡、查看获取的IP地址（已获取了一个IP，想重新获取也可以重启网卡）
$ systemctl restart network
或：ifdown ens33;ifup ens33;

#查看ip等资源是否获取到
$ ip addr                 #查看是否获取到ip，且在分配的地址池里
$ route -n                #查看是否获取到网关
$ cat /etc/resolv.conf    #查看是否获取到dns

```



#### 二、保留地址实验（服务器+ 客户机）

###### 服务器端

```shell
$ vim /etc/dhcp/dhcpd.conf
	#需要有一个跟使用网卡同网段的地址池
	subnet 192.168.66.0 netmask 255.255.255.0｛
		#设置地址范围（必填）
		range  192.168.66.3 192.168.66.254; 
        #设置网关地址
		option routers  192.168.66.1; 
	｝
	
	host fantasia｛
		#客户机的mac地址
		hardware ethernet mac地址；
        #固定分配给客户机的ip地址
		fixed-address IP地址；		   
    ｝
    host fantasia1｛
		#客户机的mac地址
		hardware ethernet mac地址；
        #固定分配给客户机的ip地址
		fixed-address IP地址；		   
    ｝

#注：设置固定IP时，一定有一个同网络的subnet地址池分配
#注：该固定IP可以是地址池之外的IP地址
#注：若是要给多个mac地址固定分IP，需要些多个host块、且后面的名字不相同

```

###### 客户端

```shell
#和dhcp服务器使用同一个虚拟网卡

#设置网卡、将获取IP地址的方式设置为dhcp
$ vim  /etc/sysconfig/network-scripts/ifcfg-eth0
	BOOTPROTO=dhcp
	去掉IPADDR、NETWORK等
# 重启网卡、查看获取的IP地址（已获取了一个IP，想重新获取也可以重启网卡）
$ systemctl restart network
或：ifdown ens33;ifup ens33;

#查看ip是否在地址池范围里
$ ip addr

```



#### 三、超级作用域实验（服务器和路由器+ 客户机1+客户机2）

###### 网络配置

```shell
dhcp服务器：vmnet1
	ens33 ：192.168.66.100
	ens33:0 :192.168.77.100
客户机1：vmnet1
	ens33 ： 自动获取
客户机2：vmnet1
	ens33 ： 自动获取
```

###### 	DHCP服务器和路由器

```shell
#关闭使用网卡自带的dhcp服务功能

#为当前ens33网卡添加子网卡、设置该子网卡
$ cd /etc/sysconfig/network-scripts
$ cp -a ifcfg-ens33 ifcfg-ens33:0
$ vim ifcfg-ens33
	BOOTPROTO=static
	IPADDR=192.168.66.100
	PREFIX=24
$ vim ifcfg-ens33:0
	NAME=ens33:0
	DEVICE=ens33:0
	BOOTPROTO=static
	IPADDR=192.168.77.100
	PREFIX=24
$ systemctl restart network

#配置dhcp服务（注释掉其他实验地址池的设置、保留地址的设置）
#分配规则是先把第一个地址池的ip分配完、再分配第二个地址池
$ vim /etc/dhcp/dhcpd.conf
	shared-network public ｛
		subnet 192.168.66.0 netmask 255.255.255.0｛
			range 192.168.66.200 192.168.66.200;
		｝
		subnet 192.168.77.0 netmask 255.255.255.0｛
			range  192.168.77.110 192.168.77.120;
		｝
	｝
$ systemctl restart dhcpd

--------------------------------------------
#若使获取的两个网段ip的客户机相互ping通
#1.将dhcp服务器作为模拟路由，多网卡已设好，开启路由转发
$ vim /etc/sysctl.conf
	net.ipv4.ip_forward=1
#验证开启成功
$ sysctl -p    

#2.给两个客户机添加网关，通过设置dhcp服务使其自动获取
#dhcpd配置里把shared-network中subnet里的注释的option router打开
$ vim /etc/dhcp/dhcpd.conf
	shared-network public ｛
		subnet 192.168.66.0 netmask 255.255.255.0｛
			option routers 192.168.66.100;     #dhcp服务器ip
			range 192.168.66.200 192.168.66.200;
		｝
		subnet 192.168.77.0 netmask 255.255.255.0｛
			option  routers  192.168.77.100;    #dhcp服务器ip
			range  192.168.77.110 192.168.77.120;
		｝
	｝
$ systemctl restart dhcpd

#3.两个不同网段的客户机可以相互ping通

```

###### 两台客户机重启网卡

```shell
#和dhcp服务器使用同一个虚拟网卡

#设置网卡、将获取IP地址的方式设置为dhcp
$ vim  /etc/sysconfig/network-scripts/ifcfg-ens33
	BOOTPROTO=dhcp
	去掉IPADDR、NETWORK等
# 重启网卡、查看获取的IP地址（已获取了一个IP，想重新获取也可以重启网卡）
$ systemctl restart network
或：ifdown ens33;ifup ens33;

#查看ip是否在地址池范围里
$ ip addr

```



#### 四、DHCP中继实验（DHCP服务器+DHCP中继和路由器+客户机）

###### 网络设置

```shell
DHCP服务器：vmnet1
	ens33 ： 192.168.66.77，网关为中继服务器上同网段的IP
DHCP中继器：
	ens33 ：vmnet1, 192.168.66.100
	ens34 ：vmnet2， 192.168.88.100
客户机：vmnet2
	ens33 : 自动获取
```

###### DHCP服务器

```shell
#关闭所有使用网卡自带的dhcp服务功能

#配置网卡信息
$ vim /etc/sysconfig/network-scripts/ifcfg-ens33
	BOOTPROTO=static
	IPADDR=192.168.66.77
	PREFIX=24
	GATEWAY=192.168.66.100   #设置成中继服务器的IP
$ systemctl restart network
 
#修改配置文件
$ vim /etc/dhcp/dhcpd.conf
	subnet 192.168.66.0 netmask 255.255.255.0｛
		range 192.168.66.110 192.168.66.120;
	｝
	subnet 192.168.88.0 netmask 255.255.255.0｛
		range  192.168.88.110 192.168.88.120;
	｝
$ systemctl restart dhcpd

```

###### DHCP中继服务器

```shell
#配置两个网卡、配置不同网段的IP地址，不用开路由转发
$ vim /etc/sysconfig/network-scripts/ifcfg-ens33
	BOOTPROTO=static
	IPADDR=192.168.66.100
	PREFIX=24
$ vim /etc/sysconfig/network-scripts/ifcfg-ens34
	BOOTPROTO=static
	IPADDR=192.168.88.100
	PREFIX=24
$ systemctl restart network

#安装dhcp软件
$ yum -y install dhcp
#指定作为中继的DHCP服务器IP
$ dhcrelay DHCP服务器IP
#查看开启的结果
$ ss -tulnp | grep dhcrelay  


-------------------------------
#若使两个客户机（vmnet1和vmnet2自动获取ip的主机）互相通信
#步骤同上个实验：中继器作为模拟路由、在dhcp服务中分别为2个subnet设置中继器ip做为网关

```

###### 客户机

```shell
#和dhcp服务器的外网使用同一个虚拟网卡，关掉网卡自带的dhcp服务器
#设置网卡、将获取IP地址的方式设置为dhcp
$ vim  /etc/sysconfig/network-scripts/ifcfg-ens33
	BOOTPROTO=dhcp
	去掉IPADDR、NETWORK等
# 重启网卡、查看获取的IP地址（已获取了一个IP，想重新获取也可以重启网卡）
$ systemctl restart network
或：ifdown ens33;ifup ens33;
#查看ip是否在地址池范围里
$ ip addr

```

