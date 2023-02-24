#### Redis安装

###### 服务器

```shell
#安装基础依赖，tcl(Tool Command Language)工具命令语言、运行redis命令
$ yum -y install gcc gcc-c++ tcl
#安装redis软件包
$ tar -zxvf redis-5.0.4.tar.gz
$ cd redis-5.0.4
$ make      #没有configure命令，已经生成了makefile文件，直接make即可
$ make test #测试安装环境，若多次运行失败也不影响安装
$ make install PREFIX=/usr/local/redis  #安装，prefix需大写

#复制配置文件
$ cd /usr/local/redis
$ cp -a 解压目录/redis-5.0.4/redis.conf .

#启动服务，需指定配置文件
$ /usr/local/redis/bin/redis-server /usr/local/redis/redis.conf
#关闭服务杀死相关进程
$ pkill redis  或：kill 进程号


#默认是前台运行、ctrl+C停止、修改配置文件重启
$ vim /usr/local/redis/redis.conf
	bind 本机IP地址       #绑定本地IP地址或回环地址
	daemonize yes        #改为后台daemon运行
	dir /usr/local/redis #指定数据存放目录./
	protected-mode no    #安全模式、需要密码连接
	requirepass 密码值    #设置密码
#重启服务
$ cd /usr/local/redis/
$ ./bin/redis-server redis.conf
$ ss -antp | grep :6379

```

###### 客户端

```shell
$ /usr/local/redis/bin/redis-cli -h 服务器IP -p 6379 -a 密码值
6379> set key值 数据    #存键值对
6379> get key值        #根据key值取数据

或：
$ /usr/local/redis/bin/redis-cli -h 服务器IP -p 6379
6379> set key值 数据    #存键值对
6379> auth 密码值
6379> set key值 数据    #存键值对
6379> get key值        #根据key值取数据

```



#### Redis持久化

```shell
#默认开启RDB方式持久化
$ vim /usr/local/redis/redis.conf
	#表示900 秒内如果至少有 1 个 key 的值变化，则保存
	save 900 1
	#表示300 秒内如果至少有 10 个 key 的值变化，则保存
	save 300 10
	#表示60 秒内如果至少有 10000 个 key 的值变化，则保存
	save 60 10000
	#文件保存位置、文件名默认是dump.rdb
	dir /usr/local/redis

#可以开启AOF方式持久化
$ vim /usr/local/redis/redis.conf
	#将no改为yes、打开aof持久化方式
	appendonly no
	#有写操作，就马上写入磁盘。效率最慢，但是最安全
	appendfsync always
	#默认，每秒钟写入磁盘一次
	appendfsync everysec
	#不进行AOF备份，将数据交给操作系统处理。最快，最不安全
	appendfsync no
	#文件保存位置、重启后产生文件名默认是appendonly.aof
	dir /usr/local/redis
	
$ pkill redis
$ /usr/local/redis/bin/redis-server /usr/local/redis/bin/redis.conf

```



#### Redis数据类型操作

```shell
#字符串（String）
#存储： set key value
127.0.0.1:6379> set username jimmy
#获取： get key
127.0.0.1:6379> get username
#删除： del key
127.0.0.1:6379> del username

#哈希（Hash）
#存储：hset key field value
#存储：hmset key field value field value
127.0.0.1:6379> hset user1 username lisi
127.0.0.1:6379> hset user1 password 123
127.0.0.1:6379> hmset user1 username lisi password 123
#hget key field: 获取指定的field对应的值
#hmget key field field...: 获取多个指定的field对应的值
#hgetall key：获取所有的field和value
127.0.0.1:6379> hget user1 username
127.0.0.1:6379> hgetall user1
#删除指定field： hdel key field
127.0.0.1:6379> hdel user1 username
#删除key： del key
127.0.0.1:6379> del username

#列表（List）
#lpush key value: 将元素加入列表左表
#rpush key value：将元素加入列表右边
127.0.0.1:6379> lpush mylist a      
127.0.0.1:6379> rpush mylist b      
#lrange key start end ：范围获取
#其中 0 表示列表的第一个元素， 1 表示列表的第二个元素，以此类推。 你也可以使用负数下标，以 -1 表示列表的最后一个元素， -2 表示列表的倒数第二个元素;
127.0.0.1:6379> lrange mylist 0 -1 
#lpop删除列表最左侧元素、并返回
#rpop删除列表最左侧元素、并返回
127.0.0.1:6379> lpop mylist          
127.0.0.1:6379> rpop mylist

#集合（set）
#存储：sadd key value
127.0.0.1:6379> sadd myset a
127.0.0.1:6379> sadd myset a  #重复了返回0
#获取：smembers key:获取set集合中所有元素
127.0.0.1:6379> smembers myset
#删除：srem key value:删除set集合中的某个元素
127.0.0.1:6379> srem myset a

#有序集合（zset）
#存储：zadd key score value
127.0.0.1:6379> zadd mysort 60 zhangsan
127.0.0.1:6379> zadd mysort 50 lisi
#获取：zrange key start end [withscores]
#获取：zrange mysort 0 -1 withscores
127.0.0.1:6379> zrange mysort 0 -1   
127.0.0.1:6379> zrange mysort 0 -1  withscores
#删除：zrem key value
127.0.0.1:6379> zrem mysort lisi

#通用命令
keys *  ：获取所有的键
type key：获取键对应的value的类型
del key：删除指定的key-value
exists key：判断某个key值是否已经存在


问题：
mysql数据：
	id  name sex   address
    1    zs   0     beijing        1:[zs,0,beijng]
    2    ls   1     shanghai       1:{name:zs,sex:0,address:beijing}
```

