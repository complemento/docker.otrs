#!/bin/bash


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

# install packages
otrs.Console.pl Maint::Config::Rebuild
otrs.Console.pl Admin::Config::Update --setting-name 'Package::AllowNotVerifiedPackages' --value 1 --no-deploy
otrs.Console.pl Maint::Config::Rebuild
for PKG in `ls -1 /app-packages/*.opm`; do
    echo "$0 - Installing package $PKG"
    otrs.Console.pl Admin::Package::Install --force --quiet $PKG \
    && rm -rf $PKG
done;

# run custom init scripts
for f in `ls /app-init.d/*.sh 2> /dev/null`; do
    echo "$0 - running $f"
    bash "$f"
done

# enable secure mode
otrs.Console.pl Admin::Config::Update --setting-name SecureMode --value 1 --no-deploy

# apply config
otrs.Console.pl Maint::Config::Rebuild

# root password
otrs.Console.pl Admin::User::SetPassword 'root@localhost' complemento
echo "Password: complemento"