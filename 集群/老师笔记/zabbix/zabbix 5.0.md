# Zabbix Server 5.0 LTS 版本

## 一、环境准备

1. 操作系统：CentOS 7.X
2. Zabbix版本：5.0 LTS
3. 网络情况：能连接互联网
4. 关闭SELinux和firewalld防护

## 二、软件配置

### 1. 安装基础web环境

1. 调试网络环境，连通互联网

   ```shell
   $ ping www.baidu.com
   PING www.a.shifen.com (110.242.68.3) 56(84) bytes of data.
   64 bytes from 110.242.68.3 (110.242.68.3): icmp_seq=1 ttl=128 time=12.2 ms
   64 bytes from 110.242.68.3 (110.242.68.3): icmp_seq=2 ttl=128 time=12.3 ms
   64 bytes from 110.242.68.3 (110.242.68.3): icmp_seq=3 ttl=128 time=12.2 ms
   ^C
   --- www.a.shifen.com ping statistics ---
   4 packets transmitted, 3 received, 25% packet loss, time 3007ms
   rtt min/avg/max/mdev = 12.218/12.273/12.378/0.116 ms
   ```

2. 下载网络yum仓库

   注意：先将原来的配置文件备份到其它目录下

   ```shell
   $ wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
   $ yum clean all
   #或选择官方自带yum仓库，切记不要安装epel源，会和zabbix源造成冲突。
   ```

3. 安装基础web环境所需软件包

   ```shell
   $ yum -y install net-snmp-devel OpenIPMI-devel httpd openssl-devel java lrzsz fping-devel libcurl-devel perl-DBI pcre-devel libxml2 libxml2-devel mysql-devel gcc php php-bcmath php-gd php-xml php-mbstring php-ldap php-mysql.x86_64 php-pear php-xmlrpc net-tools mariadb mariadb-server
   ```

4. 配置mariadb数据库并启动

   ```shell
   $ systemctl enable mariadb
   $ systemctl start mariadb
   
   #——————————————————————————————————————
   $ mysql_secure_installation
   
   NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
         SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!
   
   In order to log into MariaDB to secure it, we'll need the current
   password for the root user.  If you've just installed MariaDB, and
   you haven't set the root password yet, the password will be blank,
   so you should just press enter here.
   
   Enter current password for root (enter for none): 
   OK, successfully used password, moving on...
   #填写旧密码（新装的一般都没有密码，直接回车）
   Setting the root password ensures that nobody can log into the MariaDB
   root user without the proper authorisation.
   
   Set root password? [Y/n] y
   #是否为root设置密码
   New password: 
   Re-enter new password: 
   Password updated successfully!
   Reloading privilege tables..
    ... Success!
   
   
   By default, a MariaDB installation has an anonymous user, allowing anyone
   to log into MariaDB without having to have a user account created for
   them.  This is intended only for testing, and to make the installation
   go a bit smoother.  You should remove them before moving into a
   production environment.
   
   Remove anonymous users? [Y/n] y
    ... Success!
   #是否关闭匿名访问
   Normally, root should only be allowed to connect from 'localhost'.  This
   ensures that someone cannot guess at the root password from the network.
   
   Disallow root login remotely? [Y/n] y
    ... Success!
   #是否禁止root远程登陆
   By default, MariaDB comes with a database named 'test' that anyone can
   access.  This is also intended only for testing, and should be removed
   before moving into a production environment.
   
   Remove test database and access to it? [Y/n] y
    - Dropping test database...
    ... Success!
    - Removing privileges on test database...
    ... Success!
   #是否移除test库
   Reloading the privilege tables will ensure that all changes made so far
   will take effect immediately.
   
   Reload privilege tables now? [Y/n] y
    ... Success!
   #是否重新初始化授权表
   Cleaning up...
   
   All done!  If you've completed all of the above steps, your MariaDB
   installation should now be secure.
   
   Thanks for using MariaDB!
   
   #——————————————————————————————————————
   $ mysql -uroot -p123456
   Welcome to the MariaDB monitor.  Commands end with ; or \g.
   Your MariaDB connection id is 10
   Server version: 5.5.68-MariaDB MariaDB Server
   
   Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.
   
   Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
   
   MariaDB [(none)]>
   ```

### 2. 安装zabbix服务器端

1. 下载并安装zabbix仓库，并安装zabbix服务器端和客户端

   ```shell
   $ rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
   $ yum -y install zabbix-server-mysql zabbix-agent
   #切记不要安装epel源，会和zabbix源造成冲突。
   ```

