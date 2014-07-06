#!/bin/bash

## ------------------- declare vars section ------------------- ###

SEP="---------- ########## ###### ### # ================================================>\t"
A=""; # AWS access key:AWS secret key in such format - AWS_KEY:AWS_SECRET
B="SCRIPT_UPLPOADS"; # default bucket
LOG="/var/log/aws_sync.log"

# array of dirs to UPLOAD!
P=("." "/tmp/testSecondDir")

ACCESS_KEY=""; # AWS access key
SECRET_KEY=""; # AWS secret key
STD_ERR="/tmp/s3.tmp" # tmp log file

# print warning 
function msg() { echo -e "$1"; }

function msg_warn() { echo -e "$1"; }

#stop execution;  stop current process  and exit
function stop_exec() { kill -9 $$; rm -f $STD_ERR > /dev/null;}  

#check rights
function check_rights() {
 if [ "$(id -u)" != "0" ]; then
    msg_warn "$SEP This script must be run as root or be in /etc/sudoers";
    stop_exec;
 fi
}

#print help doc1
function sc_help() {
  msg_warn "\nscript usage: -a ACCESS_KEY:SECRET:KEY"

  msg_warn "Params:  -a - ACCESS_KEY:SECRET:KEY - AWS keys"
  stop_exec;
}

# print greetings
function sc_greeting() {
    msg "\nSCRIPT EXECUTED WITH NEXT PARAMETERS:\n"
    msg "-a - AWS keys(Can be empty): $A\n"
   # read -sn 1 -p "Check them and press any key to continue... Ctrl+C to exit."
    # msg "\n"
}

#compare arg count
function compare_count() {
 if [ "$1" -ge $2 ] 
  then
    return $SUCCESS
  else 
    return $E_UNKNOW
  fi
}


#parse command line arguments
function parse_args() {
if (compare_count "$#" 0 ) #call compare; at least 4; -l PATH_TO_LOG -a ACCESS_KEY:SECRET:KEY 	
   then
      msg "$SEP Parsing params... $#"	

	while getopts "a:" opt; do
	  case "$opt" in
	   a) A=$OPTARG;;
	  esac
	 done
      #sc_greeting; #call greetings function
   else   
      sc_help; #call help
   fi
}

#check main tools and install it's if any.
function check_s3cmd(){

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
function check_s3cnf(){
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
function check_s3_connect(){
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
  
  msg "\n$SEP: Starting new sync session!" >> $LOG

  for t in "${P[@]}"
    do

       NF=0 #new files
       CF=0 #changed files

       CUR_DIR="$(echo $t | awk -F '/' '{ print $NF }')"

      if [ "$t" == "." ]; then
        t=$(pwd)
        CUR_DIR="$(echo $t | awk -F '/' '{ print $NF }')"
      fi

       msg "\n$SEP: Sync dir full path: $t"
       msg "$SEP: Sync current dir: $CUR_DIR"
       msg "Starting folder: $t" >> $LOG

       msg "Syncing for alot of files its can take alot of time! SCRIPT IS EXECUTED, NOT HUG!" >> $LOG
       s3cmd mb s3://$B >> /dev/null
       tt=$(s3cmd sync $t s3://$B/  | awk -F ' ' '{ print $2 }' | tr -d "\'" )

      if [ "$tt" != "" ]; then        
           while read -r file; do
             let NF++
             msg "$SEP: $file"
             echo -e "\tProcessing file, new file $NF: $file " >> $LOG
           done <<< "$tt"
      fi


       msg "\n$SEP Checking new files in: $B/$CUR_DIR/"

       s3=$(s3cmd ls --list-md5 -H s3://$B/$CUR_DIR/)
       s3_list=`echo "$s3"|awk {'print $4" "$5'} | sed 's= .*/= ='`
       # msg "\n$SEP S3:\n$s3"

       locally=`md5sum "$t"/* 2>/dev/null`;

       locally_list=$(echo "$locally" | sed 's= .*/= =');
       # msg "\n$SEP L:\n$locally\n"

      IFS=$'\n'
        for i in $locally_list
        do

          locally_hash=`echo $i|awk {'print $1'}`
          locally_file=`echo $i|awk {'print $2'}`

        for j in $s3_list
          do
            s3_hash=$(echo $j|awk {'print $1'}); 
            s3_file=$(echo $j|awk {'print $2'});

            #to avoid empty file when have only hash from folder
            #if [[ $s3_hash != "" ]] && [[ $s3_file != "" ]]; then 
              if [[ $s3_hash != $locally_hash ]] && [[ $s3_file == $locally_file ]]; then
                echo "### FILE CHANGED: $t/$locally_file";
                files_list=$(s3cmd -r put $t/$locally_file s3://$B/$CUR_DIR/ |  awk -F ' ' '{ print $2 }' | tr -d "\'")

                 while read -r file; do
                  let CF++
                  msg "$SEP: $file"
                  echo -e "\tUpdating file $CF: $file " >> $LOG
                done <<< "$files_list"
              fi
            #fi
         done
        done
      unset IFS

    msg "### ============> DIR INFO: new files: $NF; updated file: $CF <============ ###\n" >> $LOG
    done

      msg "$SEP: ############# Finish the session!" >> $LOG
  }



## -------------------CALL MAIN FUNCTIONS  ------------------- ###

check_rights
check_s3cmd
parse_args "$@"
check_s3cnf
check_s3_connect
s3_sync
msg "\n$SEP SUCCESS! Execuded without error."


# for t in "${P[@]}"
# do
#   echo $t
