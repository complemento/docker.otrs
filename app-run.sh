#!/bin/bash

export INITSCREEN_DIR=/var/www/html
export PROGRESSBAR_FILE=$INITSCREEN_DIR/progress.txt
export START_BACKEND=${START_BACKEND:-1}
export START_FRONTEND=${START_FRONTEND:-1}
export START_SSHD=${START_SSHD:-0}
export DEBUG_MODE=${DEBUG_MODE:-0}

echo "5" > $PROGRESSBAR_FILE


# init-screen
perl $INITSCREEN_DIR/httpserver.pl > /dev/null 2>&1 &
INITSCREEN_PID=$!

# set APP ENV vars
printenv | grep APP_ | sed 's/^\(.*\)$/export \1/g' > /etc/profile.d/app-env.sh

# database connection test
if [ $START_FRONTEND == '1' ]; then
    while ! su -c "otrs.Console.pl Maint::Database::Check" otrs 2> /tmp/console-maint-database-check.log; 
    do
        egrep -o " Message: (.+)" /tmp/console-maint-database-check.log

        # init configuration if empty
        grep "database content is missing" /tmp/console-maint-database-check.log \
        && su -c "/app-init.sh" otrs \
        && otrs.SetPermissions.pl

        sleep 3;
    done
fi;

if [ $START_SSHD != '0' ]; then
    if [ -z "$SSH_PASSWORD" ]; then
        echo "$0 - Set SSH_PASSWORD for otrs user or put your public RSA key on /opt/otrs/.ssh/authorized_keys"
    else
        # set otrs password
        echo -e "$SSH_PASSWORD\n$SSH_PASSWORD\n" | passwd otrs 2> /dev/null
    fi;
fi;

echo "100" > $PROGRESSBAR_FILE

# stop init-screen
kill -9 $INITSCREEN_PID

# run services
exec supervisord -c /etc/supervisor/supervisord.conf
