#!/bin/bash

echo "\
##############################
# 脚本实现功能：             #
# 1. 修改SELinux状态         #
# 2. 修改IP地址（解除DHCP）  #
# 3. 配置本地yum源           #
##############################";
function SELinux_Cfg (){
	#读取开启或关闭选项存入变量OP
	read -p "enforcing or disabled?  " OP;
	#case语句判断变量OP的值，执行不同操作
	case $OP in

	disabled)
		#如果选择关闭，则修改SELINUX=这行内容为disabled
		sed -ir '/^SELINUX=/s/=.*$/=disabled/' /etc/selinux/config
		echo "SELinux关闭成功！";
		;;
	enforcing)
		#如果选择开启，则修改disabled或permissive为enforcing
		sed -ir '/^SELINUX=/s/=.*$/=enforcing/' /etc/selinux/config
		echo "SELinux开启成功！";
		;;
	*)
		#输入错误提示，然后产生错误返回值退出
		echo "输入错误！";
		return 1;
		;;
	esac
	return 0;
}

#function IP_Judge(){ TODO 因为调用了三次判断IP格式的awk，想声明一个函数来简化操作，但是发现函数貌似不能传递非整型返回值，暂且搁置。
#	echo $1 | awk '/^(([1-9][0-9]?)|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))(\.(([0-9])|([1-9][0-9])|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))){3}$/{print}';
#	return 0;
#}

function IP_Cfg (){
	read -p "请输入要修改IP地址的网卡名：" Net_Dev;
	#将Net_Dev的值与现有系统网卡设备比较，将名称赋给Net_Dev_Name变量（没有则是空值）
	Net_Dev_Name=$(ls -l /sys/class/net | awk 'NR>1{print $9}' | awk '"'"${Net_Dev}"'"==$1{print}');
	#判断传入Net_Dev_Name的网卡名是否为空
	if [ "A${Net_Dev_Name}" == "A" ]; then
		echo "没有这个设备！";
		return 1;
	else
		#有此网卡,初始化修改IP相关变量
		Net_Dev_Path="/etc/sysconfig/network-scripts/ifcfg-${Net_Dev_Name}";
		IP_Boolean=false;
		Prefix_Boolean=false;
		Gateway_Boolean=false;
		DNS_Boolean=false;
	fi

#IP判断修改
	read -p "请输入要修改为的IP地址：" IP_Addr
	IP_Addr=$( echo ${IP_Addr} | egrep "^(([1-9][0-9]?)|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))(\.(([0-9])|([1-9][0-9])|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))){3}$" );
	if [ "A${IP_Addr}" == "A" ]; then
		echo "IP地址格式错误！";
		return 1;
	else
		IP_Boolean=true;
	fi

#掩码判断修改
	read -p "请输入掩码位（1-25）：" Prefix;
	Prefix=$( echo ${Prefix} | awk '/^[0-9]+$/{print}' );
	#如果掩码位不是纯数字
	if [ "A${Prefix}" == "A" ]; then
		echo "掩码位格式错误！";
		return 1;
	#判断掩码位在1-25之间
	elif [ ${Prefix} -ge 1 -a ${Prefix} -le 25 ]; then
		Prefix_Boolean=true;
	else
		echo "掩码位超出范围！";
		return 1;
	fi

#网关判断修改
	read -p "请输入网关地址(现有水平不够判断网关地址是否合法，请自觉输入正确值！)：" Gateway;
	Gateway=$( echo ${Gateway} | egrep "^(([1-9][0-9]?)|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))(\.(([0-9])|([1-9][0-9])|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))){3}$" );
	if [ "A${Gateway}" == "A" ]; then
		echo "网关地址格式错误！"
		return 1;
	else
		Gateway_Boolean=true;
	fi
#DNS判断修改
	read -p "请输入DNS（，用逗号分隔功能还没做）：" DNS;
	DNS=$( echo ${DNS} | egrep "^(([1-9][0-9]?)|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))(\.(([0-9])|([1-9][0-9])|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))){3}$" );
	if [ "A${DNS}" == "A" ]; then
		echo "DNS格式错误！"
		return 1;
	else
		DNS_Boolean=true;
	fi

#判断四种布尔值是否全为真，进行sed操作
	if [ ${IP_Boolean} -a ${Prefix_Boolean} -a ${Gateway_Boolean} -a ${DNS_Boolean} ]; then
		#把BOOTPROTO从dhcp修改为static
		sed -ir '/^BOOTPROTO=/s/dhcp/static/' ${Net_Dev_Path};
		#把ONBOOT从no修改为yes
		sed -ir '/^ONBOOT=/s/no/yes/' ${Net_Dev_Path};
		#把原有的四项删去,如果没有则不用删除
		sed -ir '/^IPADDR=/d;/^PREFIX=/d;/^GATEWAY=/d;/^DNS/d' ${Net_Dev_Path};
		#增加新四项
		sed -ir '$aIPADDR='${IP_Addr}'' ${Net_Dev_Path};
		sed -ir '$aPREFIX='${Prefix}'' ${Net_Dev_Path};
		sed -ir '$aGATEWAY='${Gateway}'' ${Net_Dev_Path};
		sed -ir '$aDNS1='${DNS}'' ${Net_Dev_Path};
		#重启该网卡
		ifdown ${Net_Dev_Name} && ifup ${Net_Dev_Name}
		echo "修改IP地址成功！"
	else
		echo "条件不满足，无法修改！"
		return 1;
	fi
	return 0;
}

function LocalRepo_Cfg (){
	#第一步：修改/etc/yum.repos.d/CentOS-Media.repo 中的 baseurl=file:///mnt/
	sed -ir '/^baseurl=/s/=.*$/=file:\/\/\/mnt\//' /etc/yum.repos.d/CentOS-Media.repo
	#第二步：修改/etc/yum.repos.d/CentOS-Media.repo 中的 enabled=1
	sed -ir '/^enabled=/s/0/1/' /etc/yum.repos.d/CentOS-Media.repo
	#第三步：使/etc/yum.repos.d/CentOS-Base.repo失效
	if [ -e /etc/yum.repos.d/CentOS-Base.repo ]; then
		mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
	fi
	/usr/bin/umount /dev/sr0
	/usr/bin/mount /dev/sr0 /mnt/
	/usr/bin/yum clean all && /usr/bin/yum makecache
	echo "配置本地yum源成功！"
	return 0;
}
function Main (){
	read -p "请输入要执行的功能：" Func;
	
	case $Func in
	
	1)
		#SELinux状态
		SELinux_Cfg;
		;;
	2)
		#IP地址修改
		IP_Cfg;
		;;
	3)
		#本地yum源配置
		LocalRepo_Cfg;
		;;
	*)
		echo "输入错误！"
		return 1;
		;;
	esac
}
#执行主函数
Main;
