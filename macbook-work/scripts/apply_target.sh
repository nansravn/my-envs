#!/usr/bin/env bash
# =============================================================================
# apply_target.sh — [New gMac] Automated Provisioning & Bootstrap Script
# =============================================================================
# Installs Homebrew, Brewfile packages (including modern CLI kit & Casks),
# user-space tools (uv, fzf-tab), deploys dotfiles, and restores IDE configs.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOT_DIR="$PROFILE_DIR/dotfiles"
IDE_DIR="$PROFILE_DIR/ide"
AGENTS_DIR="$PROFILE_DIR/agents"

echo "==> [1/7] Checking Xcode Command Line Tools..."
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Triggering Xcode Command Line Tools install..."
  xcode-select --install || true
else
  echo "Xcode Command Line Tools detected: $(xcode-select -p)"
fi

echo "==> [2/7] Checking Homebrew installation..."
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

echo "==> [3/7] Installing packages & extensions from Brewfile..."
brew bundle install --file="$PROFILE_DIR/Brewfile" || echo "⚠️ Note: Some optional casks or extensions may require manual login or are already managed by corp MDM."

echo "==> [4/7] Installing user-space tools (uv, Oh My Zsh, fzf-tab)..."
mkdir -p "$HOME/.local/bin"
if ! command -v uv >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/uv" ]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh (unattended)..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
fi

mkdir -p "$HOME/.zsh"
if [ ! -d "$HOME/.zsh/fzf-tab" ]; then
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$HOME/.zsh/fzf-tab"
fi

echo "==> [5/7] Backing up existing dotfiles and deploying macbook-work dotfiles..."
for f in .zshrc .profile .gitconfig .tmux.conf; do
  if [ -f "$DOT_DIR/$f" ]; then
    [ -f "$HOME/$f" ] && cp -n "$HOME/$f" "$HOME/$f.pre-bootstrap.bak" || true
    cp "$DOT_DIR/$f" "$HOME/$f"
  fi
done

# Configure corporate email in ~/.gitconfig.local if not set
if [ ! -f "$HOME/.gitconfig.local" ]; then
  cat <<'EOF' > "$HOME/.gitconfig.local"
[user]
	email = renanvn@google.com
	name = Renan Vilas Novas
EOF
fi

mkdir -p "$HOME/.config/oh-my-posh"
if [ -f "$DOT_DIR/.config/oh-my-posh/atomic_renan.omp.json" ]; then
  cp "$DOT_DIR/.config/oh-my-posh/atomic_renan.omp.json" "$HOME/.config/oh-my-posh/atomic_renan.omp.json"
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -f "$DOT_DIR/.ssh/config" ]; then
  [ -f "$HOME/.ssh/config" ] && cp -n "$HOME/.ssh/config" "$HOME/.ssh/config.pre-bootstrap.bak" || true
  cp "$DOT_DIR/.ssh/config" "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
fi

echo "==> [6/7] Deploying IDE settings (VS Code & Jetski) and AGENTS.md..."
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

if [ -f "$AGENTS_DIR/AGENTS.md" ]; then
  mkdir -p "$HOME/cowork_workspace"
  cp "$AGENTS_DIR/AGENTS.md" "$HOME/cowork_workspace/AGENTS.md"
fi

echo "==> [7/7] Optional macOS Preferences & TouchID sudo..."
if [ "${APPLY_OSX_PREFS:-0}" = "1" ]; then
  "$SCRIPT_DIR/osx_prefs.sh"
else
  echo "Skipping osx_prefs.sh (run './scripts/osx_prefs.sh' or set APPLY_OSX_PREFS=1 to apply macOS defaults & TouchID sudo)."
fi

cat <<'NOTE'

✅ Bootstrap complete!

Next manual steps on a fresh gMac:
  1. Run `gcert` and `gnubby-ssh-keygen` to initialize corporate SSH/LOAS credentials.
  2. Run `gh auth login` and `gcloud auth login`.
  3. Run `./scripts/sync_repos.sh restore-all` to clone clean repos and unpack dirty/local bundles from Google Drive.
  4. Run `./scripts/osx_prefs.sh` to enable TouchID for `sudo` and macOS developer defaults.
  5. Open a new terminal window to enjoy zsh + Oh My Posh + modern CLI tools!
NOTE
