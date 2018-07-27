#!/bin/bash

# Adjustment for Sendmail
line=$(cat /etc/hosts | grep `hostname`)
line2=$(echo $line | awk '{print $2}')
echo "$line $line2.localdomain" >> /etc/hosts

# Verifies if we already executed installation process
if [ ! -f "/opt/otrs/installed" ]  ; then
    # COPY OTRS FILES TO DESTINATION FOLDER
    /opt/src/link.pl /opt/src/otrs /opt/otrs
    rm /opt/otrs/bin/otrs.SetPermissions.pl
    cp /opt/src/otrs/bin/otrs.SetPermissions.pl /opt/otrs/bin/otrs.SetPermissions.pl

    # Fix permissions
    cd /opt/otrs
    # if articles are mapped as a volume, it's not a good idea to change permissions
    # now because it can take a long time
    find . ! -path "*var/article/*" | xargs chown otrs:www-data
    
    ## Create missing directories from GIT
    for dir in "/opt/otrs/var/spool" "/opt/otrs/var/tmp" "/opt/otrs/var/article"; do
        mkdir "${dir}"
        chown otrs:www-data "${dir}"
    done
    
    # For some reason, we need to set permissions again :/
    /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data --skip-article-dir

    # Create default files if first time
    for file in "Kernel/Config.pm" "var/cron/aaa_base"  "var/cron/otrs_daemon"; do
        if [ ! -e "/opt/otrs/${file}" ] ; then
             cp  "/opt/src/otrs/${file}.dist" "/opt/otrs/${file}"
             chown otrs:www-data "/opt/otrs/${file}"
             chmod 0666 "/opt/otrs/${file}"
        fi
    done

    ## Initital Install
    # Check if INSTALL variable is set (from our docker-compose file for example)
    if [ -n "${INSTALL}" ]; then

        ##### Put the variables on OTRS Config.pm
        sed -i 's/\(.*{DatabaseHost}.*\)127.0.0.1/\1'"${MYSQL_HOSTNAME}"'/' /opt/otrs/Kernel/Config.pm
        sed -i 's/\(.*{Database}.*\)otrs/\1'"otrs_${CUSTOMER_ID}"'/' /opt/otrs/Kernel/Config.pm
        sed -i 's/\(.*{DatabaseUser}.*\)otrs/\1'"${MYSQL_USERNAME}"'/' /opt/otrs/Kernel/Config.pm
        sed -i 's/\(.*{DatabasePw}.*\)some-pass/\1'"${MYSQL_PASSWORD}"'/' /opt/otrs/Kernel/Config.pm
            
        # Waits mysql to be running for proceding Database instalation
        while ! mysqladmin ping -h "${MYSQL_HOSTNAME}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" -u"${MYSQL_USERNAME}" --silent; do sleep 1; echo "Wainting Mysql...\n"; done

        
        ##### Install OTRS Database ####
        mysql -h "${MYSQL_HOSTNAME}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" -e "CREATE DATABASE otrs_${CUSTOMER_ID} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;" && \
        mysql -h "${MYSQL_HOSTNAME}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" otrs_${CUSTOMER_ID} < /opt/src/otrs/scripts/database/otrs-schema.mysql.sql && \
        mysql -h "${MYSQL_HOSTNAME}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" otrs_${CUSTOMER_ID} < /opt/src/otrs/scripts/database/otrs-initial_insert.mysql.sql && \
        mysql -h "${MYSQL_HOSTNAME}" -u "${MYSQL_USERNAME}" -p"${MYSQL_PASSWORD}" otrs_${CUSTOMER_ID} < /opt/src/otrs/scripts/database/otrs-schema-post.mysql.sql


        ###### SysConfig defaults parameters ##############
        su -c "/opt/otrs/bin/otrs.Console.pl Maint::Config::Rebuild" -s /bin/bash otrs;    
        if [ -n "${OTRS_DEFAULT_LANGUAGE}" ]; then
                su -c "/opt/otrs/bin/otrs.Console.pl Admin::Config::Update --no-deploy --setting-name DefaultLanguage --value ${OTRS_DEFAULT_LANGUAGE}" -s /bin/bash otrs;
        fi
        
        if [ -n "${OTRS_FQDN}" ]; then
            su -c "/opt/otrs/bin/otrs.Console.pl Admin::Config::Update --no-deploy --setting-name FQDN --value ${OTRS_FQDN}" -s /bin/bash otrs;
        fi
        
        if [ -n "${OTRS_SYSTEM_ID}" ]; then
            su -c "/opt/otrs/bin/otrs.Console.pl Admin::Config::Update --no-deploy --setting-name SystemID --value ${OTRS_SYSTEM_ID}" -s /bin/bash otrs;
        fi

        ### Allow community packages to be installed
   		su -c "sed -i '26i\ \ \ \ delete \$Self->{\x27Frontend::NotifyModule\x27}->{\x278000-PackageManager-CheckNotVerifiedPackages\x27};' /opt/otrs/Kernel/Config.pm" -s /bin/bash otrs;
        # just add a new blank line
        su -c "sed -i '26i\ \ \ \ ' /opt/otrs/Kernel/Config.pm" -s /bin/bash otrs;

        su -c "/opt/otrs/bin/otrs.Console.pl Admin::Config::Update --no-deploy --setting-name 'Package::AllowNotVerifiedPackages' --value 1" -s /bin/bash otrs;

        # For some strange reason, we need to Rebuild config twice in some systems
        su -c "/opt/otrs/bin/otrs.Console.pl Maint::Config::Rebuild" -s /bin/bash otrs;    
        su -c "/opt/otrs/bin/otrs.Console.pl Admin::Config::Update --no-deploy --setting-name SecureMode --value 1" -s /bin/bash otrs;
        su -c "/opt/otrs/bin/otrs.Console.pl Maint::Config::Rebuild" -s /bin/bash otrs;
        
        ### OTRS admin default password:
        su -c "/opt/otrs/bin/otrs.Console.pl Admin::User::SetPassword 'root@localhost' ligero" -s /bin/bash otrs;

        ### Install LigeroRepository
        if [ ! -n "${DONT_INSTALL_LIGERO_ADDONS}" ]; then
            for addon in /opt/ligero_addons/*.opm; do
                su -c "/opt/otrs/bin/otrs.Console.pl Admin::Package::Install $addon" -s /bin/bash otrs;
            done
        fi

        ### Install Packages
        for addon in /opt/otrs_addons/*.opm; do
            su -c "/opt/otrs/bin/otrs.Console.pl Admin::Package::Install $addon" -s /bin/bash otrs;
        done

    fi

    touch "/opt/otrs/installed"
    
fi
/usr/bin/supervisord
