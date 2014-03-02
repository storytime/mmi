#!/bin/bash

## ------------------- declare vars section ------------------- ###

SEP="---------- ########## ###### ### # ================================================>\t"
L=""; # path to log file
A=""; # AWS access key:AWS secret key in such format - AWS_KEY:AWS_SECRET
R=""; # recursive
D="30"; # default mod time; 
B="speechpad-log-archive"; # default bucket
P="www1"; # default path 
ACCESS_KEY=""; # AWS access key
SECRET_KEY=""; # AWS secret key
STD_ERR="/tmp/s3.tmp" # tmp log file
BLIST=""; # list of buckets 
s3_link="" # path to s3
X=""; # compress
V=""; # verbose


## -------------------RETURN CODES  ------------------- ###
SUCCESS=0;
E_UNKNOW=1;

#print message
msg() { 
   if [ "$V" == "Yes" ]
    then
      echo -e "$1";
    fi
}

# print warning 
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
  msg_warn "\nscript usage:   $0 -l PATH_TO_LOG -a ACCESS_KEY:SECRET:KEY [-r] [-d X] [-b Y] [-p Z] [-x]"
  msg_warn "script usage: 	$0 -l apache.log -a 00000:abcde -d 60 -b bucket_s3 -p www1 -x -v"
  msg_warn "script usage: 	$0 -l apache.log -a 00000:abcde -b bucket_s3 -p www1 -x"
  msg_warn "script usage: 	$0 -l /var/log/boot.log -b speechpad-log-archive2 -p www1 -x"
  msg_warn "script usage: 	$0 -l /var/log/ -r -b speechpad-log-archive2 -p www1 -v -x\n"


  msg_warn "Params:  	-l - Path to log file
                -a - ACCESS_KEY:SECRET:KEY - AWS keys
	        -r - switch for recursive
                -x - compress locally before upload (recommend to use)
          	-d X - switch to archive files with modtime older than X days (default 30)
          	-b Y - switch to specify S3 bucket Y to use for archive (default speechpad-log-archive)
          	-p Z - switch to specify the path within the S3 bucket to drop the files (default to system's hostname, eg. www1, www2, etc)"
 stop_exec;
}

# print greetings
sc_greeting() {
   if [ "$V" == "Yes" ]
    then
        msg "\nSCRIPT EXECUTED WITH NEXT PARAMETERS:\n"
        msg "-l - Log file: $L\n"
        msg "-a - AWS keys(Can be empty): $A\n"
        msg "-r - Recursive: $R\n"  
        msg "-d - Mod time older then days: $D\n"
        msg "-b - S3 bucket: $B\n"
        msg "-p - Path int S3 bucket: $P\n"
        msg "-x - Compress: $X\n"
        msg "-v - Verbose: $V\n"
        read -sn 1 -p "Check them and press any key to continue... Ctrl+C to exit."
        msg "\n"
   fi 
  return $SUCCESS
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
if (compare_count "$#" 3 ) #call compare; at least 4; -l PATH_TO_LOG -a ACCESS_KEY:SECRET:KEY 	
   then
      msg "$SEP Parsing params... $#"	

	while getopts "l:a:d:b:p:rxv" opt; do
	  case "$opt" in
	   l) L=$OPTARG;;
	   a) A=$OPTARG;;
	   d) D=$OPTARG;;
	   b) B=$OPTARG;;
	   p) P=$OPTARG;;
	  esac
	 done

     # Dirs
     if [ -z $(echo "$@" | grep -ohi "\-r") ]
    	 then
          R="No"
       else
          R="Yes"	
     fi   

     # compress
     if [ -z $(echo "$@" | grep -ohi "\-x") ]
    	 then
           X="No"
    	 else
           X="Yes"	
     fi    

     # Verbose
     if [ -z $(echo "$@" | grep -ohi "\-v") ]
        then
          V="No"
        else
          V="Yes"
     fi   

      sc_greeting; #call greetings function
   else 
      sc_help; #call help
   fi
}

