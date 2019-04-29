#!/bin/bash

INITSCREEN_DIR=/var/www/html
PROGRESSBAR_FILE=$INITSCREEN_DIR/progress.txt


# Database installation
case $APP_DatabaseType in

mysql)
    
    echo "$0 - Loading MySQL data"
    
    mysql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" ${APP_Database} < /opt/otrs/scripts/database/otrs-schema.mysql.sql \
    && mysql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" ${APP_Database} < /opt/otrs/scripts/database/otrs-initial_insert.mysql.sql \
    && mysql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" ${APP_Database} < /opt/otrs/scripts/database/otrs-schema-post.mysql.sql
    
    [ $? -gt 0 ] && echo "Error loading MySQL data" && exit 1;
    
    ;;

postgresql)

    #TODO
    echo "$0 - Loading PostgreSQL data"
    #psql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" "CREATE DATABASE ${APP_Database}"
    ;;

*) 
    echo "$0 - APP_DatabaseType is not set";
    exit 1;
esac;

echo "30" > $PROGRESSBAR_FILE

# install packages
otrs.Console.pl Maint::Config::Rebuild
otrs.Console.pl Admin::Config::Update --setting-name 'Package::AllowNotVerifiedPackages' --value 1 --no-deploy
otrs.Console.pl Maint::Config::Rebuild

PACKAGE_LIST=`ls /app-packages/*.opm`
PACKAGE_COUNT=`ls -1 /app-packages/*.opm | wc -l`
let PROGRESS_STEP=55/$PACKAGE_COUNT
for PKG in $PACKAGE_LIST; do
    echo "$0 - Installing package $PKG"
    otrs.Console.pl Admin::Package::Install --force --quiet $PKG \
    && rm -rf $PKG
    let PACKAGE_COUNT_INSTALLED+=1
    let PROGRESS=$PROGRESS_STEP*$PACKAGE_COUNT_INSTALLED+30
    echo $PROGRESS > $PROGRESSBAR_FILE
done;

echo "85" > $PROGRESSBAR_FILE

# run custom init scripts
SCRIPT_LIST=`ls /app-init.d/*.sh 2> /dev/null`
SCRIPT_COUNT=`ls -1 /app-init.d/*.sh 2> /dev/null | wc -l`
let PROGRESS_STEP=10/$SCRIPT_COUNT
for f in $SCRIPT_LIST; do
    echo "$0 - running $f"
    bash "$f"
    let SCRIPT_COUNT_RUN+=1
    let PROGRESS=$PROGRESS_STEP*$SCRIPT_COUNT_RUN+80
    echo $PROGRESS > $PROGRESSBAR_FILE
done

echo "95" > $PROGRESSBAR_FILE

# enable secure mode
otrs.Console.pl Admin::Config::Update --setting-name SecureMode --value 1 --no-deploy

# apply config
otrs.Console.pl Maint::Config::Rebuild

# root password
otrs.Console.pl Admin::User::SetPassword 'root@localhost' complemento
echo "Password: complemento"

echo "97" > $PROGRESSBAR_FILE
