#### 一、基于ssh协议的数据同步（单向）

###### rsync命令  

```shell
-v, --verbose 详细模式输出 
-a, --archive 归档模式，表示以递归方式传输文件，并保持所有文件属性，等于-rlptgoD
-r, --recursive 对子目录以递归模式处理
-l, --links 保留软链结
-p, --perms 保持文件权限
-t, --times 保持文件时间信息
-g, --group 保持文件属组信息
-o, --owner 保持文件属主信息
-D, --devices 保持设备文件信息

-R, --relative 使用相对路径信息
-b, --backup 创建备份，也就是对于目的已经存在有同样的文件名时，将老的文件重新命名为~filename。可以使用--suffix选项来指定不同的备份文件前缀。
--backup-dir 将备份文件(如~filename)存放在在目录下。
-suffix=SUFFIX 定义备份文件前缀
-u, --update 仅仅进行更新，也就是跳过所有已经存在于DST，并且文件时间晚于要备份的文件。(不覆盖更新的文件)
-L, --copy-links 想对待常规文件一样处理软链结
--copy-unsafe-links 仅仅拷贝指向SRC路径目录树以外的链结
--safe-links 忽略指向SRC路径目录树以外的链结
-H, --hard-links 保留硬链结
-S, --sparse 对稀疏文件进行特殊处理以节省DST的空间
-n, --dry-run现实哪些文件将被传输
-W, --whole-file 拷贝文件，不进行增量检测
-q, --quiet 精简输出模式
-c, --checksum 打开校验开关，强制对文件传输进行校验
-z,--compress 压缩

```



###### 基准（数据）服务器

```shell
#创建要备份的数据目录、创建部分数据
$ mkdir /jizhun

#备份数据：同步到备份服务器上
#备份例1：将jizhun目录下面所有文件，到备份服务器
$ rsync -avz /jizhun/ root@备份服务器IP:/beifen
#备份例2：将jizhun目录及下面所有文件，到备份服务器
$ rsync -avz /jizhun root@备份服务器IP:/beifen
#备份例3：添加--delete进行强同步，将备份服务器上多余的删掉
$ rsync --delete -avz /jizhun root@备份服务器IP:/beifen

------------------
#默认使用ssh的密码验证模式、可以设置免密方式
$ ssh-keygen -t rsa -b 2048
#与对方指定的用户设置免密登录，此例为root
#若是其他用户需要在备份服务器上创建普通用户做接收数据
$ ssh-copy-id root@数据服务器IP

------------------
#创建专用用户去定时备份
$ useradd rsyncer
$ passwd rsyncer
$ setfacl -R -m u:rsyncer:rwx /jizhun

```

###### 备份服务器

```shell
#创建同步过来的数据，存放的目录
$ mkdir /beifen

#恢复数据：同步回数据服务器
#恢复例1：将beifen目录下面的数据，恢复到数据服务器
$ rsync -avz /beifen/ root@数据服务器IP:/jizhun:
#恢复例2：将beifen目录及下面所有的数据，恢复到数据服务器
$ rsync -avz /beifen root@数据服务器IP:/jizhun

----------------
#默认使用ssh的密码验证模式、可以设置免密方式
$ ssh-keygen -t rsa -b 2048
$ ssh-copy-id root@数据服务器IP

------------
#创建专用用户去接收数据
$ useradd reciever
$ passwd reciever
$ setfacl -R -m u:reciever:rwx /beifen
或：chown reciever.reciever /beifen

```



#### 二、rsync+inotifywait同步（单向实时）

```shell
#搭建inotify
$ yum -y install gcc gcc-c++
$ tar -zxf inotify-tools-3.14.tar.gz
$ cd inotify-tools-3.14
$ ./configure
$ make && make install 

#inotifywait命令   event
$ inotifywait -mrq -e 监听动作1，监听动作2  /监听目录 &
$ inotifywait -mrq -e create,delete /yuan &
#-m是始终保持事件监听状态；-r是递归查询目录；-q是只打印监控事件的信息
#监控动作：create，delete，modify，attrib

#执行脚本，用户登录时需要免密
$ vim bak.sh
#!/bin/bash
event1="inotifywait -mrq -e create,delete,modify /yuan"
action="rsync -avz --delete /yuan/ root@192.168.66.25:/mubiao"
$event1 | while read directory event file		#while判断是否接收到监控记录
do
	$action  &>  /dev/null
done

$ chmod +x bak.sh
$ ./bak.sh

#后台运行
$ 可采用ssh方式，进行两个服务器间的免密登录：
$ ./bak.sh &
$ jobs
$ fg job号，ctrl+c结束

```

