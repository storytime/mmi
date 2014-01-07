#!/bin/bash

# new doc1 file based on functions call
# to use functions you need to 
# include global_functions.sh file;

. global_functions.sh

## ------------------- call functions sections (all for doc1.sh)--------------------- ###
## --------------------------- doc1.sh as function call ----------------------------- ###
check_rights
parse_args "$@"
resize_root_fs
change_ssh_port 22022
add_iptables_rules 22022
sys_up
get_pack java-1.7.0-openjdk.x86_64 java-1.7.0-openjdk-devel.x86_64 dos2unix ant subversion wget 
set_java_home
setup_mysql $T
setup_tomcat
setenv
dwn_extras $U $P
setup_tomcat_config
other_stuff
solr_setup $S
