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

## --------------------------- doc2.sh as function call ----------------------------- ###

check_rights # call check rights
check_return_resualt $? "check_rights"

check_os # call check_os
check_return_resualt $? "check_os"

parse_args_doc2 "$@" # call parse args method
check_return_resualt $? "parse_args_doc2 "

create_remove_dirs # call create/remove dirs
check_return_resualt $? "create_remove_dirs"

ch_code $T $U $P $S # call checkout code
check_return_resualt $? "ch_code"

change_prod_db_password $T # call change db
check_return_resualt $? "change_prod_db_password"

set_build_version $T $V # call set build version
check_return_resualt $? "set_build_version"

set_relative_url $T $R # call change relative url
check_return_resualt $? "set_relative_url"

change_prod_configs $T $D # call change prod configs
check_return_resualt $? "change_prod_configs"

build_eas $T # call build eas
check_return_resualt $? "build_eas"

build_notif_manager $T # call build notif manager
check_return_resualt $? "build_notif_manager"

swich_prod_configs $T # call swich prod configs
check_return_resualt $? "swich_prod_configs"

doc2_print_warn $T # call doc2 print warn
check_return_resualt $? "doc2_print_warn"

kill_main_services # kill main services
check_return_resualt $? "kill_main_services"

flyway_migration $T # call flyway migration
check_return_resualt $? "flyway_migration "

checkout_solr $T $U $P $S # call checkout solr from repo
check_return_resualt $? "checkout_solr"

prepare_solr $T $D # call prepare solr
check_return_resualt $? "prepare_solr"

up_solr $T # call up solr method
check_return_resualt $? "up_solr "

other_doc2_setup $T # call other setup
check_return_resualt $? "other_doc2_setup "

setup_notif_manager $T # call copy notification mamager
check_return_resualt $? "setup_notif_manager"

final_msg $T # call print final method
check_return_resualt $? "final_msg"


 
