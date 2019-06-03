#!/bin/bash

INITSCREEN_DIR=/var/www/html
PROGRESSBAR_FILE=$INITSCREEN_DIR/progress.txt

PACKAGE_LIST=`ls /app-packages/*.opm`
PACKAGE_COUNT=`ls -1 /app-packages/*.opm | wc -l`

SCRIPT_LIST=`ls /app-init.d/*.sh 2> /dev/null`
SCRIPT_COUNT=`ls -1 /app-init.d/*.sh 2> /dev/null | wc -l`


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

# progress bar for init screen
echo "30" > $PROGRESSBAR_FILE
let TOTAL_ITENS=$PACKAGE_COUNT+$SCRIPT_COUNT
let PROGRESS_STEP=65/$TOTAL_ITENS

# install packages
otrs.RebuildConfig.pl
sed -i '10i\$Self->{\x27Package::AllowNotVerifiedPackages\x27} =  1;' /opt/otrs/Kernel/Config/Files/ZZZAuto.pm
otrs.RebuildConfig.pl

for PKG in $PACKAGE_LIST; do
    echo "$0 - Installing package $PKG"
    otrs.PackageManager.pl -a install -p $PKG 
    let ITEM_COUNT+=1
    let PROGRESS=$PROGRESS_STEP*$ITEM_COUNT+30
    echo $PROGRESS > $PROGRESSBAR_FILE
done;


# run custom init scripts
for f in $SCRIPT_LIST; do
    echo "$0 - running $f"
    bash "$f"
    let ITEM_COUNT+=1
    let PROGRESS=$PROGRESS_STEP*$ITEM_COUNT+30
    echo $PROGRESS > $PROGRESSBAR_FILE
done

echo "95" > $PROGRESSBAR_FILE

# enable secure mode
sed -i '10i\$Self->{\x27SecureMode\x27} =  \x271\x27;' /opt/otrs/Kernel/Config/Files/ZZZAuto.pm

# apply config
otrs.RebuildConfig.pl

# root password
otrs.SetPassword.pl root@localhost 'root@localhost' ${ROOT_PASSWORD:-root}
echo "Password: ${ROOT_PASSWORD:-root}"
unset ROOT_PASSWORD

echo "98" > $PROGRESSBAR_FILE
