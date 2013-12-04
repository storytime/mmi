#!/bin/bash

#https://docs.openclinica.com/3.1/installation/installation-linux

#colors
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
txtrst='\e[0m'

#dirs 
OC_HOME="/usr/local/oc/install"
CAT_HOME="/usr/local/tomcat"
F_PATH=$CAT_HOME/files
CONFIG=$CAT_HOME/webapps/OpenClinica/WEB-INF/classes/datainfo.properties

#root
if [[ $EUID -ne 0 ]]; 
then
   echo -e "$bldred $0 must be run as root ONLY! Please use \"sudo $0\" or \"su\" commands $txtrst" 
   exit 1
fi

#check dist
DIST=$(cat /etc/lsb-release | grep DISTRIB_ID |  awk -F '=' '{ print $2 }')

if [ "$DIST" == "Ubuntu" ]; then
  apt-get install unzip   
elif [ "$DIST" == "RHEL"  ]; then
  yum install unzip   
else
   echo -e "$bldred $0 Please install unzip.  $txtrst" 
   return 0;
fi

####################### fucntions #######################
download()
{
    local url=$1
    echo -e "Dowloading: $url"
    wget -nc --progress=dot $url 2>&1|grep --line-buffered -o "[0-9]*%"|xargs -L1 echo -en "\b\b\b\b";
    echo -ne "\b\b\b\b"
    echo -e "$bldgrn DONE $txtrst"
}

#get os version
OS=$(uname -a |  awk -F ' ' '{ print $12 }')
echo -e "$bldylw You have $OS system.\n $txtrst"

#1
mkdir -p $OC_HOME
cd $OC_HOME

#2
if [ "$OS" == "x86_64" ]; 
 then
   #x64
   download http://svn.akazaresearch.com/oc/software/OpenClinica-3.1/linux/apache-tomcat-6.0.32.tar.gz
   download http://svn.akazaresearch.com/oc/software/OpenClinica-3.1/linux/jdk-6u24-linux-x64.bin	
   download http://svn.akazaresearch.com/oc/software/OpenClinica-3.1/linux/postgresql-8.4.1-1-linux-x64.bin
 else
  #x32
   download http://svn.akazaresearch.com/oc/software/OpenClinica-3.1/linux/apache-tomcat-6.0.32.tar.gz
   download http://svn.akazaresearch.com/oc/software/OpenClinica-3.1/linux/jdk-6u24-linux-i586.bin	
   download http://svn.akazaresearch.com/oc/software/OpenClinica-3.1/linux/postgresql-8.4.1-1-linux.bin
fi

#3
download https://community.openclinica.com/sites/fileuploads/akaza/cms-community/OpenClinica-3.1.4.1.zip
download https://community.openclinica.com/sites/fileuploads/akaza/cms-community/OpenClinica-ws-3.1.4.1.zip

#install java
echo -e "\n $bldblu Going to install Java 6 \t $txtrst"
chmod a+x jdk-6*
./jdk-6*
rm -rf /usr/local/jdk1*
rm -rf /usr/local/java
mv jdk1* /usr/local/
ln -s /usr/local/jdk1* /usr/local/java
echo "export JAVA_HOME=/usr/local/jdk1.6.0_24/" >> ~/.bashrc
export JAVA_HOME=/usr/local/jdk1.6.0_24/
echo -e "\n $bldylw Java has been installed \t $txtrst"

