#!/bin/bash

#	global functions file
#	return resualts: 0 - success; 1 - fail;

## ------------------- declare vars section------------------- ###
trap '' INT
P=""
U=""
T=""
S=""
D="########## ###### ### # =========================================================>"

TOMCAT=""
T7PATH="/usr/local/tomcat7/"
T7LIB="/usr/local/tomcat7/lib/"

## ------------------- functions section ---------------------- ###
list_functions() {
  msg "\n"
  msg "	- msg() - print message; Input parameters: message to print"
  msg "	- stop_exec() - stop current script proces;"
  msg "	- check_rights() - check rights; if super user"
  msg "	- doc1_help () - print doc1 help"
  msg "	- doc1_greeting() - print greetings doc1 messge"
  msg " - compare_count() - compare args count; Input parameters: digits for compare"
  msg " - parse_args() - parse command line arguments; Input parameters: parameters to parse"
  msg " - resize_root_fs() - resize root fs size / fix size"
  msg " - change_ssh_port() - change SSH port; Input parameters: ssh port number"
  msg " - add_iptables_rules() - add firewall and save rules; Input parameters: port number"
  msg " - sys_up() - update system"
  msg " - get_pack() - install packages; Input parameters: packages to install"
  msg " - set_java_home() - set java home"
  msg " - setup_mysql() - setup mysql. Input parameters: env type prod/test/etc"
  msg " - init_test_mysql() - init mysql for test env"
  msg " - setup_tomcat() - setup tomcat server"
  msg " - setenv() - create setenv.sh"
  msg " - dwn_extras() - download jars and copy jars from repo; Input parameters: 1 - SVN user; 2 - SVN user password"
  msg " - setup_tomcat_config() - setup tomcat config"
  msg " - other_stuff() - other stuff"
  msg " - solr_setup()  - setup solr"
}

#print message
msg() { echo -e "$1";} #print message

#stop execution;  stop current process 
stop_exec() { kill -9 $(ps aux | grep $$ | grep -v grep |  awk -F ' ' '{ print $2 }');}  

#check rights
check_rights() {
 if [ "$(id -u)" != "0" ]; then
   msg "$D\t This script must be run as root or be in /etc/sudoers";
   stop_exec;
 fi
}

#print help doc1
doc1_help() {
  msg "\nscript usage:\n"
  msg "$0 -u USER -p PASSWORD -t prod or test -s y OR n \n"
  msg "$0 -u bogdan -p qwerty -t test -s n \n"
  exit 1;
}

# print greetings
doc1_greeting() {
  msg "SCRIPT EXECUTED WITH NEXT PARAMETERS:\n"
  msg "-u - SVN USER: $U\n"
  msg "-p - SVN PASSWORD: $P\n"	
  msg "-t - ENVIRONMENT: $T\n"
  msg "-s - INSTALL SOLR: $S\n"
  read -sn 1 -p "Check them and press any key to continue... "
  msg "\n"
  return 0
}

#compare arg count
compare_count() {
 if [ "$1" -eq $2 ] 
  then
    return 0
  else 
    return 1
  fi
}

#parse command line arguments
parse_args() {
if (compare_count "$#" 8 ) #call compare; 8 - because (-t test -u bogdan -p qwerty -s y/n)
   then
      msg "$D\t Parsing params..."	
	while getopts "s:u:p:t:" opt; do
	  case "$opt" in
	   u) U=${OPTARG};;
	   p) P=${OPTARG};;
	   t) T=${OPTARG};;
	   s) TMP=${OPTARG}
	        case $TMP in 
		  y|Y ) S=$TMP;;
		  n|N ) S=$TMP;;
		  * ) S="n";;
		esac;;
	    esac
	 done
      doc1_greeting; #call greetings function
   else 
      doc1_help; #call help
   fi
}

