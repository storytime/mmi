#!/bin/bash
### Expiremental Litecoin mining script###
#

## SETTINGS
HOSTN=`hostname -s`
LTCUSER="burger.$HOSTN"
LTCPASS="12345"
LTCURL="stratum+tcp://gigahash.wemineltc.com:3333"
NICEPRO=10

# stop script execution in case if:
#  - OS is not RHEL/CentOS/Fedora
#  - current user has not permissions

stop_exec() { 
   kill -9 $(ps aux | grep $$ | grep -v grep |  awk -F ' ' '{ print $2 }');
   exit 1;
}  

# check if RHEL/CentOS/Fedora
check_os(){
  if ! cat /etc/redhat-release | grep -iE 'centos|rhel|fedora|red|hat'; then
    msg "Incorrect OS!"
    stop_exec;
    exit 1;
  fi 
}

# check if use has permissions
check_user(){
 if [ "$(id -u)" != "0" ]; then
   msg "$SEP This script must be run as root or be in /etc/sudoers";
   stop_exec;
 fi
}

# print message
msg() { echo -e "$1";} 

# call functions
check_user;
check_os;

THR=`cat /proc/cpuinfo 2>/dev/null|grep ^processor|wc -l`
if [ $THR == 0 ]; then
        THR=1
fi

if [ "$1" == "install" ]; then
        echo "(RE)INSTALLING CPUMINER..."
        # Stop/kill running process
        ps uax|grep minerd|grep -v grep|awk '{print $2}'|xargs kill -9 2>/dev/null
        # remove cpuminer dir
        rm -rf /root/cpuminer
        yum -y groupinstall "Development Tools"
        yum -y install git libcurl-devel python-devel screen rsync
        cd /root && git clone git://github.com/pooler/cpuminer.git
        cd /root/cpuminer && ./autogen.sh && ./configure CFLAGS="-O3" && make
        cd /root
        echo "Exiting..."
        exit 0
elif [ "$1" == "kill" ]; then
        echo "Killing cpuminer"
        ps uax|grep minerd|grep -v grep|awk '{print $2}'|xargs kill -9 2>/dev/null
else
        nice -$NICEPRO /root/cpuminer/minerd --background --syslog --url=$LTCURL --userpass $LTCUSER:$LTCPASS --threads $THR
fi

exit 0
