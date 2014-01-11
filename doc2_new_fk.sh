#!/bin/bash

# new doc2 file based on functions call
# to use functions you need to 
# include global_functions.sh file;

. global_functions.sh # include global functions file

## ------------------- declare vars section------------------- ###

trap '' INT
P=""
U=""
T=""
S=""
SEP="---------- DOC2 ####### ###### ### # =========================================================>\t"
V=""
D=""
R=""

## --------------------------- doc1.sh as function call ----------------------------- ###

check_rights # call check rights
check_os # call check_os
parse_args_doc2 "$@" # call parse args method
create_remove_dirs # call create/remove dirs
ch_code $T $U $P $S # call checkout code
change_prod_db_password $T # call change db
set_build_version $T $V # call set build version
set_relative_url $T $R # call change relative url
change_prod_configs $T $D # call change prod configs
build_eas $T # call build eas
build_notif_manager $T # call build notif manager
swich_prod_configs $T # call swich prod configs
doc2_print_warn $T # call doc2 print warn
kill_main_services # kill main services
flyway_migration $T # call flyway migration
checkout_solr $T $U $P $S # call checkout solr from repo
prepare_solr $T $D # call prepare solr
up_solr $T # call up solr method



 
