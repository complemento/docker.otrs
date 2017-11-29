#!/bin/bash

if [ ! -f "/installed" ]  ; then
    su -c "/opt/src/link.pl /opt/src/otrs /opt/otrs" -s /bin/bash otrs
    
    rm /opt/otrs/bin/otrs.SetPermissions.pl
    cp /opt/src/otrs/bin/otrs.SetPermissions.pl /opt/otrs/bin/otrs.SetPermissions.pl


    ## Create missing directories from GIT
    for dir in "/opt/otrs/var/spool" "/opt/otrs/var/tmp" "/opt/otrs/var/article"; do
        mkdir "${dir}"
        chown otrs:www-data "${dir}"
    done
    
    /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data

    # Create default files if first time
    for file in "Kernel/Config.pm" "var/cron/aaa_base"  "var/cron/otrs_daemon"; do
        if [ ! -e "/opt/otrs/${file}" ] ; then
             cp  "/opt/src/otrs/${file}.dist" "/opt/otrs/${file}"
             chown otrs:www-data "/opt/otrs/${file}"
             chmod 0666 "/opt/otrs/${file}"
        fi
    done

    touch "/installed"
    
fi
/usr/bin/supervisord
