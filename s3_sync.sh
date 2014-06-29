#!/bin/bash

## ------------------- declare vars section ------------------- ###

SEP="---------- ########## ###### ### # ================================================>\t"
A=""; # AWS access key:AWS secret key in such format - AWS_KEY:AWS_SECRET
B="SCRIPT_UPLPOADS"; # default bucket
B_PATH="UPLOADS"
P="."; # default path 

ACCESS_KEY=""; # AWS access key
SECRET_KEY=""; # AWS secret key
STD_ERR="/tmp/s3.tmp" # tmp log file

# print warning 
msg() { echo -e "$1"; }

msg_warn() { echo -e "$1"; }

#stop execution;  stop current process  and exit
stop_exec() { kill -9 $$; rm -f $STD_ERR > /dev/null;}  

#check rights
check_rights() {
 if [ "$(id -u)" != "0" ]; then
    msg_warn "$SEP This script must be run as root or be in /etc/sudoers";
    stop_exec;
 fi
}

#print help doc1
sc_help() {
  msg_warn "\nscript usage:   $0 -p PATH_TO_DIR -a ACCESS_KEY:SECRET:KEY"

  msg_warn "Params:  	-p - Path to log file
                      -a - ACCESS_KEY:SECRET:KEY - AWS keys"
  stop_exec;
}

# print greetings
sc_greeting() {
    msg "\nSCRIPT EXECUTED WITH NEXT PARAMETERS:\n"
    msg "-p - Path: $P\n"
    msg "-a - AWS keys(Can be empty): $A\n"
   # read -sn 1 -p "Check them and press any key to continue... Ctrl+C to exit."
    # msg "\n"
}

#compare arg count
compare_count() {
 if [ "$1" -ge $2 ] 
  then
    return $SUCCESS
  else 
    return $E_UNKNOW
  fi
}

#parse command line arguments
parse_args() {
if (compare_count "$#" 2 ) #call compare; at least 4; -l PATH_TO_LOG -a ACCESS_KEY:SECRET:KEY 	
   then
      msg "$SEP Parsing params... $#"	

	while getopts "a:p:" opt; do
	  case "$opt" in
	   a) A=$OPTARG;;
	   p) P=$OPTARG;;
	  esac
	 done
      sc_greeting; #call greetings function
   else   
      sc_help; #call help
   fi
}

#check main tools and install it's if any.
check_s3cmd(){

	msg "\n$SEP $0 Installing s3cmd and additonal packages. Please wait ..."

 PACK=$(which s3cmd | grep s3cmd)

 if [[ -z "$PACK" ]]
   then
      grep "centos" /etc/issue -i -q
      if [ $? = '0' ];then
        yum install -y wget > /dev/null
        wget http://s3tools.org/repo/RHEL_6/s3tools.repo -P /etc/yum.repos.d/ > /dev/null
        yum -y install s3cmd  s3cmd python-magic dos2unix gzip > /dev/null
      else 
        apt-get --force-yes -y  install s3cmd python-magic dos2unix gzip > /dev/null
      fi
   fi
}

#check s3 config
check_s3cnf(){
  if [[ ! -z "$A" ]]
   then 
    wget -q http://pastebin.com/download.php?i=9RSaMiRk -O ~/.s3cfg
    dos2unix ~/.s3cfg
    ACCESS_KEY=$(echo $A | awk -F ':' '{ print $1 }')
    SECRET_KEY=$(echo $A | awk -F ':' '{ print $2 }')
    msg "\n$SEP Access key: $ACCESS_KEY;\t Secret key: $SECRET_KEY;"
    msg "$SEP Please note! -a needed only once - to set up  ~/.s3cfg. In next cases you can run $0 without -a"
    sed -i "s/access_key.*/access_key = $ACCESS_KEY/g" ~/.s3cfg
    sed -i "s/secret_key.*/secret_key = $SECRET_KEY/g" ~/.s3cfg
    msg "\n$SEP SUCCESS! Please run: $0 -p PATH_TO_DIR"
    exit 0; 
  fi


}

# check s3 connect
check_s3_connect(){
  s3cmd ls 2> $STD_ERR 1 > /dev/null #!!!
  s3_conn=$(cat $STD_ERR)
  if [[ -z "$s3_conn" ]]
   then
     msg "\n$SEP SUCCESS! Test connect to AWS S3 performed without problems." 
   else
     msg "\n$SEP ERROR!!! Can not connect to AWS S3.\nError: $s3_conn" 
     stop_exec;
  fi
}

function s3_sync(){

   msg "\n$SEP Sync ... "

   s3cmd mb s3://$B >> /dev/null
   s3cmd sync $P s3://$B/

   msg "\n$SEP Checking new files "
   s3=$(s3cmd ls --list-md5 -H s3://$B/)
   s3_list=`echo "$s3"|awk {'print $4" "$5'} | sed 's= .*/= ='`
   # msg "\n$SEP S3:\n$s3"

   locally=`md5sum "$P"/* 2>/dev/null`;
   locally_list=$(echo "$locally" | sed 's= .*/= =');
   # msg "\n$SEP LOCAL:\n $locally_list";

IFS=$'\n'
  for i in $locally_list
  do
    #echo $i
    locally_hash=`echo $i|awk {'print $1'}`
    locally_file=`echo $i|awk {'print $2'}`


  for j in $s3_list
    do
      s3_hash=$(echo $j|awk {'print $1'}); 
      s3_file=$(echo $j|awk {'print $2'});

      #to avoid empty file when have only hash from folder
      #if [[ $s3_hash != "" ]] && [[ $s3_file != "" ]]; then 
        if [[ $s3_hash != $locally_hash ]] && [[ $s3_file == $locally_file ]]; then
          echo "### FILE CHANGED: $locally_file";
          s3cmd -r put $locally_file s3://$B
        fi
      #fi
   done

  done
unset IFS

}



## -------------------CALL MAIN FUNCTIONS  ------------------- ###

check_rights
check_s3cmd
parse_args "$@"
check_s3cnf
check_s3_connect
s3_sync
msg "\n$SEP SUCCESS! Execuded without error."