2. 安装并修改zabbix frontend仓库，然后安装zabbix前端软件包

   ```shell
   $ yum -y install centos-release-scl
   $ vim /etc/yum.repos.d/zabbix.repo
   [zabbix-frontend]
   ...
   enabled=1
   ...
   $ yum -y install zabbix-web-mysql-scl zabbix-apache-conf-scl
   ```

3. 创建数据库，授权指定用户管理数据库

   ```shell
   $ mysql -uroot -p123456
   MariaDB [(none)]> create database zabbix default character set utf8 collate utf8_bin;
   MariaDB [(none)]> grant all on zabbix.* to "zabbix"@"localhost" identified by "123456";
   MariaDB [(none)]> grant all on zabbix.* to "zabbix"@"%" identified by "123456";
   
   $ cd /usr/share/doc/zabbix-server-mysql-5.0.9/
   [root@localhost zabbix-server-mysql-5.0.9]# zcat create.sql.gz | mysql -uroot zabbix -p123456
   #将zabbix数据库文件导入到mariadb数据库中
   ```

4. 修改zabbix server 配置文件

   ```shell
   $ vim /etc/zabbix/zabbix_server.conf
   DBHost=localhost
   DBName=zabbix
   DBUser=zabbix
   DBPassword=123456
   ```

5. 编辑PHP配置解析配置

   ```shell
   $ cd /etc/opt/rh/rh-php72/php-fpm.d/
   $ vim zabbix.conf
   php_value[date.timezone] = Asia/Shanghai
   ```

   

6. 启动httpd等服务，并设置开机自启

   ```shell
   $ systemctl enable httpd zabbix-server zabbix-agent rh-php72-php-fpm
   $ systemctl start httpd zabbix-server zabbix-agent rh-php72-php-fpm
   ```

7. 使用浏览器访问：http://IP/zabbix 安装并配置zabbix web界面

   ![image-20210309023754480](./zabbix%205.0.assets/image-20210309023754480.png)

   ![image-20210309023856959](./zabbix%205.0.assets/image-20210309023856959.png)

   ![image-20210309023921041](./zabbix%205.0.assets/image-20210309023921041.png)

   ![image-20210309023945198](./zabbix%205.0.assets/image-20210309023945198.png)

   ![image-20210309023959664](./zabbix%205.0.assets/image-20210309023959664.png)

   ![image-20210309024011161](./zabbix%205.0.assets/image-20210309024011161.png)

   ![image-20210309024138734](./zabbix%205.0.assets/image-20210309024138734.png)

   <font color='red'>默认：用户名：Admin ， 密码：zabbix</font>

   

   ![image-20210309024222372](./zabbix%205.0.assets/image-20210309024222372.png)

8. 中文乱码解决办法

   ```shell
   [root@localhost dejavu]# cd /usr/share/fonts/dejavu
   [root@localhost dejavu]# mv simsun.ttc DejaVuSans.ttf 
   #先上传字体文件
   ```

   ![image-20210309025325196](./zabbix%205.0.assets/image-20210309025325196.png)

   ![image-20210309025427779](./zabbix%205.0.assets/image-20210309025427779.png)

### 3. 安装zabbix客户端-Linux端

1. 配置客户端软件仓库

   ```shell
   $ rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
   ```

2. 安装客户端软件

   ```shell
   $ yum -y install zabbix-agent
   ```

3. 修改zabbix agent配置文件

   ```shell
   $ vim /etc/zabbix/zabbix_agentd.conf
   server=zabbix server IP
   ServerActive=192.168.88.110
   ```

4. 启动zabbix agent服务

   ```shell
   $ systemctl enable zabbix-agent
   $ systemctl start zabbix-agent
   ```

5. web管理页面添加客户端监控

   ![image-20210309031747195](./zabbix%205.0.assets/image-20210309031747195.png)

   ![image-20210309031855094](./zabbix%205.0.assets/image-20210309031855094.png)

   ![image-20210309031935591](./zabbix%205.0.assets/image-20210309031935591.png)

   ![image-20210309032008309](./zabbix%205.0.assets/image-20210309032008309.png)

   ![image-20210309032132177](./zabbix%205.0.assets/image-20210309032132177.png)

### 4. 安装zabbix客户端-windows版

