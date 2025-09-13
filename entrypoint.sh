set -e

mkdir -p /mc

if [ ! -f "/mc/server.properties" ]; then
  echo "[entrypoint] Seeding defaults → /mc"
  cp -n /defaults/* /mc/
fi

echo "[entrypoint] Starting Minecraft server..."
exec java ${JAVA_OPTS:- -Xms1G -Xmx2G} -jar /mc/server.jar nogui
