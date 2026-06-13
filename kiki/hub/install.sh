#!/bin/bash
# kiki hub — macOS installer
# Run with: bash <(curl -fsSL https://arcanedata.us/kiki/hub/install.sh)
# Requires macOS 12+

set -e

BASE_URL="https://arcanedata.us/kiki/hub"
INSTALL_DIR="$HOME/.kiki"
BINARY="$INSTALL_DIR/kiki-hub"
DATA_DIR="$HOME/.kiki-hub"
PLIST_LABEL="us.arcanedata.kiki-hub"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
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
echo "${BOLD}kiki hub setup${RESET}"
echo "  installs the kiki hub on this Mac and starts it automatically."
echo

# ── 1. Check macOS and curl ──────────────────────────────────────────────────
header "checking requirements"

if ! command -v curl &>/dev/null; then
  fail "curl is required but not found"
fi
success "macOS $(sw_vers -productVersion)"

# ── 2. Detect architecture and download binary ────────────────────────────────
header "downloading kiki hub"

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  BINARY_URL="$BASE_URL/kiki-hub-darwin-arm64"
  info "detected Apple Silicon (arm64)"
elif [ "$ARCH" = "x86_64" ]; then
  BINARY_URL="$BASE_URL/kiki-hub-darwin-amd64"
  info "detected Intel (x86_64)"
else
  fail "unsupported architecture: $ARCH"
fi

mkdir -p "$INSTALL_DIR"
info "downloading..."
curl -fsSL "$BINARY_URL" -o "$BINARY"
chmod +x "$BINARY"
success "downloaded → $BINARY"

# ── 5. Create data directory ──────────────────────────────────────────────────
mkdir -p "$DATA_DIR"
success "data directory → $DATA_DIR"

# ── 6. Create launchd service (auto-start on login) ──────────────────────────
header "setting up auto-start"

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_PATH" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$PLIST_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BINARY</string>
    <string>-addr</string>
    <string>:$PORT</string>
    <string>-data-dir</string>
    <string>$DATA_DIR</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$HOME/.kiki/hub.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/.kiki/hub.log</string>
</dict>
</plist>
PLIST

success "launchd service created"

# ── 7. Start the service ──────────────────────────────────────────────────────
header "starting hub"

# stop existing instance if running
launchctl unload "$PLIST_PATH" 2>/dev/null || true
sleep 1
launchctl load "$PLIST_PATH"
sleep 2

# verify it's running
if launchctl list | grep -q "$PLIST_LABEL"; then
  success "hub is running on port $PORT"
else
  fail "hub failed to start — check $HOME/.kiki/hub.log for details"
fi

# ── 8. Find local IP ──────────────────────────────────────────────────────────
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "unknown")

# ── 9. Verify health endpoint ─────────────────────────────────────────────────
sleep 1
if curl -s "http://localhost:$PORT/healthz" | grep -q "ok"; then
  success "health check passed"
else
  warn "hub started but health check didn't respond yet — it may still be starting"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo "${BOLD}kiki hub is ready${RESET}"
echo
echo "  hub address  http://$LOCAL_IP:$PORT"
echo "  data folder  $DATA_DIR"
echo "  log file     $HOME/.kiki/hub.log"
echo
echo "  open kiki on your iPhone — it will find this hub automatically"
echo "  if auto-discover doesn't work, enter the hub address manually in Settings"
echo
echo "  the hub starts automatically every time you log in to this Mac."
echo
echo "  to stop the hub:"
echo "    launchctl unload $PLIST_PATH"
echo
echo "  to uninstall:"
echo "    launchctl unload $PLIST_PATH && rm -rf $INSTALL_DIR $PLIST_PATH"
echo