1. 访问zabbix官网，下载windows版客户端软件

   官方网址：https://www.zabbix.com/cn

   软件地址：https://cdn.zabbix.com/zabbix/binaries/stable/5.0/5.0.9/zabbix_agent-5.0.9-windows-amd64-openssl.msi

   ![image-20210309231844658](./zabbix%205.0.assets/image-20210309231844658.png)

2. 安装windows版zabbix agent软件

   ![image-20210309232834266](./zabbix%205.0.assets/image-20210309232834266.png)

   Host name: 填写和zabbix web界面上相同的名字即可

   zabbix server IP/DNS: 填写zabbix server 的IP地址即可

   server or proxy for active checks: 同样也填写zabbix server 的IP地址 

   <font color='red'>注意：在windows中安装了防护软件时会有阻拦安装提示，请点击允许安装否则会失败</font>

   

   下面是安装后zabbix agent 在windows中的位置

   ![image-20210309234036740](./zabbix%205.0.assets/image-20210309234036740.png)

3. web管理页面添加客户端监控

   ![image-20210309233642169](./zabbix%205.0.assets/image-20210309233642169.png)

   ![image-20210309233848412](./zabbix%205.0.assets/image-20210309233848412.png)

   ![image-20210309234135586](./zabbix%205.0.assets/image-20210309234135586.png)

4. 查看监控效果

   ![image-20210309235118954](./zabbix%205.0.assets/image-20210309235118954.png)

### 5. 安装zabbbix proxy代理

1. 配置代理服务器软件仓库并安装相关软件

   ```shell
   $ rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
   $ yum -y install zabbix-proxy-mysql mariadb mariadb-server
   #切记不要安装epel源，会和zabbix源造成冲突。
   ```

2. 配置mariadb数据库

   ```shell
   $ systemctl enable mariadb
   $ systemctl start mariadb
   $ 
   $ mysqladmin -uroot password '123456'
   $
   $ mysql -uroot -p123456
   Welcome to the MariaDB monitor.  Commands end with ; or \g.
   MariaDB [(none)]>
   MariaDB [(none)]> create database zabbix default character set utf8 collate utf8_bin;
   MariaDB [(none)]> grant all on zabbix.* to "zabbix"@"localhost" identified by "123456";
   
   $ cd /usr/share/doc/zabbix-proxy-mysql-5.0.27/
   $ zcat schema.sql.gz | mysql -uroot -p123456 zabbix
   #将zabbix proxy数据库文件导入到mariadb数据库中
   ```

3. 修改zabbix proxy配置文件，并完成启动和自启动

   ```shell
   $ vim /etc/zabbix/zabbix_proxy.conf
   Server=192.168.88.110
   ServerPort=10051
   Hostname=Zabbix proxy
   ListenPort=10051
   DBHost=localhost
   DBName=zabbix
   DBUser=zabbix
   DBPassword=123456
   DBPort=3306
   #注意：配置文件中Hostname的名称非常重要，确定好之后不要随便修改
   
   $ systemctl start zabbix-proxy
   $ systemctl enable zabbix-proxy
   ```

4. 修改zabbix agent使用zabbix proxy监控

   ```shell
   #前提是被监控的主机已经安装好zabbix agent工具
   $ vim /etc/zabbix/zabbix_agentd.conf
   server=zabbix proxy IP
   ServerActive=zabbix proxy IP
   
   $ systemctl enable zabbix-agent
   $ systemctl start zabbix-agent
   #要求zabbix agent将数据发往zabbix proxy进行保存处理
   ```

5. web管理界面添加代理，并设置zabbix agent指向zabbix proxy

   ![1673077289728](./zabbix%205.0.assets/1673077289728.png)

   ![1673077451586](./zabbix%205.0.assets/1673077451586.png)

   ![1672942589584](./zabbix%205.0.assets/1672942589584.png)

   ![1672942686600](./zabbix%205.0.assets/1672942686600.png)

   <font color='red'>注意：每次操作完之后都要点击更新才会生效，最后重启zabbix server端，变更数据源为zabbix proxy</font>

## 三、报警设置

### 1. web端声音报警

1. 设置web前端声音报警

   ![image-20210309235601354](./zabbix%205.0.assets/image-20210309235601354.png)

   ![image-20210310001701204](./zabbix%205.0.assets/image-20210310001701204.png)

### 2. 发送邮件报警

1. 选择Email作为报警媒介

   ![image-20210310000205842](./zabbix%205.0.assets/image-20210310000205842.png)

