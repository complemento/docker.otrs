#!/bin/bash

# FRONTEND test
if [ "$START_FRONTEND" == "1" ]; then 
    curl -wfs http://localhost/otrs/index.pl?healthcheck -o /dev/null || exit 1
fi;

# BACKEND test
#if [ "$START_BACKEND" == "1" ]; then 
#    # TODO
#fi;