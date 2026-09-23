#!/bin/sh
set -e

WORKER="${1:-worker-$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')}"

cd /opt

curl -L -o ForgeMiner-1.8.1-linux.tar.gz https://github.com/0xHashRaptor/ForgeMiner/releases/download/v1.8.1/ForgeMiner-1.8.1-linux.tar.gz
tar -xzf ForgeMiner-1.8.1-linux.tar.gz
chmod +x forge
rm -f ForgeMiner-1.8.1-linux.tar.gz

nohup /opt/forge \
  --algorithm pearlhash \
  --pool prl-us.kryptex.network:7048 \
  --wallet krxY96RPRD \
  --worker "$WORKER" \
  > /opt/forgeminer.log 2>&1 < /dev/null &