#install tomcat
echo -e "\n $bldblu Going to install Tomcat \t $txtrst"
cd $OC_HOME
tar -xvf apache-tomcat-* 2>&1 >/dev/null
rm -rf /usr/local/apache-tomcat-6.0.32/
mv apache-tomcat-6.0.32 /usr/local/
rm -f $CAT_HOME
ln -s /usr/local/apache-tomcat-6.0.32 $CAT_HOME
/usr/sbin/adduser tomcat
echo -e "\n $bldylw Making dir $CAT_HOME/oldwebapps $txtrst"
mkdir -p $CAT_HOME/oldwebapps
mv $CAT_HOME/webapps/* $CAT_HOME/oldwebapps
echo -e "\n $bldylw Tomcat has been installed \t $txtrst"

#install pgsql
echo -e "\n $bldblu Going to install PostgreSQL database \t $txtrst"
cd $OC_HOME
chmod a+x postgresql-8.4.*
./postgresql-8.4.* --mode text
echo -e "$bldcyn  Please, enter password \"postgres\" PostgreSQL database user (its need for setup procedure) and press [ENTER]: $txtrst"
read PPASSWD
echo -e "$bldcyn  Please, enter password for new PostgreSQL database clinica user (Please enter secure password) and press [ENTER]: $txtrst"
read NEW_USER_PWD
PGUSER=postgres
PGPASSWORD=$PPASSWD
export PGUSER PGPASSWORD
echo -e "$bldcyn  Please, enter DATA BASE NAME and press [ENTER] (standart db name: openclinica): $txtrst"
read DB_NAME

if [ -z "$DB_NAME" ]; then
    DB_NAME="openclinica"
fi
echo -e "\n $bldylw PostgreSQL database name is: $DB_NAME\t $txtrst"
/opt/PostgreSQL/8.4/bin/psql -U postgres -c "CREATE ROLE clinica LOGIN ENCRYPTED PASSWORD '$NEW_USER_PWD' SUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE"
/opt/PostgreSQL/8.4/bin/psql -U postgres -c "CREATE DATABASE $DB_NAME WITH ENCODING='UTF8' OWNER=clinica"
echo -e "\n $bldylw PostgreSQL database has been installed \t $txtrst"

#install OC
cd $OC_HOME
OC_NAME=$(ls OpenClinica*.zip | grep -iv ws)
unzip $OC_NAME
OC_NAME=$(echo $OC_NAME| awk -F '.zip' '{ print $1 }')
cd $OC_NAME/distribution
unzip OpenClinica.war -d OpenClinica
echo -e "\n $bldylw Coping to $CAT_HOME/webapps \t $txtrst"
cp -rf OpenClinica* $CAT_HOME/webapps
rm -f $CAT_HOME/webapps/OpenClinica.war
echo -e "\n $bldylw OpenClinica app has been copied to server dir \t $txtrst"

#install Web Services
cd $OC_HOME
unzip OpenClinica-ws*
cd OpenClinica-ws*/distribution
unzip OpenClinica-ws.war -d OpenClinica-ws
echo -e "\n $bldylw Coping to $CAT_HOME/webapps \t $txtrst"
cp -rf OpenClinica-ws* $CAT_HOME/webapps
rm -f $CAT_HOME/webapps/OpenClinica-ws.war
echo -e "\n $bldylw OpenClinica web services has been copied to server dir \t $txtrst"

#setup tomcat
echo -e "\n $bldblu Going to setup tomcat \t $txtrst"
cp $OC_HOME/$OC_NAME/install-docs/linux/tomcat /etc/init.d/
cd /etc/init.d
chmod a+x /etc/init.d/tomcat

if [ "$DIST" == "Ubuntu" ]; then
  update-rc.d tomcat defaults  
elif [ "$DIST" == "RHEL"  ]; then
  /sbin/chkconfig --add tomcat 
else
   echo -e "$bldred $0 Unknow dist. Please add \"/etc/init.d/tomcat\" to auto start manualy $txtrst" 
fi

chown -R tomcat:tomcat /usr/local/tomcat/*
chown -R tomcat:tomcat /usr/local/apache-*

chmod -R 777 /usr/local/tomcat/*
chmod -R 777 /usr/local/apache-*

echo -e "\n $bldylw Going to put main configs to  $CONFIG \t $txtrst"
sed -i -r 's/dbPass=.*/dbPass='$PPASSWD'/' $CONFIG
sed -i -r 's/db=.*/db='$DB_NAME'/' $CONFIG
sed -i -r 's/filePath=.*/filePath=\/home\/tomcat\/'/'' $CONFIG

echo -e "$bldcyn  Please, enter your email [ENTER] (standart db name: admin@example.com): $txtrst"
read EMAIL

if [ -z "$EMAIL" ]; then
    EMAIL="admin@example.com"
fi

sed -i -r 's/adminEmail=.*/adminEmail='$EMAIL'/' $CONFIG
echo -e "\n $bldylw Please NOTE other parameter you can change at $CONFIG \t $txtrst"

sleep 20
#/etc/init.d/tomcat start
#/etc/init.d/tomcat status
mkdir -p /home/tomcat/
mkdir -p /home/tomcat/xslt
mkdir -p /home/tomcatxslt

chown -R tomcat:tomcat /home/tomcat/
chown -R tomcat:tomcat /home/tomcat/xslt
chown -R tomcat:tomcat /home/tomcatxslt

chmod -R 777  /home/tomcat/
chmod -R 777  /home/tomcat/xslt
chmod -R 777  /home/tomcatxslt

/usr/local/apache-tomcat-6.0.32/bin/startup.sh

