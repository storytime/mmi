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
check_return_resualt $? "check_rights"

parse_args "$@" # call parse args
check_return_resualt $? ""

resize_root_fs # call resize fs
check_return_resualt $? "resize_root_fs"

change_ssh_port 22022 # call change ssh port
check_return_resualt $? "change_ssh_port"

add_iptables_rules 22022 # call add iptables rules
check_return_resualt $? "add_iptables_rules"

sys_up # update system
check_return_resualt $? "sys_up"

get_pack java-1.7.0-openjdk.x86_64 java-1.7.0-openjdk-devel.x86_64 dos2unix ant subversion wget # install packages
check_return_resualt $? "get_pack"

set_java_home # set up java home
check_return_resualt $? "set_java_home"

setup_mysql $T # set up mysql
check_return_resualt $? "setup_mysql"

setup_tomcat # setup tomcat
check_return_resualt $? "setup_tomcat"

setenv # setup env 
check_return_resualt $? "setenv"

dwn_extras $U $P # download extra packages
check_return_resualt $? "dwn_extras"

setup_tomcat_config # setup tomcat 
check_return_resualt $? "setup_tomcat_config"

other_stuff # other stuff 
check_return_resualt $? "other_stuff"

solr_setup $S # setup solr
check_return_resualt $? "solr_setup"

/bin/bash