#fix root fs size
resize_root_fs() {
 msg "$D\t Going to fix ROOT patition size. PLEASE DON'T STOP SCRIPT !!!\n"
 ROOT_FS=$(cat /etc/fstab | head -1 |  awk -F ' ' '{ print $1}')
 ROOT_FS_SIZE=$(df -h | grep $ROOT_FS |   awk -F ' ' '{ print $2}')
 msg "\n\tRoot partion is: $ROOT_FS. \n\tSize before resize: $ROOT_FS_SIZE\n"
 resize2fs $ROOT_FS
 ROOT_FS_SIZE=$(df -h | grep $ROOT_FS |   awk -F ' ' '{ print $2}')
 msg "\n\tRoot partion is: $ROOT_FS. \n\tCurrent size: $ROOT_FS_SIZE\n"
 read -sn 1 -p "Press any key to continue..." && return 0;
}

#change ssh port and restart sshd
change_ssh_port() {
 sed -i 's/^#Port/Port/g' /etc/ssh/sshd_config
 sed -i 's/^Port .*/Port '$1'/g' /etc/ssh/sshd_config
 service sshd restart
 sed -i 's/^#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
 service sshd restart
 msg "$D\t SSH port: $1\n"
 return 0
}

#add and save firewalls rules
add_iptables_rules() {
 iptables -I INPUT -p tcp --dport $1 -j ACCEPT
 /etc/init.d/iptables status | grep $1
 /etc/init.d/iptables save
 msg "\n$D\t SSH port is changed to $1; FIREWALL HAVE BEEN UPDATED. PLEASE NOTE: ADD PORT $1 TO SECURITY AWS GROUP."
 msg "$D\t ssh login will be like this: ssh -p $1 -i motive2Key.pem root@AWS-PUBLIC-DNS."
 return 0
}

#update system
sys_up() {
 yum -y update 
 yum -y upgrade
 msg "$D\t system has been updated."
 return 0
}

#install packages
get_pack() {
 yum install -y $@
 msg "$D\t packages has been installed."
 return 0
}

#prepare java home
set_java_home(){
 export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/
 export PATH=$PATH:/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/
 echo "export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/" >> /etc/profile
 echo "export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/" >> ~/.bashrc
 msg "$D\t JAVA HOME has been set."
 return 0
}

#init mysql 
init_test_mysql(){
 service mysqld start 
 /usr/bin/mysqladmin -u root password 'mysql'
 msg "$D\t Currect MySQL version is: $(mysql -uroot --batch --silent -pmysql -e 'select version()')\n"
 mysql --batch --silent -uroot -pmysql -e 'create database eas_db';
 msg "$D\t eas_db has been created. MySQL user and password is: root/mysql\n"
 read -sn 1 -p 'Press any key to continue...';echo
 return 0
}

#setup mysql server or client
setup_mysql(){
 msg  "$D\t Sever type: $1"
 wget http://goo.gl/4TyKNk
 yum -y localinstall mysql-community-release-el6-3.noarch.rpm

 if [ "$1" == "test" ]
  then
	yum -y install mysql mysql-server #test server
	read -sn 1 -p 'It is TEST SERVER! Press any key to continue...';echo
        init_test_mysql #init mysql
        return 0
  elif [ "$1" == "prod" ]
  then
	yum -y install mysql #prod
	msg "$D\t MySQL CLIENT has been install\n"
	read -sn 1 -p 'It is PROD SERVER! Press any key to continue...';echo
	return 0
  else
 	T="test"
  	msg "$D\t Cannot parse -t parameter. Going to use default TEST params envarioment.\n"
	read -sn 1 -p 'It is TEST SERVER! Press any key to continue...';echo
	yum -y install mysql mysql-server #test server
        init_test_mysql #init mysql
	return 0
 fi
}

