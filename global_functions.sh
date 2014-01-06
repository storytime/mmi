#!/bin/bash

#	global functions file
#	return resualts: 0 - success; 1 - fail;

## ------------------- declare vars section------------------- ###
trap '' INT
P=""
U=""
T=""
S=""
SEP="---------- ########## ###### ### # =========================================================>\t"

V=""
D=""
R=""

TOMCAT=""
T7PATH="/usr/local/tomcat7/"
T7LIB="/usr/local/tomcat7/lib/"

## ------------------- doc1 functions section ---------------------- ###
list_functions() {
  msg "\n"
  msg "	--------------------------------- doc1 ------------------------------------------- "
  msg "	- msg() - print message; Input parameters: message to print"
  msg "	- stop_exec() - stop current script process;"
  msg "	- check_rights() - check rights; if super user"
  msg "	- doc1_help () - print doc1 help"
  msg "	- doc1_greeting() - print greetings doc1 message"
  msg " - compare_count() - compare args count; Input parameters: digits for compare"
  msg " - parse_args() - parse doc1 command line arguments; Input parameters: parameters to parse"
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

  msg "	--------------------------------- doc2 ------------------------------------------- "
  msg " - check_os() - check if CentOS/Fedora/RHEL/"
  msg "	- doc2_help() - print doc1 help"
  msg "	- doc2_greetings() - print greetings doc1 message"
  msg "	- create_remove_dirs - remove and create ne dirs"
  msg " - parse_args_doc2() - parse doc2 command line arguments; Input parameters: parameters to parse"
  msg " - check_env_type() - check env type; Input parameters: env"
  msg " - ch_code() - Checkout SVN code. Input parameters: env  type; SVN user; SVN password; sprint name or trunk"
  msg " - change_prod_db_password() - Change DB password. Input parameters: env type(-t)"
  msg " - set_build_version() - Set build version. Input parameters: env type; build version(-v)"
  msg " - set_relative_url() - Set relative version. Input parameters: env type; relative URL(-r)"  
  msg " - change_prod_configs() - Set change prod configs. Input parameters: env type; db password (-d)"
  msg " - build_eas() - build eas war via ant. Input parameters: env type"
  msg " - build_notif_manager() - build notif manager via ant. Input parameters: env type"
  msg " - swich_prod_configs() - move prod configs. Input parameters: env type"
  msg " - doc2_print_warn() - prinnt doc2 env. Input parameters: env type"
  msg " - kill_main_services() - stop main services"
  msg " - flyway_migration() - perform flyway migration"
}

#print message
msg() { echo -e "$1";} #print message

#stop execution;  stop current process 
stop_exec() { kill -9 $(ps aux | grep $$ | grep -v grep |  awk -F ' ' '{ print $2 }');}  

#check rights
check_rights() {
 if [ "$(id -u)" != "0" ]; then
   msg "$SEP This script must be run as root or be in /etc/sudoers";
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
 if [ "$1" -ge $2 ] 
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
      msg "$SEP Parsing params... $#"	
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
 msg "$SEP Going to fix ROOT patition size. PLEASE DON'T STOP SCRIPT !!!\n"
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
 msg "$SEP SSH port: $1\n"
 return 0
}

#add and save firewalls rules
add_iptables_rules() {
 iptables -I INPUT -p tcp --dport $1 -j ACCEPT
 /etc/init.d/iptables status | grep $1
 /etc/init.d/iptables save
 msg "\n$SEP SSH port is changed to $1; FIREWALL HAVE BEEN UPDATED. PLEASE NOTE: ADD PORT $1 TO SECURITY AWS GROUP."
 msg "$SEP SSH login will be like this: ssh -p $1 -i motive2Key.pem root@AWS-PUBLIC-DNS."
 return 0
}

#update system
sys_up() {
 yum -y update 
 yum -y upgrade
 msg "$SEP system has been updated."
 return 0
}

