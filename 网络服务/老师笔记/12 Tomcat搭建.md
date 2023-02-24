#### 一、安装jdk

```shell
#系统默认安装jdk
$ java -version

#安装jdk指定版本、覆盖系统默认安装的
$ tar -zxf jdk-11.0.11_linux-x64_bin.tar.gz 
$ cp -a jdk-11.0.11 /usr/local/jdk11

#配置环境变量,注意默认安装的jdk在/usr/bin下
$ vim /etc/profile      
	export JAVA_HOME=/usr/local/jdk11
	export JAVA_BIN=$JAVA_HOME/bin 
	export PATH=$JAVA_BIN:$PATH 
#让配置文件生效
$ source /etc/profile

#测试java环境，查看版本
$ java -version    

--------------------
演示java代码的编译运行：
#编写java代码
$ vim HelloWorld.java
	public class HelloWorld{
        public static void main(String[] args) {
                System.out.println("hello world~");
        }
	}
#编译java代码、成中间语言
$ javac HelloWorld.java
#运行java代码
$ java HelloWorld

```



#### 二、安装tomcat

```shell
#安装tomcat
$ tar -zxvf apache-tomcat-9.0.48.tar.gz
$ cp -a apache-tomcat-9.0.48 /usr/local/tomcat9

#启动服务
$ /usr/local/tomcat9/bin/catalina.sh start   

#测试
$ ss -antp | grep :8080
界面访问：http://ServerIP:8080


---------
#tomcat默认网页目录
$ cd  /usr/local/tomcat9/webapps/
$ echo "tomcat pages from 66.13~" > ROOT/index.jsp
#测试
$ curl localhost:8080

```



#### 三、部署项目

```shell
#将war包放在tomcat的webapps目录下：
$ cp -a jpetstore.war /usr/local/tomcat9/webapps/
	
#重启服务
$ /usr/local/tomcat9/catalina.sh stop
$ /usr/local/tomcat9/catalina.sh start 

#访问测试
界面访问：http://ServerIP:8080/jpetstore
默认账号：j2ee、j2ee

```



#### 四、自定义配置

```shell
#修改tomcat配置文件：
$ vim /usr/local/tomcat9/conf/server.xml
	#修改监听端口
	<Connector port="8080" protocol="HTTP/1.1"..>
$ /usr/local/tomcat9/bin/catalina.sh stop
$ /usr/local/tomcat9/bin/catalina.sh start

$ ss -antp | grep java

```

