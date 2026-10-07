#!/usr/bin/env bash
# =============================================================================
# osx_prefs.sh — macOS Productivity Defaults & TouchID Sudo for gMac
# =============================================================================
set -euo pipefail

echo "==> Applying macOS productivity preferences..."

# Keyboard: Full keyboard navigation & fast key repeat
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
defaults write -g ApplePressAndHoldEnabled -bool false

# Finder: Show status bar, path bar, search current folder by default
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder QLEnableTextSelection -bool true

# Network/USB: Prevent .DS_Store creation on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show ~/Library folder in Finder
chflags nohidden ~/Library 2>/dev/null || true

# Enable TouchID for sudo via /etc/pam.d/sudo_local (survives macOS updates & corp Puppet)
if [ -f /etc/pam.d/sudo_local.template ] && [ ! -f /etc/pam.d/sudo_local ] && grep -q "sudo_local" /etc/pam.d/sudo 2>/dev/null; then
  echo "==> Configuring TouchID for sudo (/etc/pam.d/sudo_local)..."
  sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
  sudo sed -i '' 's/#auth       sufficient     pam_tid.so/auth       sufficient     pam_tid.so/' /etc/pam.d/sudo_local
fi

for app in Finder Dock; do
  killall "$app" >/dev/null 2>&1 || true
done

echo "✅ macOS preferences applied."
