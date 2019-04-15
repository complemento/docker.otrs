#!/bin/bash


# Database installation
case $APP_DatabaseType in

mysql)
    
    echo " * Loading MySQL data"
    
    mysql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" ${APP_Database} < /opt/otrs/scripts/database/otrs-schema.mysql.sql \
    && mysql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" ${APP_Database} < /opt/otrs/scripts/database/otrs-initial_insert.mysql.sql \
    && mysql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" ${APP_Database} < /opt/otrs/scripts/database/otrs-schema-post.mysql.sql
    
    [ $? -gt 0 ] && echo "Error loading MySQL data" && exit 1;
    
    ;;

postgresql)

    #TODO
    echo " * Loading PostgreSQL data"
    #psql -h "${APP_DatabaseHost}" -u "${APP_DatabaseUser}" -p"${APP_DatabasePw}" "CREATE DATABASE ${APP_Database}"
    ;;

*) 
    echo " * APP_DatabaseType is not set";
    exit 1;
esac;

# install otrs packages
for PKG in `ls -1 /opt/otrs/var/packages/*.opm`; do
    echo " * Installing package $PKG"
    su -c "otrs.Console.pl Admin::Package::Install --quiet $PKG" otrs;
done;

# otrs root password
su -c "otrs.Console.pl Admin::User::SetPassword 'root@localhost' complemento" otrs;
echo "Password: complemento"