————————————————————————————



#### Redis主从配置

###### 主服务器：

```shell
#安装基础依赖
$ yum -y install gcc gcc-c++ tcl
#安装redis软件包
$ tar -zxvf redis-5.0.4.tar.gz
$ cd redis-5.0.4
$ make      #没有configure命令，已经生成了makefile文件，直接make即可
$ make PREFIX=/usr/local/redis install
#复制配置文件
$ cd /usr/local/redis
$ cp 存放路径/redis-5.0.4/redis.conf .
#修改配置文件
$ vim /usr/local/redis/redis.conf
	bind 本机IP地址       #绑定本地IP地址或回环地址
	port 6379
	pidfile /var/run/redis_6379.pid
	daemonize yes        #改为后台daemon运行
	dir /usr/local/redis #数据存放目录
	appendonly yes       #打开AOF模式
	protected-mode no    #安全模块、需要密码登录
	requirepass 密码值    #设置连接密码
$ /usr/local/redis/bin/redis-server /usr/local/redis/redis.conf
$ ss -antp | grep :6379

```

###### 从服务器：

```shell
#安装基础依赖
$ yum -y install gcc gcc-c++ tcl
#安装redis软件包
$ tar -zxvf redis-5.0.4.tar.gz
$ cd redis-5.0.4
$ make      #没有configure命令，已经生成了makefile文件，直接make即可
$ make PREFIX=/usr/local/redis install
#复制配置文件
$ cd /usr/local/redis
$ cp 存放路径/redis-5.0.4/redis.conf .
#修改配置文件
$ vim /usr/local/redis/redis.conf
	bind 本机IP地址      #绑定本地IP地址或回环地址
	port 6379
	pidfile /var/run/redis_6379.pid
	daemonize yes       #改为后台daemon运行
	dir /usr/local/redis
	appendonly yes       #打开AOF模式
	protected-mode no   #建议关闭安全模块、会造成数据同步的问题
	requirepass 密码值   #连接时需要密码
	
	replicaof 主服务器IP 主服务器port
	masterauth 主服务器连接密码
$ /usr/local/redis/bin/redis-server /usr/local/redis/redis.conf
$ ss -antp | grep :6379

```

###### 验证主从结构：

```shell
#连接上主服务器、进行存数据操作
$ ln -s /usr/local/redis/bin/* /usr/local/bin/
$ redis-cli -h 主服务器IP -p 6379 -a 密码
	6379> set key值 数据
	
#连接上从服务器、进行取数据操作
$ ln -s /usr/local/redis/bin/* /usr/local/bin/
$ redis-cli -h 从服务器IP -p 6379 -a 密码
	6379> get key值
	
```

——————————————————

#### Redis集群

###### 3个节点，即每个虚拟机搭建2个redis实例

```shell
#安装redis服务
$ yum -y install gcc gcc-c++ tcl
$ tar -zxvf redis-5.0.4.tar.gz
$ cd redis-5.0.4
$ make      
$ make test 
$ make PREFIX=/usr/local/redis install

#创建存放2个redis实例的目录
$ mkdir -p /data/{6378,6379}

#复制配置文件
$ cp -a 解压目录/redis-3.2.12/redis.conf /data/6378
$ cp -a 解压目录/redis-3.2.12/redis.conf /data/6379
$ vim /data/6378/redis.conf
	bind IP地址
	port 6378
	protected-mode no
	
	daemonize yes
	pidfile /data/6378/redis.pid
	logfile /data/6378/redis.log
	
	appendonly yes
	dir /data/6378  
	
	cluster-enabled yes
	cluster-config-file nodes.conf
	cluster-node-timeout 15000
		
$ vim /data/6379
	bind IP地址
	port 6379
	daemonize yes
	pidfile /data/6379/redis.pid
	logfile /data/6379/redis.log
	dir /data/6379
	appendonly yes
	protected-mode no   
	cluster-enabled yes
	cluster-config-file nodes.conf
	cluster-node-timeout 5000
	

#启动redis进程
$ ln -s /usr/local/redis/bin/* /usr/local/bin
$ redis-server /data/6378/redis.conf
$ redis-server /data/6379/redis.conf

#连接测试
$ redis-cli -p 6378
$ redis-cli -p 6379
```



###### 创建redis集群

```shell
#创建3主3从的集群
$ ln -s /usr/local/redis/bin/*  /usr/local/bin
$ redis-cli --cluster create --cluster-replicas 1 192.168.66.24:6378 192.168.66.24:6379 192.168.66.25:6378 192.168.66.25:6379 192.168.66.13:6378 192.168.66.13:6379 
#其中， - create：创建一个新的集群 - replicas 1 ：replicas参数指定集群中每个主节点配备几个从节点，这里设置为1

#连接测试
#连接任意一个节点：（-c通过集群连接） 
$ redis-cli -c -p port -h IP地址
#写入key-value值,以字符串类型为例
6379> set name cluster
#查看slot和节点的对应关系 
6379> cluster slots 
#查看key对应的slot，根据上个命令slot对应的机器，可以推出该key存在的机器
6379> cluster keyslot key
#查看集群里的节点信息
6379> cluster nodes

#查看集群中所有数据
$ redis-cli -c --cluster call 192.168.66.24:6378 keys \*

```



