#!/bin/sh
set -e

WORKER="${1:-worker-$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')}"

cd /opt

curl -L -o SRBMiner-Multi-3-6-9-Linux.tar.gz \
  https://github.com/doktor83/SRBMiner-Multi/releases/download/3.6.9/SRBMiner-Multi-3-6-9-Linux.tar.gz

tar -xzf SRBMiner-Multi-3-6-9-Linux.tar.gz

chmod +x SRBMiner-MULTI

rm -f SRBMiner-Multi-3-6-9-Linux.tar.gz

exec /opt/SRBMiner-MULTI --disable-cpu --algorithm pearlhash -pool prl-us.kryptex.network:7048 --wallet krxY96RPRD --worker "$WORKER" --gpu-coffset0 200 --gpu-cclock0 2490 --gpu-mclock0 7001 --gpu-plimit0 575