#install packages
get_pack() {
 yum install -y $@
 msg "$SEP packages has been installed."
 return 0
}

#prepare java home
set_java_home(){
 export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/
 export PATH=$PATH:/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/
 echo "export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/" >> /etc/profile
 echo "export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/" >> ~/.bashrc
 msg "$SEP JAVA HOME has been set."
 return 0
}

#init mysql 
init_test_mysql(){
 service mysqld start 
 /usr/bin/mysqladmin -u root password 'mysql'
 msg "$SEP Currect MySQL version is: $(mysql -uroot --batch --silent -pmysql -e 'select version()')\n"
 mysql --batch --silent -uroot -pmysql -e 'create database eas_db';
 msg "$SEP eas_db has been created. MySQL user and password is: root/mysql\n"
 read -sn 1 -p 'Press any key to continue...';echo
 return 0
}

#setup mysql server or client
setup_mysql(){
 msg  "$SEP Sever type: $1"
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
	msg "$SEP MySQL CLIENT has been install\n"
	read -sn 1 -p 'It is PROD SERVER! Press any key to continue...';echo
	return 0
  else
 	T="test"
  	msg "$SEP Cannot parse -t parameter. Going to use default TEST params envarioment.\n"
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
 msg "$SEP Tomcat version: $CURRENT_VERSION" 

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
 msg "$SEP Tomcat has been installed."
 return 0
}

#Create setenv.sh script
setenv(){
 cd /usr/local/tomcat7/bin
 echo -e "export JAVA_OPTS=\"-Xms256m -Xmx512m\""  > setenv.sh
 chown tomcat:tomcat setenv.sh
 chmod +x setenv.sh
 msg "$SEP Set env script has been created."
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
 msg "$SEP Extra jars has been downloaded."
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
 msg "$SEP Tomcat has been install; Port 7498; To restart tomcat: service tomcat7 restart"
 return 0
}

#other stuff
other_stuff(){
 cd /
 mkdir -p temp/atomikos-sw-tmp
 chmod -R 777 temp/
 msg "$SEP Other stuff"
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
	msg "$SEP Solr is upping... Please wait 60 sec."
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
	msg "$SEP Solr is upping... Please wait 60 sec.\n"
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

	msg "$SEP Solr has been installed."
	return 0;
    else
	msg "$SEP Solr didnt install."
	return 0;
  fi
}


## ------------------- doc2 functions section ---------------------- ###

#check OS 
check_os(){
  if ! cat /etc/redhat-release | grep -iE 'centos|rhel|fedora|red|hat'; then
    msg "$SEP Incorrect OS!"
    stop_exec;
    exit 1;
  fi
}

#print doc2 script help
doc2_help() {
  msg "\nscript usage:\n"
  msg "Example0: $0 -u USER -p PASSWORD -s sprint_name -t prod or test (all other args will be use as test) -r relative_host_url -v 1.2.4 -p db_password \n"
  msg "Example1: $0 -u bogdan -p qwerty -t test -v 1.2.4 -r relative_host_url\n"
  msg "Example2: $0 -u bogdan -p qwerty -t test -v 1.2.4\n"
  msg "Example3: $0 -s sprint13_130916 -u bogdan -p qwerty -t prod -r relative_host_url -v 1.2.4 -d db_password     #will set prod db password: db_password \n"
  msg "Example4: $0 -s sprint13_130916 -u bogdan -p qwerty -t prod -r relative_host_url -v 1.2.4 -d default     #default password will be used \n"
  msg "Example5: $0 -s sprint13_130916 -u bogdan -p qwerty -t prod -r relative_host_url -v 1.2.4 -d     #will delete prod db password from all configs \n"
  msg "Example6: $0 -s sprint_name -u bogdan -p qwerty -r relative_host_url -t BLA_BLA_INFO -v 1.2.4 \n"
  exit 1;
}

