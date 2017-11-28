#!/bin/bash

# Create default files if first time
for file in "Kernel/Config.pm" "var/cron/aaa_base"  "var/cron/otrs_daemon"; do
    if [ ! -e "/opt/otrs/${file}" ] ; then
         cp  "/opt/src/otrs/${file}.dist" "/opt/otrs/${file}"
         chown otrs:www-data "/opt/otrs/${file}"
         chmod 0666 "/opt/otrs/${file}"
    fi
done
/opt/otrs/bin/Cron.sh restart otrs

# Start Services
/etc/init.d/cron start
/etc/init.d/apache2 start
