#!/bin/bash
# Verifies if OTRS is already installed, then start it's cron

if [ -e /opt/otrs/Kernel/Config/Files/ZZZAAuto.pm ]; then
    # If ZZZAAuto was created, then we have an running OTRS probably

    cd /opt/otrs
    su -c "/opt/otrs/bin/otrs.Daemon.pl stop >> /dev/null" -s /bin/bash otrs
    su -c "/opt/otrs/bin/otrs.Daemon.pl start >> /dev/null" -s /bin/bash otrs
    /opt/otrs/bin/Cron.sh restart otrs

    # removes daemonstarter.sh from cron
    crontab -r -u root
fi