#print doc2 greetings
doc2_greetings() {
 msg "SCRIPT EXECUTED WITH NEXT PARAMETERS:\n"
 msg "-u - SVN USER: $U\n"
 msg "-p - SVN PASSWORD: $P\n"       
 msg "-t - ENVIRONMENT: $T\n"
 msg "-s - SPRINT NAME: $S\n"
 msg "-v - VERSION: $V\n"
 msg "-r - relative_host_url: $R (if it's empty, default value will be used;)\n"
 msg "-d - DB PASSWORD: $D This is applied ONLY FOR PROD server\n"
 read -sn 1 -p "Check them and press any key to continue..."
 msg "\n"
 return 0
}

#parse doc2 args
parse_args_doc2(){
if (compare_count "$#" 8 )
 then
        msg "$SEP Parsing params...  $#"
        while getopts "r:u:p:t:s:v:d:" opt; do
            case "$opt" in
            u) U=$OPTARG
                ;;
            p) P=$OPTARG
                ;;
            t) T=$OPTARG
                ;;
	    s) S=$OPTARG
		;;
	    v) V=$OPTARG
		;;
	    r) R=$OPTARG
		;;
	    d) D=$OPTARG
		;;
            esac
        done
	doc2_greetings #call greatings
 else
   doc2_help #call print help
 fi 
}

#create-remove test dir
create_remove_dirs(){ 
 msg "$SEP Create-remove new build dir"
 rm -rf ~/build/
 mkdir -p ~/build/
 cd ~/build/
 return 0
}

#check env type prod/test
#$1 - env
check_env_type() {
if [ "$1" == "test" ]; then
     return 0;
 else 
     return 1;
 fi
}

# checkout code from SVN
# $1 - env $T
# $2 - SVN user $U
# $3 - SVN password $P
# $4 - sprint name

ch_code(){
 if (check_env_type $1)
    then
      msg "$SEP Goint to checkout $1 code. SVN account: $2/$3"
      svn checkout https://motive.svn.beanstalkapp.com/eas/trunk/ trunk/ --username=$2 --password=$3
      return 0;
    else
        if [ ! -z "$4" ];then
           msg "$SEP Goint to checkout $1 code. SVN account: $2/$3; Code path: $4"
           svn checkout https://motive.svn.beanstalkapp.com/eas/branches/$4/ prod/ --username=$2 --password=$3
           return 0;
        else
	   msg "$SEP ERROR!!! Please enter scrint name"
	   stop_exec
           return 1;
        fi
  fi

  msg "$SEP ERROR! Cannot checkout code!"
  stop_exec
  return 1;
}

# Change prod DB password (use not standart)
# $1 - env type

change_prod_db_password(){
 if (check_env_type $1); then
      msg "$SEP Its test env, so default DB password will used";
      return 0;
    else
       #get DEFAULT_DB_PASSWORD
   	DEFAULT_DB_PASSWORD=$(cat  ~/build/prod/notification-manager/custom.properties_prod | grep -i db_password | grep -v "#" | awk -F '=' '{ print $2 }')   	
	if [ "$D" == "default" ]; then
	    D=$DEFAULT_DB_PASSWORD
	    msg "$SEP Default DB password will used";
            return 0
	else
	    msg "$SEP Custom DB password: $D; if DB password is empty it will delete db password from all configs";
	    return 0
    	fi
	return 1;
  fi

  msg "$SEP ERROR! Cannot change DB password!"
  stop_exec
  return 1;
}

# put build version
# $1 - env type
# $2 - build version

set_build_version () {  
  if (check_env_type $1); then
    dos2unix ~/build/trunk/eas/resources/custom.properties_awstest
    sed -i -r 's/build_version=.*/build_version='$2'/'  ~/build/trunk/eas/resources/custom.properties_awstest
    msg "$SEP Build version: $V"
    return 0
  else
    dos2unix ~/build/prod/eas/resources/custom.properties_prod
    sed -i -r 's/build_version=.*/build_version='$2'/'  ~/build/prod/eas/resources/custom.properties_prod
    msg "$SEP Build version: $V"
    return 0
  fi

  msg "$SEP ERROR! Cannot set version!"
  stop_exec
  return 1;
}

