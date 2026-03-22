#!/usr/bin/env bash
# bootstrap/setup-nas-mount.sh — Auto-mount NAS share via SMB LaunchAgent
# Share: smb://brian@primary.storage.local/brians_storage
# Mount Point: /Volumes/Brians_Storage
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC}  $*"; }
warn() { echo -e "${YELLOW}⚠${NC}  $*"; }

MOUNT_POINT="/Volumes/Brians_Storage"
PLIST_LABEL="com.brian.nasmount"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

# Create mount point (requires sudo)
if [[ -d "$MOUNT_POINT" ]]; then
  ok "Mount point exists: $MOUNT_POINT"
else
  if sudo -n true 2>/dev/null; then
    sudo mkdir -p "$MOUNT_POINT"
    ok "Created mount point: $MOUNT_POINT"
  else
    warn "Skipping mount point creation (requires sudo): $MOUNT_POINT"
    warn "Run manually: sudo mkdir -p $MOUNT_POINT"
    exit 1
  fi
fi

# Unload existing LaunchAgent if present
launchctl bootout gui/$(id -u) "$PLIST_PATH" 2>/dev/null || true
ok "Cleared previous LaunchAgent (if any)"

# Write LaunchAgent plist
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST_PATH" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.brian.nasmount</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>mount | grep -q '/Volumes/Brians_Storage' || /sbin/mount_smbfs //brian@primary.storage.local/brians_storage /Volumes/Brians_Storage</string>
    </array>
    <key>StartInterval</key>
    <integer>60</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST
ok "Wrote LaunchAgent: $PLIST_PATH"

# Load LaunchAgent
launchctl bootstrap gui/$(id -u) "$PLIST_PATH"
ok "Loaded LaunchAgent: $PLIST_LABEL"

# Verify
if launchctl list | grep -q nasmount; then
  ok "LaunchAgent running"
else
  warn "LaunchAgent may not have loaded — check: launchctl list | grep nasmount"
fi

echo ""
echo "Remember: connect manually once via Finder first and"
echo "check 'Remember this password in my keychain' for silent remounts."
