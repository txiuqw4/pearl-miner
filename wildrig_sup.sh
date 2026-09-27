#!/bin/sh
set -e

echo "========================================"
echo "[startup] PearlHash + Supervisor"
echo "========================================"

# --------------------------------------------------
# 1. Install dependencies
# --------------------------------------------------

echo "[startup] Installing dependencies..."

export DEBIAN_FRONTEND=noninteractive

apt-get update

# Fix any interrupted dpkg configuration.
# --force-confold prevents interactive conffile prompts.
apt-get \
  -o Dpkg::Options::="--force-confold" \
  --fix-broken install -y

apt-get \
  -o Dpkg::Options::="--force-confold" \
  install -y \
  supervisor \
  ocl-icd-libopencl1 \
  curl

# Make sure any interrupted configuration is completed.
dpkg --configure -a --force-confold 2>/dev/null || true

# --------------------------------------------------
# 2. Worker name
# --------------------------------------------------

if [ -n "$1" ]; then
    WORKER="$1"
else
    WORKER="$(hostname -s)"
fi

echo "[startup] Worker: $WORKER"

# --------------------------------------------------
# 3. Prepare directories
# --------------------------------------------------

mkdir -p /opt
mkdir -p /var/log/supervisor

cd /opt

# --------------------------------------------------
# 4. Download WildRig
# --------------------------------------------------

WILDRIG_VERSION="0.51.3"
WILDRIG_TARBALL="wildrig-multi-linux-${WILDRIG_VERSION}.tar.gz"
WILDRIG_URL="https://github.com/andru-kun/wildrig-multi/releases/download/${WILDRIG_VERSION}/${WILDRIG_TARBALL}"

if [ ! -x /opt/wildrig-multi ]; then

    echo "[startup] Downloading WildRig ${WILDRIG_VERSION}..."

    rm -f "/opt/${WILDRIG_TARBALL}"

    curl -fL \
      -o "/opt/${WILDRIG_TARBALL}" \
      "$WILDRIG_URL"

    tar -xzf "/opt/${WILDRIG_TARBALL}"

    rm -f "/opt/${WILDRIG_TARBALL}"

    chmod +x /opt/wildrig-multi

else

    echo "[startup] WildRig already exists, skipping download."

fi

# Verify binary
if [ ! -x /opt/wildrig-multi ]; then
    echo "[ERROR] /opt/wildrig-multi not found or not executable."
    exit 1
fi

echo "[startup] WildRig:"
/opt/wildrig-multi --version 2>&1 | head -n 3 || true

# --------------------------------------------------
# 5. Stop old manually-started WildRig
# --------------------------------------------------

echo "[startup] Checking old WildRig processes..."

pkill -f "/opt/wildrig-multi.*pearlhash" 2>/dev/null || true

sleep 2

# --------------------------------------------------
# 6. Create Supervisor configuration
# --------------------------------------------------

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

# --------------------------------------------------
# 7. Supervisor configuration
# --------------------------------------------------

# Remove stale runtime files
rm -f /var/run/supervisord.pid
rm -f /var/run/supervisor.sock

echo "[startup] Starting supervisord..."

# Start Supervisor if not already running.
if ! pgrep -x supervisord >/dev/null 2>&1; then
    supervisord -c /etc/supervisor/supervisord.conf
    sleep 2
else
    echo "[startup] supervisord is already running."
fi

# --------------------------------------------------
# 8. Reload Supervisor
# --------------------------------------------------

echo "[startup] Reloading Supervisor configuration..."

supervisorctl reread
supervisorctl update

# Make sure Pearl is running.
supervisorctl restart pearl 2>/dev/null || \
supervisorctl start pearl

sleep 2

# --------------------------------------------------
# 9. Status
# --------------------------------------------------

echo ""
echo "========================================"
echo "[startup] DONE"
echo "========================================"

echo "[startup] Worker: $WORKER"
echo "[startup] Pool: pool.pearlhash.xyz:9000"
echo "[startup] Algo: pearlhash"

echo ""
echo "[startup] Supervisor:"
supervisorctl status pearl

echo ""
echo "[startup] WildRig process:"
pgrep -af "/opt/wildrig-multi" || true

echo ""
echo "[startup] Logs:"
echo "  Miner:    tail -f /opt/prl.log"
echo "  Errors:   tail -f /opt/prl-error.log"
echo "  Status:   supervisorctl status pearl"
echo ""

echo "========================================"