# set relative url
# $1 - env type $T
# $2 - relative url $R

set_relative_url() {  
  if (check_env_type $1); then
    if ! [ -z "$2" ]; then
	 sed -i -r 's/relative_host_url=.*/relative_host_url=\/\/'$2'/'  ~/build/trunk/eas/resources/custom.properties_awstest
    fi
    msg "$SEP Relative url: $2"
    return 0
  else
    msg "$SEP Relative url: $2"
    if ! [ -z "$2" ]; then
	 sed -i -r 's/relative_host_url=.*/relative_host_url=\/\/'$2'/'  ~/build/prod/eas/resources/custom.properties_prod
    fi
    return 0
  fi

  msg "$SEP ERROR! Cannot set relative url!"
  stop_exec
  return 1;
}

# change win to unix encoding, fix configs, remove DB passwords from config files
# $1 - env type
# $2 - db password $D
change_prod_configs() {
  if (! check_env_type $1); then
	dos2unix ~/build/prod/notification-manager/custom.properties_prod
	sed -i -r 's/db_password=.*/db_password='$2'/' ~/build/prod/notification-manager/custom.properties_prod
	dos2unix ~/build/prod/flyway-2.2.1/conf/flyway.properties_prod
	sed -i -r 's/flyway.password=.*/flyway.password='$2'/' ~/build/prod/flyway-2.2.1/conf/flyway.properties_prod
	dos2unix ~/build/prod/eas/resources/eas-dao.properties_prod
	sed -i -r 's/MySQL_EAS.connection.password=.*/MySQL_EAS.connection.password='$2'/' ~/build/prod/eas/resources/eas-dao.properties_prod
	msg "$SEP Configs has been changed"
	return 0;
  else 
	msg "$SEP This is $1 env. Going to use default configs"
	return 0;
  fi

  msg "$SEP ERROR! Cannot change prod configs!"
  stop_exec
  return 1;
}


# prepare eas war file
# $1 env type

build_eas() {
  if (check_env_type $1); then
    cd ~/build/trunk/eas/
    ant -f build-eas.xml clean war-awstest
    msg "$SEP $1 eas.war is ready"
    return 0;
  else 
      #prod  
      cd ~/build/prod/eas/
      ant -f build-eas.xml clean war-production
      msg "$SEP $1 eas.war is ready"
      return 0;
  fi

  msg "$SEP ERROR! Can not build eas.war"
  stop_exec
  return 1;
}


# build notificatopm manager
# $1 env type

build_notif_manager(){
  if (check_env_type $1); then
    #build notif. manager
    cd ~/build/trunk/notification-manager
    ant -f build.xml clean build-awstest 
    msg "$SEP $1 notif. manager is ready"
    return 0;
  else 
    #build notif. manager
    cd ~/build/prod/notification-manager
    ant -f build.xml clean build-prod
    msg "$SEP $1 notif. manager is ready"
    return 0;
  fi

  msg "$SEP ERROR! Can not build notif. manager war"
  stop_exec
  return 1;
}

# swich configs to prod; Switch the flyway parameter file for production only 
# $1 env type

swich_prod_configs(){
  if(! check_env_type $1); then
    cd ~/build/prod/flyway-2.2.1/conf
    cp -rf flyway.properties_prod flyway.properties
    cd ~/build/prod/solr/new_mentor/solr/eas/conf
    cp -rf solr-eas-config_prod.xml solr-eas-config.xml
    msg "$SEP $1 prod configs has been moved"
    return 0;
  else 
    msg "$SEP You dont need to move $1 configs"
    return 0;
  fi

  msg "$SEP ERROR! Can not swich configs to prod"
  stop_exec
  return 1;
}


# print messages
# $1 - env type