#setup tomcat at new server
setup_tomcat(){
 wget -q http://archive.apache.org/dist/tomcat/tomcat-7/?C=M;O=A
 CURRENT_VERSION=$(cat index.html\?C\=M  | grep -vi beta |grep -i folder.gif | grep  7.0.* | tail -1 | awk -F 'v' '{ print $2 }'| awk -F '/' '{ print $1 }');
 msg "$D\t Tomcat version: $CURRENT_VERSION" 

 TOMCAT="http://archive.apache.org/dist/tomcat/tomcat-7/v$CURRENT_VERSION/bin/apache-tomcat-$CURRENT_VERSION.tar.gz"
 T7PATH="/usr/local/tomcat7/"
 T7LIB="/usr/local/tomcat7/lib/"

 cd /tmp
 wget $TOMCAT
 tar xf apache-tomcat-7.0.47.tar.gz
 rm -rf $T7PATH
 mv apache-tomcat-7.0.47 $T7PATH
 cd /usr/local/tomcat7/bin/
 chmod +x *
 useradd -d /usr/share/tomcat -s /sbin/nologin tomcat
 chown -R tomcat:tomcat $T7PATH
 cd /etc/init.d

 #create init script
 echo -e "#!/bin/bash

 CATALINA_HOME=/usr/local/tomcat7

 case \$1 in
 start)
 sh \$CATALINA_HOME/bin/startup.sh
 ;;

 stop)
 sh \$CATALINA_HOME/bin/shutdown.sh
 ;;

 restart)
 sh \$CATALINA_HOME/bin/shutdown.sh
 sh \$CATALINA_HOME/bin/startup.sh
 ;;

 esac
 exit 0\n" > /etc/init.d/tomcat7

 export CATALINA_HOME=$T7PATH
 export PATH=$PATH:$T7PATH
 echo "export TOMCAT_HOME=$T7PATH" >> /etc/profile
 echo "export TOMCAT_HOME=$T7PATH" >> ~/.bashrc

 #add tomcat to autostart
 chmod 755 tomcat7 
 chkconfig --add tomcat7
 chkconfig --level 234 tomcat7 on
 sudo iptables -I INPUT -p tcp --dport 7498 -j ACCEPT
 sudo /etc/init.d/iptables save
 cd /usr/local/tomcat7/webapps/
 rm -rf ROOT/
 msg "$D\t Tomcat has been installed."
 return 0
}

#Create setenv.sh script
setenv(){
 cd /usr/local/tomcat7/bin
 echo -e "export JAVA_OPTS=\"-Xms256m -Xmx512m\""  > setenv.sh
 chown tomcat:tomcat setenv.sh
 chmod +x setenv.sh
 msg "$D\t Set env script has been created."
 return 0
}

#download extra jars
dwn_extras(){
 cd /tmp/
 mkdir -p jars/
 svn checkout https://motive.svn.beanstalkapp.com/eas/trunk/ops/  jars/  --username=$1 --password=$2
 cp /tmp/jars/el-api-*.jar $T7LIB
 cp /tmp/jars/el-impl-*.jar $T7LIB
 cp /tmp/jars/log4j.jar $T7LIB
 cp /tmp/jars/tomcat-juli*.jar $T7LIB
 chown tomcat:tomcat * $T7LIB
 chmod 777 * $T7LIB
 msg "$D\t Extra jars has been downloaded."
 return 0
}

#Setup tomcat configs
setup_tomcat_config(){
 cd /usr/local/tomcat7/conf/
 sed -i 's/<Context>/<Context swallowOutput=\"true\">/' context.xml
 #change port
 sed -i 's/port\=\"8080\"/port\=\"7498\"/' server.xml
 #mkdir for eas notification
 mkdir -p /usr/eas/notifications
 service tomcat7 start
 msg "$D\t Tomcat has been install; Port 7498; To restart tomcat: service tomcat7 restart"
 return 0
}

#other stuff
other_stuff(){
 cd /
 mkdir -p temp/atomikos-sw-tmp
 chmod -R 777 temp/
 msg "$D\t Other stuff"
 return 0
}

