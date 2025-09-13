FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jre-headless curl jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /mc

RUN set -eux; \
  curl -fsSL https://piston-meta.mojang.com/mc/game/version_manifest_v2.json -o /tmp/manifest.json; \
  LATEST_ID="$(jq -r '.latest.release' /tmp/manifest.json)"; \
  VERSION_URL="$(jq -r --arg v "$LATEST_ID" '.versions[] | select(.id==$v) | .url' /tmp/manifest.json)"; \
  curl -fsSL "$VERSION_URL" -o /tmp/version.json; \
  curl -fsSL "$(jq -r '.downloads.server.url' /tmp/version.json)" -o /mc/server.jar; \
  rm -f /tmp/manifest.json /tmp/version.json

RUN echo "eula=true" > /mc/eula.txt

COPY defaults/ /defaults/

ENV JAVA_OPTS="-Xms1G -Xmx2G"

COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh
CMD ["sh", "/entrypoint.sh"]

EXPOSE 25565