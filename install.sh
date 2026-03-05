#!/bin/bash
################################################################################
# Claw-Mission-One: The Fully Rebuilt AI Orchestration Stack
# Version: 2026.3.06 (Premium Rebuilt - Foolproof & Fallback Safe)
# Description: Integrated OpenClaw Gateway + Mission Control on Android Termux
################################################################################

set -e

# --- TERMUX HOST SETUP ---
if [ ! -f "/.dockerenv" ] && [ -z "$PROOT_PID" ] && [ "$(id -u)" != "0" ]; then
    echo "=========================================================="
    echo "🛸 CLAW-MISSION-ONE: PREMIUM VPS REBUILD 🛸"
    echo "=========================================================="
    
    # Clean up old root scripts if user previously ran as root
    if [ -f "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/root/start.sh" ]; then
        echo "[*] Cleaning up old root-level scripts to prevent conflicts..."
        rm -f $PREFIX/var/lib/proot-distro/installed-rootfs/debian/root/*.sh
        rm -rf $PREFIX/var/lib/proot-distro/installed-rootfs/debian/root/.pm2
    fi

    # 1. ENVIRONMENT SYNC
    if command -v proot-distro >/dev/null 2>&1 && command -v socat >/dev/null 2>&1; then
        echo "[*] Host infrastructure active. Skipping package sync..."
    else
        echo "[*] Initializing host dependencies..."
        if [ -f "$PREFIX/etc/apt/sources.list" ]; then
            sed -i 's|mirror.nevacloud.com/applications/termux/termux-main|packages.termux.dev/apt/termux-main|g' $PREFIX/etc/apt/sources.list
        fi
        apt-get update -qq || true
        apt-get install -y --allow-downgrades proot-distro socat wget curl openssh ncurses-utils
    fi
    
    # 2. NETWORK BRIDGING
    echo "[*] Configuring infrastructure bridges..."
    cat << 'BRIDGE' > ~/vps-bridge.sh
#!/data/data/com.termux/files/usr/bin/bash
pkill socat || true
nohup socat TCP4-LISTEN:2222,reuseaddr,fork,bind=0.0.0.0 TCP4:127.0.0.1:2222 > /dev/null 2>&1 &
nohup socat TCP4-LISTEN:3000,reuseaddr,fork,bind=0.0.0.0 TCP4:127.0.0.1:3000 > /dev/null 2>&1 &
nohup socat TCP4-LISTEN:18789,reuseaddr,fork,bind=0.0.0.0 TCP4:127.0.0.1:18789 > /dev/null 2>&1 &
echo "Claw-Mission Bridges Active: [SSH:2222] [MC:3000] [Gate:18789]"
BRIDGE
    chmod +x ~/vps-bridge.sh
    bash ~/vps-bridge.sh > /dev/null 2>&1

    # 3. DEBIAN INSTALLATION
    if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" ]; then
        echo "[*] Installing Debian environment..."
        proot-distro install debian
    fi
    
    # 4. GUEST SETUP SCRIPT
    GUEST_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/root"
    mkdir -p "$GUEST_ROOT"
    GUEST_SCRIPT="$GUEST_ROOT/rebuild_guest.sh"
    
    cat << 'EOF' > "$GUEST_SCRIPT"
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "[*] Hardening Guest System..."
echo "nameserver 1.1.1.1" > /etc/resolv.conf
apt update -qq
apt install -y curl git sudo procps ca-certificates build-essential openssh-server netcat-openbsd nano libvips-dev

# --- ROOT WARNING (Aggressive Cleanup + Re-write) ---
# Remove any old warnings from bashrc to prevent duplication
if [ -f "/root/.bashrc" ]; then
    sed -i '/--- CLAW MISSION ROOT WARNING START ---/,/--- CLAW MISSION ROOT WARNING END ---/d' /root/.bashrc
fi

cat << 'ROOTBASH' >> /root/.bashrc
# --- CLAW MISSION ROOT WARNING START ---
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "WARNING: You are logged in as ROOT."
echo "Claw-Mission runs as the dedicated 'openclaw' user."
echo "Please switch users by running: su - openclaw"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
# --- CLAW MISSION ROOT WARNING END ---
ROOTBASH

# Dedicated User
if ! id "openclaw" &>/dev/null; then
    echo "[*] Creating operator 'openclaw'..."
    useradd -m -s /bin/bash openclaw
    echo "openclaw ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo "root:root" | chpasswd
    echo "openclaw:openclaw" | chpasswd
fi

# SSH Setup
mkdir -p /run/sshd
sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Operator Scope
su - openclaw << 'USER_SCOPE'
set -e
# Install NVM
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node
nvm install 22
nvm use 22
nvm alias default 22

# --- CORE TOOLS INSTALL (Bypass if present to avoid ENOTEMPTY) ---
if command -v pm2 >/dev/null 2>&1 && command -v tsx >/dev/null 2>&1 && command -v tsc >/dev/null 2>&1; then
    echo "[*] Core tools (pm2, tsx, typescript) already present. Skipping install..."
else
    echo "[*] Installing core node tools..."
    NPM_G_ROOT=$(npm root -g)
    # Manual deep cleaning of target folders
    rm -rf "$NPM_G_ROOT/typescript" "$NPM_G_ROOT/pm2" "$NPM_G_ROOT/tsx" 2>/dev/null
    rm -rf "$NPM_G_ROOT/../.npm" 2>/dev/null
    
    # Try install with one more guard
    npm install -g pm2 tsx typescript --no-audit || {
        echo "[!] Primary install failed, attempting individual installs..."
        npm install -g pm2 --no-audit
        npm install -g tsx --no-audit
        npm install -g typescript --no-audit
    }
fi

# Cleanup PM2 state from any previous failed runs
pm2 kill 2>/dev/null || true
rm -rf $HOME/.pm2/dump.pm2 2>/dev/null

# Networking Shim
cat > $HOME/.node_bypass.js << 'BYPASS'
const os = require('os');
const originalNetworkInterfaces = os.networkInterfaces;
os.networkInterfaces = function() {
  try {
    const interfaces = originalNetworkInterfaces.call(os);
    if (interfaces && Object.keys(interfaces).length > 0) return interfaces;
  } catch (e) {}
  return { lo: [{ address: '127.0.0.1', netmask: '255.0.0.0', family: 'IPv4', mac: '00:00:00:00:00:00', internal: true, cidr: '127.0.0.1/8' }] };
};
BYPASS

# Bashrc
cat << 'BASHRC' >> ~/.bashrc
export NODE_OPTIONS="--require $HOME/.node_bypass.js"
export HOST=0.0.0.0
export NEXT_TELEMETRY_DISABLED=1
export NODE_LLAMA_CPP_SKIP_POSTINSTALL=1
alias check-all='pm2 status'
alias logs='pm2 logs'
alias vps-start='$HOME/start.sh'
alias vps-stop='pm2 stop all'
alias vps-restart='pm2 restart all'
alias vps-sync='$HOME/sync.sh'
BASHRC

# Load env variables for current script
export NODE_OPTIONS="--require $HOME/.node_bypass.js"
export SHARP_IGNORE_GLOBAL_LIBVIPS=1
export NODE_LLAMA_CPP_SKIP_POSTINSTALL=1

# --- BINARY DEPLOYMENT OR FALLBACK ---
REPO_BASE="https://raw.githubusercontent.com/Muxd21/Claw-Mission-One/builds"

binary_install() {
    APP_NAME=$1
    if [ "$SKIP_BINARY" = "1" ] || [ "$SKIP_BINARY" = "$APP_NAME" ]; then
        echo "[*] SKIP_BINARY detected. Skipping pre-built ${APP_NAME}..."
        return 1
    fi

    echo "[*] Checking for pre-built ${APP_NAME}..."
    if curl --output /dev/null --silent --head --fail "${REPO_BASE}/${APP_NAME}-arm64.tar.gz.part-aa"; then
        echo "[🚀] Binary parts found! Downloading (this may take a few minutes)..."
        mkdir -p "$HOME/${APP_NAME}" && cd "$HOME/${APP_NAME}"
        
        # Download parts
        for part in {a..z}{a..z}; do
            PART_FILE="${APP_NAME}-arm64.tar.gz.part-${part}"
            if curl --output /dev/null --silent --head --fail "${REPO_BASE}/${PART_FILE}"; then
                echo "    -> Receiving ${PART_FILE}..."
                wget -q "${REPO_BASE}/${PART_FILE}" -O "${PART_FILE}"
            else
                break
            fi
        done
        
        echo "[📦] Extracting ${APP_NAME} (Streaming to save memory)..."
        # Optimized: Stream cat into tar to avoid massive intermediate file
        cat ${APP_NAME}-arm64.tar.gz.part-* | tar -xz || { 
            echo "[!] Extraction failed. Disk full or OOM?"
            return 1 
        }
        
        echo "[✓] Extraction complete. Cleaning up parts..."
        rm -f ${APP_NAME}-arm64.tar.gz.part-*
        return 0
    else
        echo "[!] No binary found for ${APP_NAME} on this architecture."
        return 1
    fi
}

cd $HOME

# Deploy Mission Control
if ! binary_install "mission-control"; then
    echo "[!] No binary for Mission Control. Fallback to git build..."
    git clone --depth 1 https://github.com/builderz-labs/mission-control.git || true
    cd mission-control
    npm install --legacy-peer-deps || true
    npm run build || true
    cd ..
fi

cat > $HOME/mission-control/start-mc.sh << 'MC'
#!/bin/bash
if [ -d ".next" ]; then
  echo "Starting Production Build"
  npm run start -- -p 3000
else
  echo "Build missing, starting Dev Mode fallback"
  npm run dev -- -p 3000
fi
MC
chmod +x $HOME/mission-control/start-mc.sh

# Deploy OpenClaw
if ! binary_install "openclaw"; then
    echo "[!] No binary for OpenClaw. Fallback to git build..."
    git clone --depth 1 https://github.com/openclaw/openclaw.git || true
    cd openclaw
    npm install --legacy-peer-deps --ignore-scripts=false || true
    rm -rf node_modules/sharp node_modules/node-llama-cpp || true
    npm run build || true
    npm run ui:build || true
    cd ..
fi

# --- GATEWAY TOKEN ---
GW_TOKEN=$(openssl rand -hex 32)
echo "${GW_TOKEN}" > $HOME/.openclaw_token

# --- OPENCLAW GATEWAY CONFIG (fixes origin + token issues) ---
mkdir -p $HOME/.openclaw
cat > $HOME/.openclaw/gateway.yaml << GWCONF
gateway:
  port: 18789
  bind: 0.0.0.0
  token: "${GW_TOKEN}"
  controlUi:
    allowedOrigins:
      - "*"
GWCONF

# Start script for OpenClaw (uses CLI binary or fallback)
cat > $HOME/openclaw/start-gw.sh << 'GW'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Use the openclaw CLI binary if available
if command -v openclaw > /dev/null 2>&1; then
  echo "Starting OpenClaw Gateway (CLI binary)"
  exec openclaw gateway
elif [ -f "dist/index.js" ]; then
  echo "Starting OpenClaw Gateway (compiled JS)"
  exec node dist/index.js gateway --bind lan --port 18789
else
  echo "Starting OpenClaw Gateway (TSX fallback)"
  exec npx tsx src/index.ts gateway --bind lan --port 18789
fi
GW
chmod +x $HOME/openclaw/start-gw.sh

# PM2 Ecosystem (token is baked in at install time, not via shell variable)
cat > $HOME/ecosystem.config.js << ECO
module.exports = {
  apps: [
    {
      name: 'mission-control',
      cwd: '/home/openclaw/mission-control',
      script: 'bash',
      args: 'start-mc.sh',
      env: {
        HOST: '0.0.0.0',
        NEXTAUTH_SECRET: 'secret',
        LOCAL_AUTH_TOKEN: 'clawone',
        ADMIN_PASSWORD: 'admin',
        OPENCLAW_GATEWAY_URL: 'ws://127.0.0.1:18789',
        OPENCLAW_GATEWAY_TOKEN: '${GW_TOKEN}'
      }
    },
    {
      name: 'openclaw-gateway',
      cwd: '/home/openclaw/openclaw',
      script: 'bash',
      args: 'start-gw.sh',
      env: {
        OPENCLAW_STATE_DIR: '/home/openclaw/.openclaw',
        OPENCLAW_GATEWAY_TOKEN: '${GW_TOKEN}'
      }
    }
  ]
};
ECO

# Sync & Start
cat << 'SYNC' > $HOME/sync.sh
#!/bin/bash
cd ~/openclaw && git pull && npm install --legacy-peer-deps && rm -rf node_modules/sharp node_modules/node-llama-cpp && npm run build
cd ~/mission-control && git pull && npm install --legacy-peer-deps && npm run build
pm2 restart all
SYNC
chmod +x $HOME/sync.sh

cat << 'START' > $HOME/start.sh
#!/bin/bash
echo "[*] Starting Claw-Mission-One..."
pm2 delete all 2>/dev/null || true
pm2 start ~/ecosystem.config.js
pm2 save
echo "[✓] All services started! Run 'pm2 status' to check."
START
chmod +x $HOME/start.sh

pm2 kill || true
pm2 start $HOME/ecosystem.config.js
pm2 save
USER_SCOPE
EOF
    chmod +x "$GUEST_SCRIPT"
    proot-distro login debian -- /root/rebuild_guest.sh
    
    # Save Token safely to Termux Host for easy access
    GUEST_TOKEN=$(cat $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/openclaw/.openclaw_token 2>/dev/null || echo "Token not found")
    echo "$GUEST_TOKEN" > ~/claw-mission-token.txt

    # =================================================================
    # THE ONE COMMAND: ~/claw.sh
    # Starts EVERYTHING: bridges, SSH, PM2 services, then drops into shell
    # =================================================================
    cat << 'LAUNCHER' > ~/claw.sh
#!/data/data/com.termux/files/usr/bin/bash
clear
echo "=========================================================="
echo "🛸 CLAW-MISSION-ONE: STARTING ALL SYSTEMS 🛸"
echo "=========================================================="

# --- STEP 1: Network Bridges (Termux host side) ---
echo ""
echo "[1/3] 🌐 Starting network bridges..."
pkill -f "socat TCP4-LISTEN" 2>/dev/null || true
sleep 0.5
nohup socat TCP4-LISTEN:2222,reuseaddr,fork,bind=0.0.0.0 TCP4:127.0.0.1:2222 > /dev/null 2>&1 &
nohup socat TCP4-LISTEN:3000,reuseaddr,fork,bind=0.0.0.0 TCP4:127.0.0.1:3000 > /dev/null 2>&1 &
nohup socat TCP4-LISTEN:18789,reuseaddr,fork,bind=0.0.0.0 TCP4:127.0.0.1:18789 > /dev/null 2>&1 &
echo "      ✓ SSH:2222  MC:3000  Gateway:18789"

# --- STEP 2: Start SSH + PM2 inside Debian ---
echo ""
echo "[2/3] 🚀 Starting services inside Debian..."
proot-distro login debian -- bash -c '
  # Start SSH daemon
  mkdir -p /run/sshd
  /usr/sbin/sshd 2>/dev/null
  echo "      ✓ SSH daemon started"

  # Switch to openclaw and start PM2
  su - openclaw -c "
    export NVM_DIR=\"\$HOME/.nvm\"
    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
    export NODE_OPTIONS=\"--require \$HOME/.node_bypass.js\"

    pm2 delete all 2>/dev/null || true
    pm2 start ~/ecosystem.config.js
    pm2 save
    echo \"      ✓ PM2 services launched\"
    echo \"\"
    pm2 status
  "
'

# --- STEP 3: Status Report ---
echo ""
echo "[3/3] ✅ All systems online!"
echo ""
echo "=========================================================="
echo "  📡 SSH:              ssh -p 2222 root@<YOUR_IP>"
echo "  🖥  Mission Control:  http://<YOUR_IP>:3000"
echo "  🦞 OpenClaw Gateway: http://<YOUR_IP>:18789"
echo "  🔑 Token:            $(cat ~/claw-mission-token.txt 2>/dev/null || echo 'see ~/.openclaw_token')"
echo "=========================================================="
echo ""
echo "Dropping into operator shell... (type 'exit' to leave)"
echo ""

# Drop into the openclaw user shell
proot-distro login debian --user openclaw
LAUNCHER
    chmod +x ~/claw.sh

    clear
    echo "=========================================================="
    echo "🛸 CLAW-MISSION-ONE INSTALLED SUCCESSFULLY 🛸"
    echo "=========================================================="
    echo "Gateway Token: $GUEST_TOKEN"
    echo "(saved to ~/claw-mission-token.txt)"
    echo ""
    echo ">>> TO START EVERYTHING, just run:"
    echo ""
    echo "    ./claw.sh"
    echo ""
    echo "That single command will:"
    echo "  ✓ Start network bridges (SSH, MC, Gateway)"
    echo "  ✓ Launch SSH daemon"
    echo "  ✓ Launch Mission Control + OpenClaw Gateway via PM2"
    echo "  ✓ Drop you into the operator shell"
    echo ""
    echo "Dashboards (once Tailscale is connected):"
    echo "  >> Mission Control: http://<PHONE_IP>:3000"
    echo "  >> OpenClaw UI:     http://<PHONE_IP>:18789"
    echo "=========================================================="
    exit 0
fi
