#!/bin/bash

#https://docs.openclinica.com/3.1/installation/installation-linux

#check rights
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root or be in /etc/sudoers" 1>&2
   exit 1
fi

rm -rf usr/local/oc/install/
rm -rf /usr/local/apache-tomcat-6.0.32/
rm -rf /usr/local/jdk1.6.0_24/
rm -rf /opt/PostgreSQL/
userdel -r tomcat