2. 设置Email报警媒介相关参数

   1. 获取邮件发送端的第三方登陆授权密码

      ![image-20210310000544441](./zabbix%205.0.assets/image-20210310000544441.png)

   2. 将参数填写到Email报警媒介中

      ![image-20210310000855327](./zabbix%205.0.assets/image-20210310000855327.png)

   3. 配置完成后测试是否能正常发送邮件

      ![image-20210310001039736](./zabbix%205.0.assets/image-20210310001039736.png)

      ![image-20210310001247109](./zabbix%205.0.assets/image-20210310001247109.png)

      ![image-20210310001438467](./zabbix%205.0.assets/image-20210310001438467.png)

3. 将报警媒介添加到指定监控项的动作中

   ![image-20210310001818758](./zabbix%205.0.assets/image-20210310001818758.png)

   ![image-20210310002010450](./zabbix%205.0.assets/image-20210310002010450.png)

   添加动作时，注意选用触发器示警度，然后选择大于等于某警告级别以上即可。

   

   ![image-20210310002544789](./zabbix%205.0.assets/image-20210310002544789.png)

   设置符合触发机制的操作行为：发现问题时发送的信息

   ```shell
   Problem: {EVENT.NAME}
   
   Problem started at {EVENT.TIME} on {EVENT.DATE}
   Problem name: {EVENT.NAME}
   Host: {HOST.NAME}
   Severity: {EVENT.SEVERITY}
   Operational data: {EVENT.OPDATA}
   Original problem ID: {EVENT.ID}
   {TRIGGER.URL}
   ```

   ![image-20210310003035974](./zabbix%205.0.assets/image-20210310003035974.png)

   设置符合触发机制的操作行为：问题恢复时发送的信息

   ```shell
   Resolved in {EVENT.DURATION}: {EVENT.NAME}
   
   Problem has been resolved at {EVENT.RECOVERY.TIME} on {EVENT.RECOVERY.DATE}
   Problem name: {EVENT.NAME}
   Problem duration: {EVENT.DURATION}
   Host: {HOST.NAME}
   Severity: {EVENT.SEVERITY}
   Original problem ID: {EVENT.ID}
   {TRIGGER.URL}
   ```

   ![image-20210310003511859](./zabbix%205.0.assets/image-20210310003511859.png)

4. 配置用户参数，设置收件人信息

   ![image-20210310005410438](./zabbix%205.0.assets/image-20210310005410438.png)

5. 制造报警，检查报警是否正常触发动作，邮件是否发送

   ![image-20210310010228160](./zabbix%205.0.assets/image-20210310010228160.png)

   ![image-20210310010243697](./zabbix%205.0.assets/image-20210310010243697.png)

### 3. 发送钉钉报警

1. 登陆钉钉在群里创建机器人生成api接口地址

   ![image-20210310012031207](./zabbix%205.0.assets/image-20210310012031207.png)

   ![image-20210310012446824](./zabbix%205.0.assets/image-20210310012446824.png)

   ![image-20210310012509058](./zabbix%205.0.assets/image-20210310012509058.png)

2. 编写钉钉信息发送脚本，设置钉钉报警媒介

   ```shell
   $ cd /usr/lib/zabbix/alertscripts
   $ vim dingding.sh
   #!/bin/bash
   to=$1
   subject=$2
   text=$3
   curl 'https://oapi.dingtalk.com/robot/send?access_token=3581fa0977a8415fccfb9b27df3924cb31f059a67e08e8a61c9bf222cf7691b0' \
   -H 'Content-Type: application/json' \
   -d '
   {"msgtype": "text",
   "text": {
   "content": "'"$text"'"
   },
   "at":{
   "atMobiles": [ "'"$to"'" ],
   "isAtAll": false
   }
   }'
   
   $ chmod +x dingding.sh
   ```

   ![image-20210310013427608](./zabbix%205.0.assets/image-20210310013427608.png)

   ![image-20210310014627809](./zabbix%205.0.assets/image-20210310014627809.png)

   ```shell
   三个参数
   {ALERT.SENDTO}
   {ALERT.SUBJECT}
   {ALERT.MESSAGE}
   ```

   ![image-20210310021951491](./zabbix%205.0.assets/image-20210310021951491.png)

   ![image-20210310014852565](./zabbix%205.0.assets/image-20210310014852565.png)

