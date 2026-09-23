#!/bin/sh
set -e

cd /opt

curl -L -o SRBMiner-Multi-3-6-9-Linux.tar.gz \
  https://github.com/doktor83/SRBMiner-Multi/releases/download/3.6.9/SRBMiner-Multi-3-6-9-Linux.tar.gz

tar -xzf SRBMiner-Multi-3-6-9-Linux.tar.gz

rm -f SRBMiner-Multi-3-6-9-Linux.tar.gz

cd /opt/SRBMiner-Multi-3-6-9

chmod +x SRBMiner-MULTI

WORKER="$(hostname -s)"

exec ./SRBMiner-MULTI \
  --disable-cpu \
  --algorithm pearlhash \
  --pool prl.kryptex.network:7048 \
  --wallet "krxY96RPRD.${WORKER}" \
  --gpu-coffset0 200 --gpu-cclock0 2490 --gpu-mclock0 7001 --gpu-plimit0 575  \
  > /opt/SRBMiner-Multi-3-6-9/prl.log 2>&1
