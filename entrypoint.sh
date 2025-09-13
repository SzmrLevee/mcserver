#!/bin/sh
set -e

# seeding
if [ ! -f "/mc/server.properties" ]; then
  [ -f "/defaults/server.properties" ] && cp -n /defaults/server.properties /mc/
fi
if [ ! -f "/mc/server-icon.png" ] && [ -f "/defaults/server-icon.png" ]; then
  cp -n /defaults/server-icon.png /mc/
fi

# start
exec java ${JAVA_OPTS:- -Xms1G -Xmx2G} -jar /mc/server.jar nogui