3. 设置动作条件出发后的行为：重新添加一个专门发送给钉钉的警告（问题警告、故障恢复）

   ![image-20210310015206486](./zabbix%205.0.assets/image-20210310015206486.png)

   ![image-20210310015253658](./zabbix%205.0.assets/image-20210310015253658.png)

4. 显示报警信息

   ![image-20210310021649255](./zabbix%205.0.assets/image-20210310021649255.png)

   ![image-20210310021716708](./zabbix%205.0.assets/image-20210310021716708.png)

## 四、高级功能

### 1. 聚合图形

直接在web界面即可完成聚合图形的设置，见下图

![1672944636161](./zabbix%205.0.assets/1672944636161.png)

![1672944782143](./zabbix%205.0.assets/1672944782143.png)

![1672944827076](./zabbix%205.0.assets/1672944827076.png)

![1672944863979](./zabbix%205.0.assets/1672944863979.png)

![1672944881280](./zabbix%205.0.assets/1672944881280.png)

![1672945094826](./zabbix%205.0.assets/1672945094826.png)

### 2. 自动发现

自动发现主要应对多服务器监控需求，但是有前提条件，需要在每个被监控主机提前安装好zabbix agent才能实现。

![1672945220715](./zabbix%205.0.assets/1672945220715.png)

![1672945508635](./zabbix%205.0.assets/1672945508635.png)

![1672945543739](./zabbix%205.0.assets/1672945543739.png)

![1672945628434](./zabbix%205.0.assets/1672945628434.png)

![1672945783298](./zabbix%205.0.assets/1672945783298.png)

![1672945915897](./zabbix%205.0.assets/1672945915897.png)

![1672945975101](./zabbix%205.0.assets/1672945975101.png)

![1672946035479](./zabbix%205.0.assets/1672946035479.png)

![1673063260077](./zabbix%205.0.assets/1673063260077.png)

![1673063285433](./zabbix%205.0.assets/1673063285433.png)

![1673063327871](./zabbix%205.0.assets/1673063327871.png)

![1673063355274](./zabbix%205.0.assets/1673063355274.png)

添加一台新的主机，安装zabbix agent程序，修改配置文件并启动，等待被发现即自动添加即可。

### 3. 创建自定义监控模板-实现nginx流量监控

> 实验前提：已实现对Linux主机的基础监控，Nginx流量监控会以新监控模板的方式加入到现有主机中。

1. 在被监控主机安装部署Nginx服务，并开启状态监控模块

   ```shell
   $ yum -y install gcc pcre-devel zlib-devel
   $ wget http://nginx.org/download/nginx-1.22.1.tar.gz
   $ tar -xf nginx-1.22.1.tar.gz
   $ cd nginx-1.22.1/
   $ ./configure --prefix=/usr/local/nginx --with-http_stub_status_module && make && make install
   #完成Nginx的安装及统计模块的安装
   
   $ vim /usr/local/nginx/conf/nginx.conf
   server {
   	... ...
   	location /tongji {
   		stub_status on;
   	}
   }
   #修改配置文件开启统计模块
   
   $ ln -s /usr/local/nginx/sbin/* /usr/local/sbin/
   $ nginx
   #启动nginx，并通过浏览器测试统计模块是否生效：http://ip/tongji
   ```

   ![1673034887066](./zabbix%205.0.assets/1673034887066.png)

2. 在zabbix agent中添加Nginx数据采集脚本实现流量数据收集，并添加到自定义监控中

   ```shell
   $ vim /etc/zabbix/zabbix_agentd.d/check_nginx.sh
   #!/bin/bash	 
   HOST="127.0.0.1"
   PORT="80" 
   # 检测 nginx 进程是否存在
   function ping {
   	/sbin/pidof nginx | wc -l 
   }
   # 检测 nginx 性能
   function active {
   	/usr/bin/curl "http://$HOST:$PORT/tongji/" 2>/dev/null| grep 'Active' | awk '{print $NF}'
   }	
   function reading {
   	/usr/bin/curl "http://$HOST:$PORT/tongji/" 2>/dev/null| grep 'Reading' | awk '{print $2}'
   }
   function writing {
   	/usr/bin/curl "http://$HOST:$PORT/tongji/" 2>/dev/null| grep 'Writing' | awk '{print $4}'
   }
   function waiting {
   	/usr/bin/curl "http://$HOST:$PORT/tongji/" 2>/dev/null| grep 'Waiting' | awk '{print $6}'
   }
   function accepts {
   	/usr/bin/curl "http://$HOST:$PORT/tongji/" 2>/dev/null| awk NR==3 | awk '{print $1}'
   }
   function handled {
   	/usr/bin/curl "http://$HOST:$PORT/tongji/" 2>/dev/null| awk NR==3 | awk '{print $2}'
   }
   function requests {
   	/usr/bin/curl "http://$HOST:$PORT/tongji/" 2>/dev/null| awk NR==3 | awk '{print $3}'
   }
   # 执行function
   $1
   #-------------------------------END------------------------------------------------
   
   $ cd /etc/zabbix/zabbix_agentd.d/
   $ chmod +x check_nginx.sh
   $ ./check_nginx.sh ping
   $ ./check_nginx.sh requests
   #编写脚本，设置执行权限，测试关键词数据过滤是否有效
   
   $ vim /etc/zabbix/zabbix_agentd.conf
   UserParameter=nginx.status[*],/etc/zabbix/zabbix_agentd.d/check_nginx.sh $1
   $ systemctl restart zabbix-agent
   #讲设置好的脚本添加到zabbix agent配置文件中，设置为自定义监控
   ```

