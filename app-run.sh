#!/bin/bash

INITSCREEN_DIR=/var/www/html
PROGRESSBAR_FILE=$INITSCREEN_DIR/progress.txt
export START_FRONTEND=${START_FRONTEND:1}
export START_BACKEND=${START_BACKEND:-1}
export START_PLACKUP=${START_PLACKUP:-1}
export DEBUG_MODE=${DEBUG_MODE:-0}

echo "5" > $PROGRESSBAR_FILE


# init-screen
perl $INITSCREEN_DIR/httpserver.pl > /dev/null 2>&1 &
INITSCREEN_PID=$!

# set APP ENV vars
printenv | grep APP_ | sed 's/^\(.*\)$/export \1/g' > /etc/profile.d/app-env.sh

# fix permissions before database test
perl /opt/otrs/bin/otrs.SetPermissions.pl --skip-article-dir

# database connection test
while ! su -c "otrs.Console.pl Maint::Database::Check" otrs 2> /tmp/console-maint-database-check.log; 
do
    egrep -o " Message: (.+)" /tmp/console-maint-database-check.log

    # init configuration if empty
    grep "database content is missing" /tmp/console-maint-database-check.log \
    && su -c "/app-init.sh" otrs;
    
    sleep 1;
done

if [ "$START_BACKEND" == "1" ]; then
    /opt/otrs/bin/Cron.sh start otrs;
    su -c "/opt/otrs/bin/otrs.Daemon.pl start" otrs;
else
    /opt/otrs/bin/Cron.sh stop otrs;
fi;

if [ "$DEBUG_MODE" == "0" ]; then
    export PLACK_ENV=deployment
else
    export PLACK_ENV=development
fi;

echo "100" > $PROGRESSBAR_FILE

# stop init-screen
kill -9 $INITSCREEN_PID

# run services
exec supervisord
