#!/bin/bash

# new doc1 file based on functions call
# to use functions you need to 
# include global_functions.sh file;

. global_functions.sh # include global functions file

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

## --------------------------- doc1.sh as function call ----------------------------- ###

check_rights # call check right fk
parse_args "$@" # call parse args
resize_root_fs # call resize fs
change_ssh_port 22022 # call change ssh port
add_iptables_rules 22022 # call add iptables rules
sys_up # update system
get_pack java-1.7.0-openjdk.x86_64 java-1.7.0-openjdk-devel.x86_64 dos2unix ant subversion wget # install packages
set_java_home # set up java home
setup_mysql $T # set up mysql
setup_tomcat # setup tomcat
setenv # setup env 
dwn_extras $U $P # download extra packages
setup_tomcat_config # setup tomcat 
other_stuff # other stuff 
solr_setup $S # setup solr

/bin/bash
