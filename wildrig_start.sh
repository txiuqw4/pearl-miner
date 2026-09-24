#!/bin/sh
set -e

WORKER="$(hostname -s)"

cd /opt

curl -fL -o wildrig-multi-linux-0.51.2.tar.gz \
  https://github.com/andru-kun/wildrig-multi/releases/download/0.51.2/wildrig-multi-linux-0.51.2.tar.gz

tar -xzf wildrig-multi-linux-0.51.2.tar.gz
rm -f wildrig-multi-linux-0.51.2.tar.gz

chmod +x /opt/wildrig-multi

exec /opt/wildrig-multi \
  --algo pearlhash \
  --url pool.pearlhash.xyz:9000 \
  --user "prl1pl76eychyzq97as53t855ryct2dfsgghe3sgrpfdl89ctq06py9gs6qnuc7.$WORKER" \
  >> /opt/prl.log 2>&1
