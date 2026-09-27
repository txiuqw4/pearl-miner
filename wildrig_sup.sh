#!/bin/sh
set -e

export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "[startup] PearlHash Miner"
echo "========================================"

# ============================================================
# 1. APT
# ============================================================

echo "[startup] Updating apt..."

apt-get update

# ============================================================
# 2. Completely remove broken Supervisor installation
#
# This is important because the container may have Supervisor
# stuck in "half-configured" state and dpkg keeps asking about
# supervisord.conf.
# ============================================================

echo "[startup] Cleaning broken Supervisor installation..."

if dpkg-query -W -f='${Status}' supervisor 2>/dev/null | \
   grep -qE 'install ok installed|install ok half-configured|install ok unpacked|install reinstreq'; then

    echo "[startup] Purging existing Supervisor package..."

    dpkg --purge --force-all supervisor 2>/dev/null || true
fi

# Remove leftover Supervisor files.
rm -f /etc/supervisor/supervisord.conf
rm -f /var/run/supervisord.pid
rm -f /var/run/supervisor.sock

# Keep the directory but remove old package-generated config.
mkdir -p /etc/supervisor/conf.d
mkdir -p /var/log/supervisor

# ============================================================
# 3. Repair dpkg
# ============================================================

echo "[startup] Repairing dpkg..."

dpkg --configure -a 2>/dev/null || true

apt-get \
    --fix-broken \
    install \
    -y

# ============================================================
# 4. Install dependencies
# ============================================================

echo "[startup] Installing dependencies..."

apt-get install -y \
    supervisor \
    ocl-icd-libopencl1 \
    curl

# ============================================================
# 5. Verify Supervisor
# ============================================================

echo "[startup] Supervisor version:"

supervisord --version

# ============================================================
# 6. Worker
# ============================================================

if [ -n "$1" ]; then
    WORKER="$1"
else
    WORKER="$(hostname -s)"
fi

echo "[startup] Worker: $WORKER"

# ============================================================
# 7. WildRig
# ============================================================

WILDRIG_VERSION="0.51.3"
WILDRIG_FILE="wildrig-multi-linux-${WILDRIG_VERSION}.tar.gz"
WILDRIG_URL="https://github.com/andru-kun/wildrig-multi/releases/download/${WILDRIG_VERSION}/${WILDRIG_FILE}"

cd /opt

if [ ! -x /opt/wildrig-multi ]; then

    echo "[startup] Downloading WildRig ${WILDRIG_VERSION}..."

    rm -f "/opt/${WILDRIG_FILE}"

    curl -fL \
        -o "/opt/${WILDRIG_FILE}" \
        "$WILDRIG_URL"

    echo "[startup] Extracting WildRig..."

    tar -xzf "/opt/${WILDRIG_FILE}"

    rm -f "/opt/${WILDRIG_FILE}"

    chmod +x /opt/wildrig-multi

else

    echo "[startup] WildRig already exists."

fi

if [ ! -x /opt/wildrig-multi ]; then
    echo "[ERROR] /opt/wildrig-multi does not exist!"
    exit 1
fi

# ============================================================
# 8. Stop manually running WildRig
# ============================================================

echo "[startup] Stopping existing Pearl miner..."

pkill -f "/opt/wildrig-multi.*pearlhash" 2>/dev/null || true

sleep 2

# ============================================================
# 9. Create Supervisor configuration
# ============================================================

echo "[startup] Creating Supervisor configuration..."

mkdir -p /etc/supervisor/conf.d

cat > /etc/supervisor/supervisord.conf <<'EOF'
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor
nodaemon=false

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files=/etc/supervisor/conf.d/*.conf
EOF

# ============================================================
# 10. Pearl Supervisor program
# ============================================================

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

# ============================================================
# 11. Start Supervisor
# ============================================================

echo "[startup] Starting Supervisor..."

rm -f /var/run/supervisord.pid
rm -f /var/run/supervisor.sock

supervisord -c /etc/supervisor/supervisord.conf

sleep 2

# ============================================================
# 12. Load configuration
# ============================================================

echo "[startup] Loading Pearl configuration..."

supervisorctl reread
supervisorctl update

# ============================================================
# 13. Start Pearl
# ============================================================

echo "[startup] Starting Pearl miner..."

supervisorctl start pearl 2>/dev/null || \
supervisorctl restart pearl

sleep 3

# ============================================================
# 14. Status
# ============================================================

echo ""
echo "========================================"
echo "[startup] COMPLETE"
echo "========================================"

echo ""
echo "Worker:"
echo "  $WORKER"

echo ""
echo "Pool:"
echo "  pool.pearlhash.xyz:9000"

echo ""
echo "Supervisor:"
supervisorctl status pearl

echo ""
echo "WildRig:"
pgrep -af "/opt/wildrig-multi" || true

echo ""
echo "Logs:"
echo "  tail -f /opt/prl.log"
echo "  tail -f /opt/prl-error.log"

echo ""
echo "========================================"
