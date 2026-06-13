#!/bin/bash
# kiki hub — Linux / NAS installer
# Run with: bash <(curl -fsSL https://arcanedata.us/kiki/hub/nas-install.sh)
# Supports: Synology DSM 7+, QNAP, Unraid, TrueNAS Scale, Ubuntu, Debian, any Linux

set -e

BASE_URL="https://arcanedata.us/kiki/hub"
INSTALL_DIR="/opt/kiki"
BINARY="$INSTALL_DIR/kiki-hub"
DATA_DIR="/opt/kiki/data"
PORT=8787

BOLD=$(tput bold 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo "  $1"; }
success() { echo -e "  ${GREEN}✓${NC}  $1"; }
warn()    { echo -e "  ${YELLOW}!${NC}  $1"; }
fail()    { echo -e "  ${RED}✗${NC}  $1"; exit 1; }
header()  { echo; echo "${BOLD}$1${RESET}"; echo "  ────────────────────────────────"; }

echo
echo "${BOLD}kiki hub setup — Linux / NAS${RESET}"
echo "  installs the kiki hub and starts it automatically."
echo

# ── 1. Check requirements ─────────────────────────────────────────────────────
header "checking requirements"

[ "$(uname -s)" = "Linux" ] || fail "this installer is for Linux only. for macOS, use the Mac installer."
command -v curl &>/dev/null || fail "curl is required but not found"
success "Linux $(uname -r | cut -d- -f1)"

# ── 2. Detect architecture ────────────────────────────────────────────────────
header "downloading kiki hub"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)          BINARY_URL="$BASE_URL/kiki-hub-linux-amd64"; info "detected x86_64 (amd64)" ;;
  aarch64|arm64)   BINARY_URL="$BASE_URL/kiki-hub-linux-arm64"; info "detected arm64" ;;
  *) fail "unsupported architecture: $ARCH. contact info@arcanedata.us for help." ;;
esac

# ── 3. Install binary ─────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR" "$DATA_DIR"
info "downloading..."
curl -fsSL "$BINARY_URL" -o "$BINARY"
chmod +x "$BINARY"
success "installed → $BINARY"

# ── 4. Set up auto-start ──────────────────────────────────────────────────────
header "setting up auto-start"

if command -v systemctl &>/dev/null && [ -d /etc/systemd/system ]; then
  # systemd path (Synology DSM 7+, QNAP, Unraid, TrueNAS Scale, Ubuntu, Debian)
  cat > /etc/systemd/system/kiki-hub.service << SERVICE
[Unit]
Description=kiki hub
After=network.target

[Service]
Type=simple
ExecStart=$BINARY -addr :$PORT -data-dir $DATA_DIR
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

  systemctl daemon-reload
  systemctl enable kiki-hub
  systemctl restart kiki-hub
  sleep 2

  if systemctl is-active --quiet kiki-hub; then
    success "systemd service running"
  else
    warn "service may still be starting — check: journalctl -u kiki-hub -n 20"
  fi

else
  # Fallback: rc.local / init.d (older NAS firmware)
  warn "systemd not found — using rc.local fallback"

  STARTUP_SCRIPT="/etc/rc.local"
  if [ -f "$STARTUP_SCRIPT" ]; then
    # inject before exit 0 if present
    if grep -q "^exit 0" "$STARTUP_SCRIPT"; then
      sed -i "s|^exit 0|$BINARY -addr :$PORT -data-dir $DATA_DIR \&\nexit 0|" "$STARTUP_SCRIPT"
    else
      echo "$BINARY -addr :$PORT -data-dir $DATA_DIR &" >> "$STARTUP_SCRIPT"
    fi
  else
    echo "#!/bin/bash" > "$STARTUP_SCRIPT"
    echo "$BINARY -addr :$PORT -data-dir $DATA_DIR &" >> "$STARTUP_SCRIPT"
    chmod +x "$STARTUP_SCRIPT"
  fi

  # Start it now
  "$BINARY" -addr :$PORT -data-dir $DATA_DIR &
  sleep 2
  success "started (rc.local configured for auto-start on boot)"
fi

# ── 5. Verify ─────────────────────────────────────────────────────────────────
header "verifying"

if curl -s "http://localhost:$PORT/healthz" | grep -q "ok"; then
  success "health check passed"
else
  warn "hub started but health check hasn't responded yet — may still be initialising"
fi

LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1 | awk '{print $7; exit}' || echo "unknown")

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo "${BOLD}kiki hub is ready${RESET}"
echo
echo "  hub address  http://$LOCAL_IP:$PORT"
echo "  data folder  $DATA_DIR"
echo
echo "  open kiki on your iPhone and go to Settings → hub url"
echo "  enter:  http://$LOCAL_IP:$PORT"
echo
echo "  if your router supports mDNS the app may find the hub automatically."
echo "  if not, use the address above."
echo
echo "  to view logs:"
if command -v systemctl &>/dev/null; then
  echo "    journalctl -u kiki-hub -f"
else
  echo "    $INSTALL_DIR/hub.log (if configured)"
fi
echo
echo "  to uninstall:"
if command -v systemctl &>/dev/null; then
  echo "    systemctl stop kiki-hub && systemctl disable kiki-hub"
  echo "    rm /etc/systemd/system/kiki-hub.service && rm -rf $INSTALL_DIR"
else
  echo "    kill \$(pgrep kiki-hub) && rm -rf $INSTALL_DIR"
fi
echo
