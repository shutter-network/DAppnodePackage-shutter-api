#!/bin/bash


if [[ SHUTTER_PUSH_LOGS_ENABLED=true ]];
then
    configure.sh | rotatelogs -n 1 -e -c /tmp/configure.log 5M
else
    configure.sh
fi
