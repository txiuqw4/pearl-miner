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
cat <<'EOF' > /opt/SRBMiner-Multi-3-6-9/start_miner.sh
#!/bin/sh
WORKER="$(hostname -s)"
exec /opt/SRBMiner-Multi-3-6-9/SRBMiner-MULTI \
  --disable-cpu \
  --algorithm pearlhash \
  --pool pearl-us-west.luckypool.io:3361 \
  --wallet prl1pl76eychyzq97as53t855ryct2dfsgghe3sgrpfdl89ctq06py9gs6qnuc7+33Hskj4RdTAenJkd6Rkftj1AGb1ciKKMC37fwL6QKTncTLfJosze7J \
  --worker "${WORKER}" \
  >> /opt/SRBMiner-Multi-3-6-9/prl.log 2>&1
EOF

chmod +x /opt/SRBMiner-Multi-3-6-9/start_miner.sh

cat <<'EOF' > /etc/systemd/system/srbminer.service
[Unit]
Description=SRBMiner-Multi Pearl Mining Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/SRBMiner-Multi-3-6-9
ExecStart=/opt/SRBMiner-Multi-3-6-9/start_miner.sh
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable srbminer.service
systemctl start srbminer.service
