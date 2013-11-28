#!/bin/sh

# http://ec2-54-219-59-129.us-west-1.compute.amazonaws.com:8983/solr/
# ssh -p22022 -i .ssh/motive2Key.pem root@ec2-54-219-59-129.us-west-1.compute.amazonaws.com

P=""
U=""
T=""
S=""
V=""

#check rights
if [ "$(id -u)" != "0" ]; then
   echo -e "This script must be run as root or be in /etc/sudoers to exec sudo -s\n" 1>&2
   exit 1
fi

#check OS 
if ! cat /etc/redhat-release | grep -iE 'centos|rhel|fedora|red|hat'; then
    echo -e "\nIncorrect OS!\n"
    exit 1;
fi

#parse args
if [ "$#" -eq 10 ]
then
        echo -e "\t\t Parsing params..."
        while getopts "u:p:t:s:v" opt; do
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
            esac
        done
        echo -e "\tSCRIPT EXECUTED WITH NEXT PARAMETERS:\n"
        echo -e "-u - SVN USER: $U\n"
        echo -e "-p - SVN PASSWORD: $P\n"       
        echo -e "-t - ENVIRONMENT: $T\n"
        echo -e "-s - SPRINT NAME: $S\n"
        echo -e "-v - VERSION: $V\n"
        read -sn 1 -p "Check them and press any key to continue..."
        echo -e "\n"
else
  echo -e "\nscript usage:\n"
  echo -e "$0 -u USER -p PASSWORD -s sprint_name -t prod or test (all other args will be use as test) -v 1.2.4\n"
  echo -e "Example1: $0 -u bogdan -s sprint_name -p qwerty -t test -v 1.2.4\n"
  echo -e "Example2: $0 -u bogdan -s sprint_name -p qwerty -t prod -v 1.2.4\n"
  echo -e "Example3: $0 -u bogdan -s sprint_name -p qwerty -t BLA_BLA_INFO -v 1.2.4 \n"
  exit 1;
fi


#create test dir
mkdir -p ~/build/
cd ~/build/

#check server type 
#  trunk/ - test
#  prod/ - prod
#--------------------------------------------------------------------------------------------------------------------------------------#
if [ "$T" == "prod" ]
then
    #PROD SERVER

    #set custom.properties
    sed -i -r 's/build_version=.*/build_version='$V'/'  ~/build/trunk/eas/resources/custom.properties_prod
    svn checkout https://motive.svn.beanstalkapp.com/eas/branches/$S/ prod/ --username=$U --password=$P
    cd ~/build/prod/eas/resources/	
    cd ~/build/prod/eas/
    #build
    ant -f build-eas.xml clean war-production
    #build notif. manager
    cd ~/build/prod/notification-manager
    ant -f build.xml clean build-prod

    #Switch the flyway parameter file for production only 
    cd ~/build/prod/flyway-2.2.1/conf
    cp -rf flyway.properties_prod flyway.properties
    #Switch the solr parameter file for production only (point to RDS database):
        #PLEASE NOTE!
        #In these config (flyway.properties and solr-eas-config.xml) used user/password
        #user="eas" password="1eas2eas!". As we discussed in Skype. This user in ONLY FOR 
        #PRODUCTION AND I WILL BE CREATED AUTOMATICALLY ETC.
    cd ~/build/prod/solr/new_mentor/solr/eas/conf
    cp -rf solr-eas-config_prod.xml solr-eas-config.xml
    
    #Solr files
    echo -e "Solr files: ~/build/prod/solr/new_mentor/\n"
    echo -e "Flyway migration files: ~/build/prod/flyway-2.2.1/\n"
    echo -e "eas.war: ~/build/prod/eas/output/dist/eas.war\n"
    echo -e "\t Going to stop sorl, tomcat and notification.\n"
    kill -9 $(ps aux | grep -v grep | grep -i notifications | grep -i jar |  awk -F ' ' '{ print $2 }')
    kill -9 $(ps aux | grep -v grep | grep -i solr |  awk -F ' ' '{ print $2 }')
    kill -9 $(ps aux | grep -v grep | grep -i tomcat | grep -iv grep |  awk -F ' ' '{ print $2 }')
    # mysql -u eas -p1eas2eas! -h eas-prod-db.ccc4r0vems7f.us-west-1.rds.amazonaws.com
    
    #Flyway migration - use  flyway.properties
    cd	 ~/build/prod/flyway-2.2.1
    chmod +x flyway
    ./flyway -X migrate 

    #solr part
    read -sn 1 -p 'Solr deployment part!..';echo
    cd /usr/local/solr/prod/new_mentor
    rm -rf solr/
    svn checkout https://motive.svn.beanstalkapp.com/eas/branches/$S/solr/new_mentor/solr/ solr/  --username=$U --password=$P
    cd /usr/local/solr/prod/new_mentor/solr
    cp /usr/local/solr/prod/start.jar .
    cd /usr/local/solr/prod
    touch solr.sh
    chmod +x solr.sh
    echo -e "java -Dsolr.solr.home=/usr/local/solr/prod/new_mentor/solr/ -jar start.jar > /usr/local/solr/prod/new_mentor/solr/solr.log 2>&1 &" > solr.sh
    ./solr.sh
    read -sn 1 -p 'Going to start solr. Press any key to continue... and wait 45 sec.';echo
    sleep 45

    #other setup
    cd /usr/local/tomcat7/webapps/
    rm -f ROOT.war
    rm -rf ROOT/
    cp ~/build/prod/eas/output/dist/eas.war ROOT.war
    service tomcat7 start

   #Copy notification manager files:
   cd /usr/eas/notifications/
   cp ~/build/prod/notification-manager/notifications.jar .
   cp ~/build/prod/notification-manager/custom.properties .
   cp ~/build/prod/notification-manager/notifications.sh .
   cp ~/build/prod/notification-manager/src/log4j.properties_prod log4j.properties
   cp ~/build/prod/notification-manager/new_user.st .
   cp ~/build/prod/notification-manager/password_reset.st .
   cp ~/build/prod/notification-manager/review_request.st .
   cp ~/build/prod/notification-manager/review_request.st .
   chmod +x notifications.sh
   sed -i -e 's/\r$//' notifications.sh
   ./notifications.sh /dev/null 2>&1

