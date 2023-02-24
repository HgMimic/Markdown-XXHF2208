#### 一、搭建本地yum源

```shell
1.虚拟机连接上光盘文件，并勾选“已连接”；
2.创建挂载点
3.执行mount挂载命令，或在/etc/fstab中添加挂载记录
4.配置/etc/yum.repos.d下的repo源
  $ vim /etc/yum.repos.d/CentOS-Media.repo
  	[c7-media]
	name=CentOS-$releasever - Media
	baseurl=file:///mnt/cdrom
	gpgcheck=1
	enabled=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
5.测试：yum -y install gcc gcc-c++   

```



#### 二、搭建局域网yum源

###### 服务器

```shell
#CentOS7系统
$ yum -y install vsftpd
$ cd /var/ftp/pub
$ cp -a /mnt/cdrom/* .
$ systemctl restart vsftpd
$ ss -antp | grep :21

#CentOS6系统
$ yum -y install vsftpd
$ cd /var/ftp/pub
挂载第一张光盘，将里面的东西复制到vsftpd的共享路径
$ mount -t iso9660 /dev/sr0 /mnt/cdrom
$ cp -a /mnt/cdrom/* /var/ftp/pub/c6
$ eject|umount /mnt/cdrom   #弹出第一张光盘
挂载第二张光盘，将里面的东西复制到vsftpd的共享路径
$ cd /var/ftp/pub/c6
$ mount -t iso9660 /dev/sr0 /mnt/cdrom
$ cp -a /mnt/cdrom/Packages/* /var/ftp/pub/c6/Packages
重新挂载第一张盘，安装createrepo，重构两张盘之间的依赖关系
$ yum -y install createrepo
$ createrepo /var/ftp/pub/c6
启动或检查vsftpd服务有没开启：
$ service vsftpd restart
$ ss -antp | grep :21
测试：
$ yum -y install libevent-devel

```

###### 客户端

```shell
$ vim /etc/yum.repos.d/CentOS-Media.repo
  	[c7-media]
	name=CentOS-$releasever - Media
	baseurl=ftp://服务器IP/pub/C?
	gpgcheck=1
	enabled=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
	
$ make clean all
$ makecache

#客户端为了能正常运行yum源，需要服务器一直打开这vsftpd服务
```



#### 三、搭建网络yum源

```shell
#阿里源：https://mirrors.aliyun.com/repo/
#网易源：http://mirrors.163.com/.help/centos.html

1.在网站地址栏输入上面的网络yum源地址
2.下载对应系统的系统源和扩展源
3.将下载的源文件拖进虚拟机，放在/etc/yum.repos.d目录下
或者：
#wget下载文件，-O将wget下载的文件，保存到指定位置时，保存时可以重新起一个名字，或者直接写一个要保存的路径，这样还用原来的文件名
$ wget -O /etc/yum.repos.d/CentOS-7.repo https://mirrors.aliyun.com/repo/Centos-7.repo
$ wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

4.打开第二张网卡（用NAT网络连接的）
5.下载测试
$ yum -y install htop

----------------
#Centos6版本的官方和上面常用网络yum不再维护
CentOs6.x yum源停止维护，安装yum源
因为官方对CentOs6的版本已经不维护了，所以用户无法再从其他国内yum源进行下载，但是官方将数据有些搬移到 http://vault.centos.org/，（提醒：个别还是源没有）因此我们可以通过http://vault.centos.org/
#但如下网络yum可用，将网页内容复制到/etc/yum.repos.d下面的.repo文件：
http://github.itzmx.com/1265578519/mirrors/master/CentOS/CentOS6-Base-itzmx.repo
http://github.itzmx.com/1265578519/mirrors/master/EPEL/epel.repo

#查询并下载rpm包的网址：
http://rpmfind.net/linux/rpm2html/search.php?query=htop(x86-64)

```



#### 四、提取yum源记录

```shell
#配置网络yum源（步骤同三）
#打开yum缓存记录,修改完文件自动生效
$ vim /etc/yum.conf
	[main]
	cachedir=/yum  #设置安装rpm包的缓存位置
	keepcache=1    #1是安装rpm包后，不清除对应的软件包；0是清除
	
#创建缓存目录
$ mkdir /yum
$ yum clean all
$ yum makecache
$ yum -y install htop
$ tree /yum   #查看下载的rpm在缓存中的位置

--------------------------------

#客户端：
方式一：重新做一下yum缓存
	$ yum clean all
	$ yum makecache   #把服务器的软件包拉到本地，创建缓存
	$ vim /etc/yum.repos.d/CentOS-Media.repo
		gpgcheck=0
	$ yum -y install htop
	
方法二：直接连接ftp服务
	$ ftp vsftpd服务器IP
	ftp> get htop-2.....rpm
	$ yum -y install htop-2.....rpm
	
```

