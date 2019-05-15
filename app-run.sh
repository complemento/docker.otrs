#!/bin/bash

INITSCREEN_DIR=/var/www/html
PROGRESSBAR_FILE=$INITSCREEN_DIR/progress.txt
START_BACKEND=${START_BACKEND:-1}

echo "5" > $PROGRESSBAR_FILE


# init-screen
perl $INITSCREEN_DIR/httpserver.pl > /dev/null 2>&1 &
INITSCREEN_PID=$!

# set APP ENV vars
printenv | grep APP_ | sed 's/^\(.*\)$/export \1/g' > /etc/profile.d/app-env.sh

# database connection test
while ! su -c "otrs.Console.pl Maint::Database::Check" otrs 2> /tmp/console-maint-database-check.log; 
do
    egrep -o " Message: (.+)" /tmp/console-maint-database-check.log

    # init configuration if empty
    grep "database content is missing" /tmp/console-maint-database-check.log \
    && su -c "/app-init.sh" otrs;
    
    sleep 1;
done

echo "100" > $PROGRESSBAR_FILE

# stop init-screen
kill -9 $INITSCREEN_PID

if [ "$START_BACKEND" == "1" ]; then

    /opt/otrs/bin/Cron.sh start otrs;
    su -c "/opt/otrs/bin/otrs.Daemon.pl start" otrs;

fi;

# run services
exec supervisord