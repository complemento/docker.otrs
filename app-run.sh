#!/bin/bash

INITSCREEN_DIR=/var/www/html
PROGRESSBAR_FILE=$INITSCREEN_DIR/progress.txt
START_BACKEND=${START_BACKEND:-1}

echo "5" > $PROGRESSBAR_FILE


# init-screen
sudo perl $INITSCREEN_DIR/httpserver.pl > /dev/null 2>&1 &
INITSCREEN_PID=$!

# set APP ENV vars
sudo bash -c 'printenv | grep APP_ | sed "s/^\(.*\)$/export \1/g" > /etc/profile.d/app-env.sh'

# database connection test
while ! /opt/otrs/bin/otrs.Console.pl Maint::Database::Check 2> /tmp/console-maint-database-check.log; 
do
    egrep -o " Message: (.+)" /tmp/console-maint-database-check.log

    # init configuration if empty
    grep "database content is missing" /tmp/console-maint-database-check.log \
    && /app-init.sh;
    
    sleep 1;
done

echo "100" > $PROGRESSBAR_FILE

# stop init-screen
sudo kill -9 $INITSCREEN_PID

if [ "$START_BACKEND" == "1" ]; then
    /opt/otrs/bin/Cron.sh start;
    /opt/otrs/bin/otrs.Daemon.pl start;
else
    /opt/otrs/bin/Cron.sh stop;
fi;

# run services
exec sudo supervisord