#--------------------------------------------------------------------------------------------------------------------------------------#
else
    #TEST SERVER

    #set custom.properties
    sed -i -r 's/build_version=.*/build_version='$V'/'  ~/build/trunk/eas/resources/custom.properties_prod

    svn checkout https://motive.svn.beanstalkapp.com/eas/trunk/ trunk/ --username=$U --password=$P    
    cd ~/build/trunk/eas/resources/
    cd ~/build/trunk/eas/
    #build
    ant -f build-eas.xml clean war-awstest
    #build notif. manager
    cd ~/build/trunk/notification-manager
    ant -f build.xml clean build-awstest 

    #Switch the flyway parameter file for production only 
    #dont needed
    
    #Solr files
    echo -e "Solr files: ~/build/trunk/solr/new_mentor/\n"
    echo -e "Flyway migration files: ~/build/trunk/flyway-2.2.1/\n"
    echo -e "eas.war: ~/build/trunk/eas/output/dist/eas.war\n"
    echo -e "\t Going to stop sorl, tomcat and notification.\n"
    kill -9 $(ps aux | grep -iv grep | grep -i notifications | grep -i jar |  awk -F ' ' '{ print $2 }')
    kill -9 $(ps aux | grep -v grep | grep -i solr |  awk -F ' ' '{ print $2 }')
    kill -9 $(ps aux | grep -i tomcat | grep -iv grep |  awk -F ' ' '{ print $2 }')
    # mysql -u eas -p1eas2eas! -h eas-prod-db.ccc4r0vems7f.us-west-1.rds.amazonaws.com
    
    #Flyway migration - use  flyway.properties
    cd	 ~/build/trunk/flyway-2.2.1
    chmod +x flyway
    ./flyway -X migrate

    #solr part
    read -sn 1 -p 'Solr deployment part! Press any key to continue...';echo
    cd /usr/local/solr/trunk/new_mentor
    rm -rf solr/
    svn checkout https://motive.svn.beanstalkapp.com/eas/trunk/solr/new_mentor/solr/ solr/  --username=$U --password=$P
    cd /usr/local/solr/trunk/new_mentor/solr
    cp /usr/local/solr/trunk/start.jar .
    cd /usr/local/solr/trunk  
    chmod +x solr.sh
    echo -e "java -Dsolr.solr.home=/usr/local/solr/trunk/new_mentor/solr/ -jar start.jar > /usr/local/solr/trunk/solr/solr.log 2>&1 &" > solr.sh
    ./solr.sh
    read -sn 1 -p 'Going to start solr. Press any key to continue... and wait 45 sec.';echo
    sleep 45

    #other setup
    cd /usr/local/tomcat7/webapps/
    rm -f ROOT.war
    rm -rf ROOT/
    cp ~/build/trunk/eas/output/dist/eas.war ROOT.war
    service tomcat7 start
     
   #Copy notification manager files:
   cd /usr/eas/notifications/
   cp ~/build/trunk/notification-manager/notifications.jar .
   cp ~/build/trunk/notification-manager/custom.properties .
   cp ~/build/trunk/notification-manager/notifications.sh .
   cp ~/build/trunk/notification-manager/src/log4j.properties_prod log4j.properties
   cp ~/build/trunk/notification-manager/new_user.st .
   cp ~/build/trunk/notification-manager/password_reset.st .
   cp ~/build/trunk/notification-manager/review_request.st .
   cp ~/build/trunk/notification-manager/review_request.st .
   chmod +x notifications.sh
   sed -i -e 's/\r$//' notifications.sh
   ./notifications.sh /dev/null 2>&1

fi

read -sn 1 -p "Server: $T has been configured. Then press any key to exit... and wait 4-5min. Tomcat is starting!"
echo -e "\n"


