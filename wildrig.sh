#!/bin/sh
set -e

cd /opt

curl -fL -o wildrig-multi-linux-0.51.2.tar.gz \
  https://github.com/andru-kun/wildrig-multi/releases/download/0.51.2/wildrig-multi-linux-0.51.2.tar.gz

tar -xzf wildrig-multi-linux-0.51.2.tar.gz
rm -f wildrig-multi-linux-0.51.2.tar.gz

chmod +x /opt/wildrig-multi

cat <<'EOF' > /opt/start_miner.sh
#!/bin/sh

WORKER="$(hostname -s)"

exec /opt/wildrig-multi \
  --algo pearlhash \
  --url pool.pearlhash.xyz:9000 \
  --user prl1pl76eychyzq97as53t855ryct2dfsgghe3sgrpfdl89ctq06py9gs6qnuc7 \
  --worker "$WORKER" \
  >> /opt/prl.log 2>&1
EOF

chmod +x /opt/start_miner.sh

cat <<'EOF' > /etc/systemd/system/prlminer.service
[Unit]
Description=WildRig-MULTI PearlHash Mining Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt
ExecStart=/opt/start_miner.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prlminer.service
systemctl restart prlminer.service