3. 在zabbix server端安装专门的数据收集工具，将zabbix agent上收集的nginx流量数据拉取到本地

   ```shell
   $ yum -y install zabbix-get
   $ zabbix_get -s zabbix-agent-IP -k 'nginx.status[ping]'
   $ zabbix_get -s zabbix-agent-IP -k 'nginx.status[requests]'
   #使用zabbix server端测试能否连接到zabbix agent端设置的自定义监控，并正常获取数据
   ```

4. 在zabbix server端的web管理界面中添加Nginx数据采集模板，完成自动数据采集（应用集、监控项、触发器、图形）（详见以下截图）

   ![1673034964485](./zabbix%205.0.assets/1673034964485.png)

   ![1673035087347](./zabbix%205.0.assets/1673035087347.png)

   ![1673035126098](./zabbix%205.0.assets/1673035126098.png)

   

   选中自己添加的 nginx 模板，选择上方的应用集按钮，创建一个叫 nginx 的应用集（详见以下截图）

   ![1673035266882](./zabbix%205.0.assets/1673035266882.png)

   ![1673035300139](./zabbix%205.0.assets/1673035300139.png)

   选择上方的监控项，点击创建监控项，名称：zabbix ping 和 zabbix requests  分两次完成创建（详见以下截图）

   ```
   名称：zabbix ping
   键值：nginx.status[ping]
   应用集：nginx
   
   名称：zabbix requests
   键值：nginx.status[requests]
   应用集：nginx
   ```

   ![1673035383355](./zabbix%205.0.assets/1673035383355.png)

   ![1673035664559](./zabbix%205.0.assets/1673035664559.png)

   ![1673035726139](./zabbix%205.0.assets/1673035726139.png)

   选择上方的触发器，然后点击创建触发器（详见以下截图）

   ```shell
   名称：nginx is down
   表达式：添加自己定义的ping的监控项[ping]
   #还可以仿照继续添加requests的触发器
   ```

   ![1673035975791](./zabbix%205.0.assets/1673035975791.png)

   ![1673036124465](./zabbix%205.0.assets/1673036124465.png)

   ![1673036157598](./zabbix%205.0.assets/1673036157598.png)

   ![1673036310612](./zabbix%205.0.assets/1673036310612.png)

   ![1673036343798](./zabbix%205.0.assets/1673036343798.png)

   选中上方的图形，点击创建图形（详见以下截图）

   ```shell
   名称：nginx requests
   监控项：选择自己已经创建好了的监控项[requests]
   ```

   ![1673036426663](./zabbix%205.0.assets/1673036426663.png)

   ![1673036540403](./zabbix%205.0.assets/1673036540403.png)

   ![1673036713626](./zabbix%205.0.assets/1673036713626.png)

5. 最终将自己定义的监控项添加到已监控的主机中即可

   在配置中找到已经实现监控的主机，添加自定义的nginx监控模板即可（详见以下截图）

   ![1673036804977](./zabbix%205.0.assets/1673036804977.png)

   ![1673036892844](./zabbix%205.0.assets/1673036892844.png)

   ![1673036931376](./zabbix%205.0.assets/1673036931376.png)

   ![1673036974585](./zabbix%205.0.assets/1673036974585.png)

   ![1673037000865](./zabbix%205.0.assets/1673037000865.png)

   ![1673037116845](./zabbix%205.0.assets/1673037116845.png)