#check main tools and install it's if any.
check_s3cmd(){
# if [ -z $(dpkg -l | grep s3cmd | awk -F ' ' '{ print $2 }') ] 
#   then
	msg "\n$SEP $0 Installing s3cmd and additonal packages. Please wait ..."
   	apt-get --force-yes -y  install s3cmd python-magic dos2unix gzip > /dev/null
 #  fi
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

# check if s3 buckek exists
check_s3_bucket(){
  s3cmd ls > $STD_ERR
  BLIST=$(cat $STD_ERR | awk -F '\/\/' '{ print $2 }' |  grep -ix $B)

  if [[ -z $BLIST ]]
   then 
      msg "\n$SEP ERROR!!! No \"$B\" bucket! Please existing bucket." 
      msg "$SEP List of buckets, use one of them:\n\n$(cat $STD_ERR | awk -F '\/\/' '{ print $2 }')"
      echo -e "\n" 
      stop_exec;
   else
      msg "$SEP SUCCESS! Bucket \"$B\" will be used."
  fi
}

# check s3 bucket dirs
check_s3_bucket_dirs(){
 s3_link="s3://$B"
 s3cmd ls $s3_link > $STD_ERR
 s3_dirs=$(cat $STD_ERR | awk -F '//' '{ print $2 }' | awk -F '/' '{ print $2 }')
 # echo "P: $P"

 s3_dir=$(cat $STD_ERR | awk -F '//' '{ print $2 }' | awk -F '/' '{ print $2 }' | tr '\n' ' ') ### !!!!
 s3_dir=$(echo $s3_dir | grep $P)
 # echo "$s3_dir dir"
 #echo " $(echo $s3_dir | grep $P)"

 s3_link=$s3_link"/$P"

  if [[ -z $s3_dir ]]
   then 
      msg "\n$SEP ERROR!!! No \"$P\" dir in bucket! Please use existing dir." 
      msg "$SEP List of S3 objects, in \"$B\" bucket, use one of them:\n\n$s3_dirs"
      echo -e "\n" 
      stop_exec;
   else
      msg "$SEP SUCCESS! Dir \"$P\" form bucket \"$B\" will be used."
  fi
}

#check local file from command line
check_local_data(){
  if [ "$R" == "No" ]
     then
	msg "\n$SEP INFO. Searching for file: $L"
	res="$(ls $L 2> /dev/null | grep $L)"

	if [[ -z $res ]]
	   then 
	     msg "$SEP ERROR! Can not found local log file: $L"
	     stop_exec;
	   else
	     msg "$SEP SUCCESS! Found local log file: $L"
	fi
   fi
}

# upload or compress and upload one files
upload_one_file(){

 f=$1

   if [ "$X" == "Yes" ]
      then
        msg "$SEP INFO. Going to compress file: $1"
        gzip -8 $1 2> /dev/null
	# rm -f $L > /dev/null
        f=$1".gz"
        msg "$SEP INFO. Compressed: $f"
   fi 

    s3_path=$s3_link/$(echo $f | awk -F '/' '{ print  $NF }')
    s3cmd put --progress $f $s3_path 2> $STD_ERR
    err=$(cat $STD_ERR)

   if [[ ! -z $err ]]
        then 
          msg "$SEP ERROR! Could not upload file: $f to S3."
          stop_exec;
        else
	  #rm -rf $L > /dev/null
          msg "$SEP SUCCESS! File has been uploaded: $s3_path"
	  msg "$SEP INFO. File has been removed: $f\n"
   fi
}

# upload one dir
upload_one_dir(){
file_list=$(find $L -maxdepth 1 -mtime +$D -type f -printf '%f\n') #-mtime +$D
msg "$SEP INFO. File list: $file_list"
  
   for file in $file_list 
   do
       upload_one_file $L$file
   done
}

## -------------------CALL MAIN FUNCTIONS  ------------------- ###

check_rights
check_s3cmd
parse_args "$@"
check_s3cnf
check_s3_connect
check_s3_bucket
check_s3_bucket_dirs
msg "$SEP SUCCESS! Path checked! Path to upload: $s3_link/"
check_local_data

if [ "$R" == "Yes" ]
 then 
   upload_one_dir
 else
   upload_one_file $L
fi



msg "\n$SEP SUCCESS! Execuded without error."

#  AKIAIN5HPWEKQR4LPJXA
#  obo8xkY5B8Tya0O535Znrl2nm1dOBaCvN9CotgBJ	
#  ./archive_to_s3.sh -l apache.log - -b bucket_s3 -p /tmp/
