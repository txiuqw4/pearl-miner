#!/bin/sh
set -e

export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "[STARTUP] PearlHash Miner"
echo "========================================"

# ==================================================
# 1. Prepare / fix broken dpkg
# ==================================================

echo "[STARTUP] Preparing apt/dpkg..."

# Kill any stale apt/dpkg process if necessary
rm -f /var/lib/dpkg/lock-frontend 2>/dev/null || true
rm -f /var/lib/dpkg/lock 2>/dev/null || true
rm -f /var/cache/apt/archives/lock 2>/dev/null || true

# --------------------------------------------------
# IMPORTANT:
# Supervisor may be stuck because an old
# /etc/supervisor/supervisord.conf exists and dpkg
# wants to ask Y/N.
#
# Move the old config away BEFORE apt touches it.
# --------------------------------------------------

if [ -f /etc/supervisor/supervisord.conf ]; then
    echo "[STARTUP] Removing old Supervisor conffile..."

    mv \
      /etc/supervisor/supervisord.conf \
      /etc/supervisor/supervisord.conf.backup \
      2>/dev/null || true
fi

# --------------------------------------------------
# Fix interrupted dpkg without interaction
# --------------------------------------------------

dpkg --configure -a \
  -Dpkg::Options::="--force-confnew" \
  2>/dev/null || true

# ==================================================
# 2. Install packages
# ==================================================

echo "[STARTUP] Updating apt..."

apt-get update

echo "[STARTUP] Installing dependencies..."

apt-get \
  -o Dpkg::Options::="--force-confnew" \
  --fix-broken install -y

apt-get \
  -o Dpkg::Options::="--force-confnew" \
  install -y \
  supervisor \
  ocl-icd-libopencl1 \
  curl

# Final dpkg configuration
dpkg --configure -a 2>/dev/null || true

echo "[STARTUP] Supervisor version:"
supervisord --version

# ==================================================
# 3. Worker name
# ==================================================

if [ -n "$1" ]; then
    WORKER="$1"
else
    WORKER="$(hostname -s)"
fi

echo "[STARTUP] Worker: $WORKER"

# ==================================================
# 4. Directories
# ==================================================

mkdir -p /opt
mkdir -p /var/log/supervisor
mkdir -p /etc/supervisor/conf.d

cd /opt

# ==================================================
# 5. Download WildRig
# ==================================================

WILDRIG_VERSION="0.51.3"
WILDRIG_FILE="wildrig-multi-linux-${WILDRIG_VERSION}.tar.gz"
WILDRIG_URL="https://github.com/andru-kun/wildrig-multi/releases/download/${WILDRIG_VERSION}/${WILDRIG_FILE}"

if [ ! -x /opt/wildrig-multi ]; then

    echo "[STARTUP] Downloading WildRig ${WILDRIG_VERSION}..."

    rm -f "/opt/${WILDRIG_FILE}"

    curl -fL \
      -o "/opt/${WILDRIG_FILE}" \
      "$WILDRIG_URL"

    echo "[STARTUP] Extracting WildRig..."

    tar -xzf "/opt/${WILDRIG_FILE}"

    rm -f "/opt/${WILDRIG_FILE}"

    chmod +x /opt/wildrig-multi

else

    echo "[STARTUP] WildRig already exists."

fi

# Verify
if [ ! -x /opt/wildrig-multi ]; then
    echo "[ERROR] WildRig binary not found!"
    exit 1
fi

# ==================================================
# 6. Stop old WildRig
# ==================================================

echo "[STARTUP] Stopping old WildRig..."

pkill -f "/opt/wildrig-multi.*pearlhash" 2>/dev/null || true

sleep 2

# ==================================================
# 7. Create Supervisor config
# ==================================================

echo "[STARTUP] Creating Supervisor config..."

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

# ==================================================
# 8. Clean old Supervisor runtime
# ==================================================

rm -f /var/run/supervisord.pid
rm -f /var/run/supervisor.sock

# ==================================================
# 9. Start Supervisor
# ==================================================

echo "[STARTUP] Starting Supervisor..."

if ! pgrep -x supervisord >/dev/null 2>&1; then

    supervisord \
      -c /etc/supervisor/supervisord.conf

    sleep 2

else

    echo "[STARTUP] Supervisor already running."

fi

# ==================================================
# 10. Reload Supervisor configuration
# ==================================================

echo "[STARTUP] Reloading Supervisor..."

supervisorctl reread
supervisorctl update

# ==================================================
# 11. Start Pearl
# ==================================================

echo "[STARTUP] Starting Pearl miner..."

supervisorctl restart pearl 2>/dev/null || \
supervisorctl start pearl

sleep 3

# ==================================================
# 12. Status
# ==================================================

echo ""
echo "========================================"
echo "[STARTUP] COMPLETE"
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
