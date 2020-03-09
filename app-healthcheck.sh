#!/bin/bash

# disable check on restore
if [ ! -z "$RESTORE_DIR" ]; then 
    exit 0
fi;

# FRONTEND test
if [ "$START_FRONTEND" == "1" ] && [ -z $(pgrep httpserver.pl) ]; then 
    curl -wfs http://localhost/otrs/index.pl?healthcheck -o /dev/null || exit 1
fi;

# BACKEND test
#if [ "$START_BACKEND" == "1" ]; then 
#    # TODO
#fi;


# returns ok
exit 0