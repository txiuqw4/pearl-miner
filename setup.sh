#!/bin/sh
set -e

echo "=== Installing ForgeMiner 1.8.1 ==="

cd /opt

curl -L -o ForgeMiner-1.8.1-linux.tar.gz \
  https://github.com/0xHashRaptor/ForgeMiner/releases/download/v1.8.1/ForgeMiner-1.8.1-linux.tar.gz

tar -xzf ForgeMiner-1.8.1-linux.tar.gz

chmod +x forge

rm -f ForgeMiner-1.8.1-linux.tar.gz

echo "=== Starting ForgeMiner ==="

nohup /opt/forge --algorithm pearlhash --pool prl-us.kryptex.network:7048 --wallet krxY96RPRD --worker "$HOSTNAME" > /opt/forge.log 2>&1 &

wait