#setup sold #Optional sold installation
solr_setup(){
  if [ "$1" == "y" ]
   then
	############################Solr Section############################ 
	read -sn 1 -p "Going to install solr. Press any key to continue..."
	echo -e "\n"
	cd /tmp/
	mkdir -p solrinstal/

	#install solr
	wget http://archive.apache.org/dist/lucene/solr/4.5.1/solr-4.5.1.tgz
	tar xf solr-4.5.1.tgz
        rm -rf /usr/local/solr/
	mv solr-4.5.1/ /usr/local/solr/

	#add firewall rules
	iptables -I INPUT -p tcp --dport 8983 -j ACCEPT
	/etc/init.d/iptables save

	#up solr
	cd /usr/local/solr/example
	nohup java -Dsolr.solr.home=/usr/local/solr/example/example-DIH/solr -jar start.jar > /var/log/solr.log 2>&1 &
	msg "$D\t Solr is upping... Please wait 60 sec."
	echo -e "\n"
	sleep 60
	read -sn 1 -p "Solr is up. Please check it at: http://domain-name:8983/solr/. Then press any key to continue and stop solr"
	echo -e "\n"
	kill -9 $(ps aux | grep solr | grep -v grep |  awk -F ' ' '{ print $2 }')

	#make a copy of the example configuration for our real set-up
	cd /usr/local/solr/
	mkdir -p prod/
	cd prod/
	cp -rp ../example/* .

	#tailor it for our needs
	cd /usr/local/solr/prod
	mv example-DIH/ new_mentor/
	cd /usr/local/solr/prod
	msg "$D\t Solr is upping... Please wait 60 sec.\n"
	sleep 60
	java -Dsolr.solr.home=/usr/local/solr/prod/new_mentor/solr -jar start.jar > /var/log/solr.log 2>&1 &
	read -sn 1 -p "Solr is up. Please check it at: http://domain-name:8983/solr/. Then press any key to continue and stop solr.."
	echo -e "\n"
	kill -9 $(ps aux | grep solr | grep -v grep |  awk -F ' ' '{ print $2 }')

	#dihs.jar
	cd /usr/local/solr/prod/solr-webapp/webapp/WEB-INF/lib
	wget http://solr-data-import-scheduler.googlecode.com/files/dihs.jar

	#change web.xml
	cd /usr/local/solr/prod/solr-webapp/webapp/WEB-INF/
	sed -i '26i <listener>\n  <listener-class>\n    org.apache.solr.handler.dataimport.scheduler.ApplicationListener\n  </listener-class>\n</listener>\n' web.xml
	echo -e "\n"

	#------ for test solr server
	cd /usr/local/solr/
	mkdir -p trunk/
	cd trunk/
	cp -rp ../example/* .
	cd /usr/local/solr/trunk
	cp -rp example-DIH/ new_mentor/
	cd /usr/local/solr/trunk/solr-webapp/webapp/WEB-INF/lib
	wget http://solr-data-import-scheduler.googlecode.com/files/dihs.jar
	cd /usr/local/solr/prod/solr-webapp/webapp/WEB-INF/
	sed -i '26i <listener>\n  <listener-class>\n    org.apache.solr.handler.dataimport.scheduler.ApplicationListener\n  </listener-class>\n</listener>\n' web.xml

	msg "$D\t Solr has been installed."
	return 0;
    else
	msg "$D\t Solr didnt install."
	return 0;
  fi
}



## ------------------- call functions sections --------------------- ###
check_rights;
parse_args "$@";
resize_root_fs;
change_ssh_port 22022
add_iptables_rules 22022
sys_up
get_pack java-1.7.0-openjdk.x86_64 java-1.7.0-openjdk-devel.x86_64 dos2unix ant subversion wget 
set_java_home
setup_mysql $T
setup_tomcat
setenv
dwn_extras $U $P
setup_tomcat_config
other_stuff
solr_setup $S
 