doc2_print_warn(){
  if(check_env_type $1); then
     msg "$SEP Solr files: ~/build/trunk/solr/new_mentor/"
     msg "$SEP Flyway migration files: ~/build/trunk/flyway-2.2.1/"
     msg "$SEP eas.war: ~/build/trunk/eas/output/dist/eas.war"
     msg "$SEP Going to stop sorl, tomcat and notification"
     return 0;
  else
     msg "$SEP Solr files: ~/build/prod/solr/new_mentor/"
     msg "$SEP Flyway migration files: ~/build/prod/flyway-2.2.1/"
     msg "$SEP eas.war: ~/build/prod/eas/output/dist/eas.war"
     msg "$SEP Going to stop sorl, tomcat and notification"
     return 0;
  fi

  msg "$SEP ERROR! Cannot print $1 messages"
  stop_exec
  return 1;
}

# force kill proc
kill_main_services(){
 NOT_PID = $(ps auxw | grep -iv grep | grep -i notifications | grep -i jar |  awk -F ' ' '{ print $2 }')
 SOLR_PID = $(ps auxw | grep -v grep | grep -i solr |  awk -F ' ' '{ print $2 }')
 TOM_PID = $(ps auxw | grep -i tomcat | grep -iv grep |  awk -F ' ' '{ print $2 }')
 
 msg "$SEP PIDs: Notif: $NOT_PID Solr: $SOLR_PID Tomcat: $TOM_PID"

 if ! [ -z "$NOT_PID" ]; then
     kill -9 $NOT_PID
     msg "$SEP Notification PID: $NOT_PID. Killed"
 else
     msg "$SEP Notification is not started"
 fi

 if ! [ -z "$SOLR_PID" ]; then
     kill -9 $SOLR_PID
     msg "$SEP Solr PID: $SOLR_PID. Killed"
 else
     msg "$SEP Solr is not started"
 fi

 if ! [ -z "$TOM_PID" ]; then
     kill -9 $TOM_PID 	
     msg "$SEP Tomcat PID: $TOM_PID. Killed"
 else
     msg "$SEP Tomcat is not started"
 fi
 return 0;
}

# Flyway migration - use  flyway.properties
# $1 - env type 

flyway_migration(){
 if (check_env_type $1); then
    cd	 ~/build/trunk/flyway-2.2.1
    chmod +x flyway
    ./flyway -X migrate
     msg "$SEP $1 migration has been performed"
     return 0;
  else 
    cd	 ~/build/prod/flyway-2.2.1
    chmod +x flyway
    ./flyway -X migrate
     msg "$SEP $1 migration has been performed"
     return 0;
  fi

  msg "$SEP ERROR! Cannot perform flyway migration !!!"
  stop_exec
  return 1;
}

## ------------------- call functions sections (all for doc1.sh)--------------------- ###
## --------------------------- doc1.sh as function call ----------------------------- ###
#check_rights
#parse_args "$@"
#resize_root_fs
#change_ssh_port 22022
#add_iptables_rules 22022
#sys_up
#get_pack java-1.7.0-openjdk.x86_64 java-1.7.0-openjdk-devel.x86_64 dos2unix ant subversion wget 
#set_java_home
#setup_mysql $T
#setup_tomcat
#setenv
#dwn_extras $U $P
#setup_tomcat_config
#other_stuff
#solr_setup $S
 

## ------------------- call functions sections (all for doc2.sh)--------------------- ###
## --------------------------- doc2.sh as function call ----------------------------- ###
check_rights
check_os
parse_args_doc2 "$@"
create_remove_dirs
ch_code $T $U $P $S
change_prod_db_password $T
set_build_version $T $V
set_relative_url $T $R
change_prod_configs $T $D
build_eas $T
build_notif_manager $T #test it 
swich_prod_configs $T #test it 
doc2_print_warn $T #test it 
kill_main_services #test it 
flyway_migration $T #test it

