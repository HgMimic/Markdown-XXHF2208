# Linux初步认知

## 主流操作系统出现时间

Unix—1969
DOS—70年代早期
Windows—80年代中后期
Linux—1991

## UNIX主要发行版本

|操作系统|公司|硬件平台|
|-|-|-|
|AIX|IBM|PowerPC|
|UX|HP|PA-RISC|
|Solaris|SUN|SPARC|
|Linux, BSD|RedHat Linux, Ubuntu, FreeBSD|IA(Intel, AMD, Cyrix, RISE)|

## Linux版本

- 内核版：www.kernel.org

# Linux系统认知

## 学习Linux注意事项

1. Linux严格区分大小写
2. Linux一切皆文件
3. Linux不靠扩展名区分文件类型
    > 强制使用扩展名
    >
    > 1. 压缩包：`.gz|.bz2|.zip|.tar.gz|.tar.bz2|.tgz`等
    > 2. 二进制软件包：CentOS使用rpm包，所有rpm包都使用`.rpm`扩展名结尾
    > 3. 程序文件：shell脚本`.sh`，C语言`.c`等
    > 4. 网页文件：`.html` `.php`等

4. Linux中所有的存储设备都必须挂载之后才能使用

    > - Linux开机会自动挂载
    > - 不允许做移动设备自动挂载（未插开机会导致无法启动）
    > - 移动设备可以手动挂载

5. Winodws下的程序不能直接在Linux中使用

    > 优：Winodws的病毒木马对Linux无效  
    > 缺：需要单独开发Linux版本的软件

## Linux常用目录

|||
|-|-|
|/bin/|系统命令目录，普通用户和超级用户都能执行，是/usr/bin/的软链接|
|/sbin/|系统命令目录，只有超级用户才可以执行，是/usr/sbin/的软链接|
|/usr/bin/|系统命令目录，普通用户和超级用户都能执行|
|/usr/sbin/|系统命令目录，只有超级用户才可以执行|
|/boot/|启动目录，独立分区
|dev/|设备文件目录|
|/etc/|保存rpm安装的服务的配置文件目录|
|/home/|普通用户的家目录，默认登录位置，当前用户拥有最大权限|
|/lib/|系统函数库目录，是/usr/lib/的软链接（.so.xx.x.xx扩展名：系统函数库）|
|/lib64/|系统函数库目录，是/usr/lib64/的软链接|
|media/|系统预留挂载点（空目录），建议挂载媒体设备|
|mnt/|系统预留挂载点（空目录），建议挂载额外设备|
|opt/|类比Windows中的Program Files目录，用来手动安装源码包的位置（出现太晚，不习惯，一般习惯安装在/usr/local/目录下|
|proc/|目录中文件存储在内存中，为各种系统文件，少碰|
|sys/|目录中文件存储在内存中，为各种系统文件，少碰|
|root/|超级用户root的宿主目录
|run/|系统运行时产生的数据（SSID、PID），/var/run/是此目录的软链接|
|srv/|服务数据目录|
|tmp/|临时目录，存放临时文件|
|usr/|系统软件资源目录（UNIX Software Resource）|
|usr/local/|手工安装的软件保存位置（/usr/local/src/存放手工安装源码包）|
|usr/lib64/|系统函数库目录|
|usr/share/|应用程序资源文件保存位置|
|usr/src/|源码包保存位置（/usr/src/kernels/ 存放内核源码）|
|var/|动态数据保存位置（缓存、日志、运行产生文件）|
|var/www/html/|RPM包安装的Apache的网页主目录|
|var/lib/mysql|MySQL数据库保存目录|
|var/log/|系统日志保存目录|
|var/run/|服务和程序运行信息目录，存放PID|
|var/spool/|队列数据的目录|
|var/spool/mail/|新收到邮件队列保存位置|
|var/spool/cron/|系统的定时任务队列保存位置，保存系统计划任务|

> 软链接：类比Windows中快捷方式，/bin/ -> /usr/bin/

# Linux常用命令

## 命令的基本格式

### 命令的提示符
`[root@localhost ~]#`  
`[当前登录用户@简写主机名 当前所在目录最后一级目录]提示符`
> 提示符：超级用户`#`、普通用户`$`  
> `~`代表家目录

### 命令基本格式

`命令 [选项] [参数]`  
> `[]`代表可选项
> 选项：调整命令的功能  
> 参数：命令的操作对象，**省略是因为有默认参数**

## 目录操作命令

### ls

***作用：显示目录下的内容***  
`ls [选项] [文件名或目录名]`
> `-a`  显示所有文件  
> `-d`  显示目录信息，而不是目录下文件  
> `-h`  人性化显示文件大小单位  
> `-i`  显示文件的INode节点号  
> `-l`  长格式显示  
> `-n`  长格式显示uid和gid  
> `-R`  递归显示子目录  
> `--color=always|never|auto`   颜色显示

`ls -l`命令显示信息的含义：  
`-rw-------. 1 root root 1413 Oct 27 15:16 anaconda-ks.cfg`

<br />
<br />
<br />