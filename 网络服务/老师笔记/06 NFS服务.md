#### 一、基本功能搭建

###### 服务器端

```shell
$ yum -y install rpcbind nfs-utils

#/etc/export可以写多行，每行当做一个客户端挂载设置
#每行的网段和后面括号的权限要紧挨着、不能有空格；否则挂载后是只读文件系统
$ vim /etc/exports
	#设置只读权限
    共享目录1  192.168.66.0/24(ro,async,root_squash)  
    #可写、将客户端登录的用户在服务器映射为匿名用户
    共享目录2  192.168.66.0/24(rw,async,root_squash) 
    #可写、将客户端登录的用户在服务器保留root身份
    共享目录3  192.168.66.0/24(rw,async,no_root_squash) 
    #可写、将客户端登录的用户在服务器映射为指定的用户
    共享目录4  192.168.66.0/24(rw,async,all_squash,anonuid=xx,anongid=xx) 
    
$ mkdir -p 共享目录n
$ echo "123" >>共享目录n/index.html

$ systemctl restart rpcbind   #不用每次引导、第一次启动重启、慢时重启
$ systemctl restart nfs

```

###### 客户端（可设多个）

```shell
$ yum -y install rpcbind nfs-utils

#查看服务器端的分享目录
$ showmount -e 服务器端ip

#挂载一个分享目录
$ mkdir ${挂载点}
$ mount  -t  nfs  serverId:${共享目录}  ${挂载点}

#查看挂载情况
$ df -h

#进入挂载点，查看分享数据
cd ${挂载点}
cat index.html    #慢的话，可以执行service rpc.bind重新引导下rpc

#可以在该挂载点里创建目录或文件，并写入数据。该数据会在多个客户端即服务器端共享。
```

![1648781544545](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\1648781544545.png)

#### 二、共享网站资源

###### 服务器

```shell
$ yum -y install rpcbind nfs-utils

$ vim /etc/exports
    /shares  192.168.66.0/24 (rw,async,no_root_squash) 
    
$ mkdir /shares
$ echo "A beautiful page~" >> /shares/index.html

$ systemctl restart rpcbind
$ systemctl restart nfs

```

###### 客户端1、客户端2

```shell
$ mount -t nfs ${nfsIP}:/shares /var/www/html

$ service httpd start
$ curl localhost

```

