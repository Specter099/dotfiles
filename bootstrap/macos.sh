#!/usr/bin/env bash
# bootstrap/macos.sh — Sensible macOS defaults
# Run as your normal user (not root). Some settings require logout to take effect.
set -euo pipefail

GREEN='\033[0;32m'; NC='\033[0m'
ok() { echo -e "${GREEN}✓${NC}  $*"; }

echo "Applying macOS preferences..."

# Close System Preferences/Settings to prevent override
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# ── Keyboard ──────────────────────────────────────────────────────────────────
# Key repeat rate (lower = faster)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
ok "Key repeat: fast"

# Disable press-and-hold (enable key repeat in all apps)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
ok "Key repeat: press-and-hold disabled"

# ── Trackpad ─────────────────────────────────────────────────────────────────
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
ok "Trackpad: tap to click"

# ── Finder ────────────────────────────────────────────────────────────────────
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
ok "Finder: show hidden files"

# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
ok "Finder: show all extensions"

# Show path bar and status bar
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
ok "Finder: path bar + status bar"

# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
ok "Finder: list view default"

# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
ok "Finder: no extension change warning"

# Keep folders on top when sorting
defaults write com.apple.finder _FXSortFoldersFirst -bool true
ok "Finder: folders on top"

# New window opens $HOME
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"
ok "Finder: new window → home"

# ── Dock ──────────────────────────────────────────────────────────────────────
# Auto-hide dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0.1
ok "Dock: auto-hide"

# Smaller dock
defaults write com.apple.dock tilesize -int 42
ok "Dock: tile size 42"

# Don't show recent apps in dock
defaults write com.apple.dock show-recents -bool false
ok "Dock: no recent apps"

# Don't animate opening apps
defaults write com.apple.dock launchanim -bool false
ok "Dock: no launch animation"

# ── Screen ────────────────────────────────────────────────────────────────────
# Save screenshots to ~/Desktop/Screenshots
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"
ok "Screenshots → ~/Desktop/Screenshots"

# Screenshots as PNG
defaults write com.apple.screencapture type -string "png"
ok "Screenshots: PNG format"

# Disable screenshot shadow
defaults write com.apple.screencapture disable-shadow -bool true
ok "Screenshots: no shadow"

# ── Safari ────────────────────────────────────────────────────────────────────
# Show full URL in address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
ok "Safari: full URL"

# ── Terminal / Shell ──────────────────────────────────────────────────────────
# Secure keyboard entry in Terminal
defaults write com.apple.terminal SecureKeyboardEntry -bool true
ok "Terminal: secure keyboard entry"

# ── Activity Monitor ─────────────────────────────────────────────────────────
# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0
# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0
ok "Activity Monitor: all processes, sorted by CPU"

# ── Energy ────────────────────────────────────────────────────────────────────
# Don't sleep display too quickly while on power
if sudo -n true 2>/dev/null; then
  sudo pmset -c displaysleep 15 2>/dev/null || true
  sudo pmset -b displaysleep 5 2>/dev/null || true
  ok "Energy: display sleep 15min (AC), 5min (battery)"
else
  echo "  ⚠  Skipping energy settings (requires sudo)"
fi

# ── Misc ──────────────────────────────────────────────────────────────────────
# Disable Gatekeeper (allows apps from anywhere — remove if you prefer security)
# sudo spctl --master-disable

# Expand save/print dialogs by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
ok "Save/print dialogs: expanded by default"

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
ok "Auto-correct: disabled"

# Disable smart quotes (kills code pasting issues)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
ok "Smart quotes/dashes: disabled"

# ── Apply ─────────────────────────────────────────────────────────────────────
for app in "Finder" "Dock" "SystemUIServer" "Activity Monitor"; do
  killall "$app" &>/dev/null || true
done

echo ""
echo "macOS preferences applied. Some changes require a logout to take full effect."
