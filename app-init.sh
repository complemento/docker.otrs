#!/bin/bash

INITSCREEN_DIR=/var/www/html
PROGRESSBAR_FILE=$INITSCREEN_DIR/progress.txt

PACKAGE_LIST=`ls /app-packages/*.opm`
PACKAGE_COUNT=`ls -1 /app-packages/*.opm | wc -l`

SCRIPT_LIST=`find /app-init.d/ -type f -executable 2> /dev/null`
SCRIPT_COUNT=`find /app-init.d/ -type f -executable 2> /dev/null | wc -l`



if [ -d "$RESTORE_DIR" ]; then
    #
    # restore system from backup dir
    #
    echo "$0 - Restoring backup $RESTORE_DIR"

    echo "30" > $PROGRESSBAR_FILE

    otrs.Console.pl Maint::Cache::Delete

    cp Kernel/Config.pm{,_tmp}
    /opt/otrs/scripts/restore.pl -d /opt/otrs -b $RESTORE_DIR
    cp Kernel/Config.pm{,_restored}
    mv Kernel/Config.pm{_tmp,}

else

    #
    # system installation
    #
    case $APP_DatabaseType in

    mysql)
        
        echo "$0 - Loading MySQL data"
        
        mysql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" ${APP_Database} < /opt/otrs/scripts/database/otrs-schema.mysql.sql \
        && mysql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" ${APP_Database} < /opt/otrs/scripts/database/otrs-initial_insert.mysql.sql \
        && mysql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" ${APP_Database} < /opt/otrs/scripts/database/otrs-schema-post.mysql.sql
        
        [ $? -gt 0 ] && echo "Error loading MySQL data" && exit 1;
        
        ;;

    postgresql)

        echo "$0 - Loading PostgreSQL data"
        export PGPASSWORD=${APP_DatabasePw}
        psql -h "${APP_DatabaseHost}" -U "${APP_DatabaseUser}" -d ${APP_Database} -a -f /opt/otrs/scripts/database/otrs-schema.postgresql.sql > /dev/null \
        && psql -h "${APP_DatabaseHost}" -U "${APP_DatabaseUser}" -d ${APP_Database} -a -f /opt/otrs/scripts/database/otrs-initial_insert.postgresql.sql > /dev/null \
        && psql -h "${APP_DatabaseHost}" -U "${APP_DatabaseUser}" -d ${APP_Database} -a -f /opt/otrs/scripts/database/otrs-schema-post.postgresql.sql > /dev/null

        [ $? -gt 0 ] && echo "Error loading PostgreSQL data" && exit 1;

        ;;

    *) 
        echo "$0 - APP_DatabaseType is not set";
        exit 1;
    esac;

    # progress bar for init screen
    echo "30" > $PROGRESSBAR_FILE
    let TOTAL_ITENS=$PACKAGE_COUNT+$SCRIPT_COUNT
    let PROGRESS_STEP=65/$TOTAL_ITENS

    # initial config
    otrs.Console.pl Maint::Config::Rebuild
    otrs.Console.pl Admin::Config::Update --setting-name 'Package::AllowNotVerifiedPackages' --value 1 --no-deploy
    [ $APP_DefaultLanguage ] && otrs.Console.pl Admin::Config::Update --setting-name 'DefaultLanguage' --value $APP_DefaultLanguage --no-deploy
    # TODO: loop on APP_* testing setting name
    otrs.Console.pl Maint::Config::Rebuild

    # install packages
    for PKG in $PACKAGE_LIST; do
        echo "$0 - Installing package $PKG"
        otrs.Console.pl Admin::Package::Install --force --quiet $PKG 
        let ITEM_COUNT+=1
        let PROGRESS=$PROGRESS_STEP*$ITEM_COUNT+30
        echo $PROGRESS > $PROGRESSBAR_FILE
    done;


    # run custom init scripts
    for f in $SCRIPT_LIST; do
        echo "$0 - running $f"
        $f
        let ITEM_COUNT+=1
        let PROGRESS=$PROGRESS_STEP*$ITEM_COUNT+30
        echo $PROGRESS > $PROGRESSBAR_FILE
    done

    # root password
    otrs.Console.pl Admin::User::SetPassword 'root@localhost' "${ROOT_PASSWORD:-ligero}"
    echo "default user: root@localhost"
    echo "default password: ligero"
    unset ROOT_PASSWORD

fi;

echo "95" > $PROGRESSBAR_FILE

# enable secure mode
otrs.Console.pl Admin::Config::Update --setting-name SecureMode --value 1 --no-deploy

# apply config
otrs.Console.pl Maint::Config::Rebuild

otrs.Console.pl Maint::Log::Clear

echo "98" > $PROGRESSBAR_FILE

exit 0
