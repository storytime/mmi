Scripts
===

Some different shell/bash scripts


### MMI

Motivate Media Intelligence scripts - mm1/

Script to automate the deployment and configuration process of Java web application that runs in the Amazon cloud.

##### doc1_new_fk.sh:
###### script usage:  

    ./doc1_new_fk.sh -u USER -p PASSWORD -t prod or test -s y OR n 
    ./doc1_new_fk.sh -u bogdan -p qwerty -t test -s n 

###### Params

    -u - SVN user
    -p - SVN password
    -t - Environment (prot/test)
    -s - Install Solr (y/n - yes/no)
    
##### doc2_new_fk.sh:
###### script usage:   
    
    ./doc2_new_fk.sh -u USER -p PASSWORD -s sprint_name -t prod or test (all other args will be use as test) -r relative_host_url -v 1.2.4 -p db_password 
    ./doc2_new_fk.sh -u bogdan -p qwerty -t test -v 1.2.4 -r relative_host_url
    ./doc2_new_fk.sh -u bogdan -p qwerty -t test -v 1.2.4
    ./doc2_new_fk.sh -s sprint13_130916 -u bogdan -p qwerty -t prod -r relative_host_url -v 1.2.4 -d db_password     #will set prod db password: db_password 
    ./doc2_new_fk.sh -s sprint13_130916 -u bogdan -p qwerty -t prod -r relative_host_url -v 1.2.4 -d default     #default password will be used 
    ./doc2_new_fk.sh -s sprint13_130916 -u bogdan -p qwerty -t prod -r relative_host_url -v 1.2.4 -d     #will delete prod db password from all configs 
    ./doc2_new_fk.sh -s sprint_name -u bogdan -p qwerty -r relative_host_url -t BLA_BLA_INFO -v 1.2.4 

###### Params
    -u - SVN user
    -p - SVN password
    -t - Environment (prot/test)
    -s - Sprint name
    -r - Host relative URL
    -v - App version
    -d - DB password/default (default - leave default, password - new password )
    
<a href="http://i.imgur.com/9bPGvrG.png"><img src="http://i.imgur.com/9bPGvrG.png" title="Hosted by imgur.com" /></a>


### Open Clinica
Open Clinica scripts - open_clinica/

### Lyc
Lyc scripts - lyc/

### Other scripts
##### archive_to_s3.sh
archive_to_s3.sh - put files to AWS S3 bucket

###### script usage:  

    ./archive_to_s3.sh -l PATH_TO_LOG -a ACCESS_KEY:SECRET:KEY [-r] [-d X] [-b Y] [-p Z] [-x]
    ./archive_to_s3.sh -l apache.log -a 00000:abcde -d 60 -b bucket_s3 -p www1 -x -v
    ./archive_to_s3.sh -l apache.log -a 00000:abcde -b bucket_s3 -p www1 -x
    ./archive_to_s3.sh -l /var/log/boot.log -b speechpad-log-archive2 -p www1 -x
    ./archive_to_s3.sh -l /var/log/ -r -b speechpad-log-archive2 -p www1 -v -x

###### Params:  

    -l - Path to log file or dir
    -a - ACCESS_KEY:SECRET:KEY - AWS keys
    -r - switch to recursive
    -x - compress localy before upload
    -d X - specify date to archive files with modtime older than X days (default 30)
    -b Y - specify S3 bucket Y to use for archive (default speechpad-log-archive)
    -p Z - specify the Z path/dir in S3 bucket (default to system's hostname, eg. www1, www2, etc)
    
<a href="http://i.imgur.com/I3ymQL6.png"><img src="http://i.imgur.com/I3ymQL6.png" title="Hosted by imgur.com" /></a>

##### s3_sync.sh
s3_sync.sh - sync files with AWS S3 bucket

###### script usage:  

    ./s3_sync.sh -a ACCESS_KEY:SECRET:KEY
    ./s3_sync.sh -p PATH_TO_SYNC_DIR


###### Params:  

    -a - ACCESS_KEY:SECRET:KEY - AWS keys
    -p - Path to sync dir 
    
<a href="http://i.imgur.com/7qJ3m23.png"><img src="http://i.imgur.com/7qJ3m23.png" title="Hosted by imgur.com" /></a>


