#!/bin/sh

# http://ec2-54-219-59-129.us-west-1.compute.amazonaws.com:8983/solr/
# ssh -p22022 -i .ssh/motive2Key.pem root@ec2-54-219-59-129.us-west-1.compute.amazonaws.com

P=""
U=""
T=""
S=""

#TODO: TRAP CTRL+C

#check rights
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root or be in /etc/sudoers" 1>&2
   exit 1
fi

if [ "$#" -eq 8 ] #because  (-t test -u bogdan -p qwerty -s on/off)
then
	echo -e "\t\t Parsing params..."
		
	while getopts "s:u:p:t:" opt; do
	    case "$opt" in
	    u) U=$OPTARG
		;;
	    p) P=$OPTARG 
		;;
	    t) T=$OPTARG 
		;;
	    s) TMP=$OPTARG
		case $TMP in 
		  y|Y ) S=$TMP;;
		  n|N ) S=$TMP;;
		  * ) S="n";;
		esac
		;;
	    esac
	done

	echo -e "\tSCRIPT EXECUTED WITH NEXT PARAMETERS:\n"
	echo -e "-u - SVN USER: $U\n"
	echo -e "-p - SVN PASSWORD: $P\n"	
	echo -e "-t - ENVIRONMENT: $T\n"
        echo -e "-s - INSTALL SOLR: $S\n"
	read -sn 1 -p "Check them and press any key to continue..."
	echo -e "\n"
else 
  echo -e "\nscript usage:\n"
  echo -e "$0 -u USER -p PASSWORD -t prod or test -s y OR n \n"
  echo -e "$0 -u bogdan -p qwerty -t test -s n \n"
  exit 1;
fi


#fix size
echo -e "\t\t Going to fix ROOT patition size. PLEASE DON'T STOP SCRIPT !!!\n"
ROOT_FS=$(cat /etc/fstab | head -1 |  awk -F ' ' '{ print $1}')
ROOT_FS_SIZE=$(df -h | grep $ROOT_FS |   awk -F ' ' '{ print $2}')
echo -e "\n\tRoot partion is: $ROOT_FS. \n Size before resize: $ROOT_FS_SIZE\n"
resize2fs $ROOT_FS
echo -e "\n\tRoot partion is: $ROOT_FS. \tCurrent size: $ROOT_FS_SIZE\n"
read -sn 1 -p "Press any key to continue..."

#change ssh port and restart sshd
sed -i 's/^#Port/Port/g' /etc/ssh/sshd_config
sed -i 's/^Port .*/Port 22022/g' /etc/ssh/sshd_config
service sshd restart
sed -i 's/^#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
service sshd restart

#add and save firewalls rules
iptables -I INPUT -p tcp --dport 22022 -j ACCEPT
/etc/init.d/iptables status | grep 22022
/etc/init.d/iptables save
echo -e "-----> SSH PORT IS CHANGED TO 22022; FIREWALL HAVE BEEN UPDATED. PLEASE NOTE: ADD 22022 PORT TO SECURITY GROUP\n"
echo -e "-------- ssh login will be like this: ssh -p 22022 -i motive2Key.pem root@AWS-PUBLIC-DNS\n"

#create new user
if cat /etc/passwd | grep -q "tjohnson"
  then 
	echo -e "-------- User exists. Skipping creation step."
  else 
	echo -e "-------- User didnt exists. Going to create new."
	useradd -s /bin/bash -m -d /home/tjohnson tjohnson 
	passwd tjohnson
	echo -e " tjohnson ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	echo -e "-----> User tjohnson has been created."
fi

#update system
yum -y update && yum -y upgrade

#install OpenJDK 1.7
yum install -y java-1.7.0-openjdk.x86_64 java-1.7.0-openjdk-devel.x86_64 dos2unix

#install packages
yum install -y ant subversion 

#set java home
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/
export PATH=$PATH:/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/
echo "export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/" >> /etc/profile
echo "export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.45.x86_64/" >> ~/.bashrc

#install MySQL 5.6
yum install -y wget
wget http://goo.gl/4TyKNk
yum -y localinstall mysql-community-release-el6-3.noarch.rpm

#check server type
if [ "$T" == "test" ]
then
	yum -y install mysql mysql-server #test server
	read -sn 1 -p 'It is TEST SERVER! Press any key to continue...';echo
elif [ "$T" == "prod" ]
then
	yum -y install mysql #prod
	echo -e "-----> MySQL CLIENT has been install;\n"
	read -sn 1 -p 'It is PROD SERVER! Press any key to continue...';echo
else
	T="test"
  	echo -e "-----> Cannot parse -t parameter. Going to use default TEST params envarioment.\n"
	read -sn 1 -p 'It is TEST SERVER! Press any key to continue...';echo
	yum -y install mysql mysql-server #test server
fi

#check if test show info
if [ "$T" == "test" ]
then
	service mysqld start 
	/usr/bin/mysqladmin -u root password 'mysql'
	echo -e "-------- Currect MySQL version is: $(mysql -uroot --batch --silent -pmysql -e 'select version()')\n"
	mysql --batch --silent -uroot -pmysql -e 'create database eas_db';
	echo -e "-------- eas_db has been created. MySQL user and password is: root/mysql\n"
	read -sn 1 -p 'Press any key to continue...';echo
fi

############################install tomcat7 section############################ 
TOMCAT="http://mirror.nl.webzilla.com/apache/tomcat/tomcat-7/v7.0.47/bin/apache-tomcat-7.0.47.tar.gz"
T7PATH="/usr/local/tomcat7/"
T7LIB="/usr/local/tomcat7/lib/"

cd /tmp
wget $TOMCAT
tar xf apache-tomcat-7.0.47.tar.gz
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

#Create a setenv.sh script
cd /usr/local/tomcat7/bin
echo -e "export JAVA_OPTS=\"-Xms256m -Xmx512m\""  > setenv.sh
chown tomcat:tomcat setenv.sh
chmod +x setenv.sh

#download jars and copy jars
yum install -y subversion
cd /tmp/
mkdir -p jars/
svn checkout https://motive.svn.beanstalkapp.com/eas/trunk/ops/  jars/  --username=$U --password=$P
cp /tmp/jars/el-api-*.jar $T7LIB
cp /tmp/jars/el-impl-*.jar $T7LIB
cp /tmp/jars/log4j.jar $T7LIB
cp /tmp/jars/tomcat-juli*.jar $T7LIB
chown tomcat:tomcat * $T7LIB
chmod 777 * $T7LIB

#Setup context
cd /usr/local/tomcat7/conf/
sed -i 's/<Context>/<Context swallowOutput=\"true\">/' context.xml
#change port
sed -i 's/port\=\"8080\"/port\=\"7498\"/' server.xml
#mkdir for eas notification
mkdir -p /usr/eas/notifications
service tomcat7 start
echo -e "-----> Tomcat has been install; Port 7498; To restart tomcat: service tomcat7 restart"

#Upload other stuff
cd /
mkdir -p temp/atomikos-sw-tmp
chmod -R 777 temp/

#Optional sold installation
if [ "$S" == "y" ]
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
	echo -e "Solr is upping... Please wait 60 sec."
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
	echo -e "Solr is upping... Please wait 60 sec."
	echo -e "\n"
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
	#-------------------------------------
fi

read -sn 1 -p "Server: $T has been configured. Then press any key to exit..."
echo -e "\n"



