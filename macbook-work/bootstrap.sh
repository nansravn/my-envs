#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Bootstrap a fresh Google corporate MacBook (gMac)
# =============================================================================
# Installs Homebrew, Brewfile packages/casks/fonts/extensions, Oh My Zsh,
# fzf-tab, deploys sanitized dotfiles & IDE settings, and optionally applies
# macOS developer preferences + TouchID sudo (--osx-prefs or APPLY_OSX_PREFS=1).
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT_DIR="$HERE/dotfiles"
IDE_DIR="$HERE/ide"

APPLY_OSX_PREFS="${APPLY_OSX_PREFS:-0}"
for arg in "$@"; do
  case "$arg" in
    --osx-prefs) APPLY_OSX_PREFS=1 ;;
  esac
done

echo "==> [1/6] Checking Xcode Command Line Tools..."
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Triggering Xcode Command Line Tools install..."
  xcode-select --install || true
else
  echo "Xcode Command Line Tools detected: $(xcode-select -p)"
fi

echo "==> [2/6] Checking Homebrew installation..."
if ! command -v brew >/dev/null 2>&1; then
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -x "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  echo "Homebrew detected: $(command -v brew)"
fi

echo "==> [3/6] Installing packages, casks, fonts & extensions from Brewfile..."
brew bundle install --file="$HERE/Brewfile" || \
  echo "⚠️ Note: Some optional casks or extensions may require manual login or are managed by corp MDM."

echo "==> [4/6] Installing Oh My Zsh & fzf-tab..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh (unattended)..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
fi

mkdir -p "$HOME/.zsh"
if [ ! -d "$HOME/.zsh/fzf-tab" ]; then
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$HOME/.zsh/fzf-tab"
fi

echo "==> [5/6] Backing up existing dotfiles and deploying macbook-work configs..."
for f in .zshrc .gitconfig .tmux.conf; do
  if [ -f "$DOT_DIR/$f" ]; then
    [ -f "$HOME/$f" ] && cp -n "$HOME/$f" "$HOME/$f.pre-bootstrap.bak" || true
    cp "$DOT_DIR/$f" "$HOME/$f"
  fi
done

if [ ! -f "$HOME/.gitconfig.local" ]; then
  cat <<'EOF' > "$HOME/.gitconfig.local"
[user]
	email = renanvn@google.com
	name = Renan Vilas Novas
EOF
fi

mkdir -p "$HOME/.config/oh-my-posh"
cp "$DOT_DIR/.config/oh-my-posh/atomic_renan.omp.json" "$HOME/.config/oh-my-posh/atomic_renan.omp.json"

if [ -f "$IDE_DIR/vscode-settings.json" ]; then
  for target_dir in \
    "$HOME/Library/Application Support/Code/User" \
    "$HOME/Library/Application Support/Jetski/User" \
    "$HOME/Library/Application Support/Antigravity/User"; do
    mkdir -p "$target_dir"
    [ -f "$target_dir/settings.json" ] && cp -n "$target_dir/settings.json" "$target_dir/settings.json.pre-bootstrap.bak" || true
    cp "$IDE_DIR/vscode-settings.json" "$target_dir/settings.json"
  done
fi

echo "==> [6/6] macOS Preferences & TouchID sudo..."
if [ "$APPLY_OSX_PREFS" = "1" ]; then
  echo "Applying macOS productivity defaults..."
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
  defaults write -g ApplePressAndHoldEnabled -bool false
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder QLEnableTextSelection -bool true
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
  chflags nohidden ~/Library 2>/dev/null || true

  if [ -f /etc/pam.d/sudo_local.template ] && [ ! -f /etc/pam.d/sudo_local ] && grep -q "sudo_local" /etc/pam.d/sudo 2>/dev/null; then
    echo "Configuring TouchID for sudo (/etc/pam.d/sudo_local)..."
    sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
    sudo sed -i '' 's/#auth       sufficient     pam_tid.so/auth       sufficient     pam_tid.so/' /etc/pam.d/sudo_local
  fi

  for app in Finder Dock; do
    killall "$app" >/dev/null 2>&1 || true
  done
else
  echo "Skipping macOS defaults (re-run with './bootstrap.sh --osx-prefs' to apply Finder/keyboard defaults & TouchID sudo)."
fi

cat <<'NOTE'

✅ Bootstrap complete!

Next manual steps on a fresh gMac:
  1. Run `gcert` and `gnubby-ssh-keygen` to initialize corporate SSH/LOAS credentials.
  2. Run `gh auth login` and `gcloud auth login`.
  3. Run `./sync_repos.sh restore-all` to clone remote repos and restore local/dirty bundles from Google Drive.
  4. Open a new terminal window to land in zsh + Oh My Posh.
NOTE
