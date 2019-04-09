#!/bin/bash

# set APP ENV vars
printenv | grep APP_ | sed 's/^\(.*\)$/export \1/g' > /etc/profile.d/app-env.sh

# database connection test
while ! su -c "otrs.Console.pl Maint::Database::Check" otrs; 
do 
    sleep 1;
done

# run services
exec supervisord