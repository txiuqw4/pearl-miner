#!/bin/sh
set -e

echo "[startup] Installing dependencies..."

apt-get update
apt-get install -y supervisor ocl-icd-libopencl1 curl

WORKER="${1:-worker-$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')}"

echo "[startup] Worker: $WORKER"

mkdir -p /opt
mkdir -p /var/log/supervisor

cd /opt

# Download WildRig only if it does not already exist
if [ ! -x /opt/wildrig-multi ]; then
    echo "[startup] Downloading WildRig..."

    curl -fL -o wildrig-multi-linux-0.51.3.tar.gz \
      https://github.com/andru-kun/wildrig-multi/releases/download/0.51.3/wildrig-multi-linux-0.51.3.tar.gz

    tar -xzf wildrig-multi-linux-0.51.3.tar.gz
    rm -f wildrig-multi-linux-0.51.3.tar.gz

    chmod +x /opt/wildrig-multi
fi

echo "[startup] Creating Supervisor config..."

cat > /etc/supervisor/conf.d/pearl.conf <<EOF
[program:pearl]
command=/opt/wildrig-multi --algo pearlhash --url pool.pearlhash.xyz:9000 --user prl1pl76eychyzq97as53t855ryct2dfsgghe3sgrpfdl89ctq06py9gs6qnuc7.$WORKER --print-time 10 --no-color
directory=/opt
autostart=true
autorestart=true
startsecs=5
startretries=999
stopasgroup=true
killasgroup=true
stdout_logfile=/opt/prl.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=3
stderr_logfile=/opt/prl-error.log
stderr_logfile_maxbytes=20MB
stderr_logfile_backups=3
EOF

echo "[startup] Starting Supervisor..."

# Make sure stale supervisor pid/socket do not break startup
rm -f /var/run/supervisord.pid
rm -f /var/run/supervisor.sock

# Start supervisord if it is not already running
if ! pgrep -x supervisord >/dev/null 2>&1; then
    supervisord -c /etc/supervisor/supervisord.conf
fi

# Reload config and start/restart Pearl
supervisorctl reread
supervisorctl update
supervisorctl restart pearl || supervisorctl start pearl
