#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu (WSL2) machine to match this environment.
# Idempotent-ish: safe to re-run. Review before executing.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT="$HERE/dotfiles"

echo "==> Installing apt packages (needs sudo)"
sudo apt-get update -y
sudo apt-get install -y zsh fzf zoxide bat fd-find eza unzip git curl tmux ripgrep

echo "==> Installing Starship (user-space)"
mkdir -p "$HOME/.local/bin"
command -v starship >/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"

echo "==> Installing uv (user-space)"
command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh

echo "==> Installing gh CLI (user-space)"
if ! command -v gh >/dev/null; then
  VER=$(curl -sS https://api.github.com/repos/cli/cli/releases/latest | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')
  curl -sSL -o /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/v${VER}/gh_${VER}_linux_amd64.tar.gz"
  tar -xzf /tmp/gh.tar.gz -C /tmp
  cp "/tmp/gh_${VER}_linux_amd64/bin/gh" "$HOME/.local/bin/gh"
  rm -rf /tmp/gh.tar.gz "/tmp/gh_${VER}_linux_amd64"
fi

echo "==> Cloning zsh plugins"
mkdir -p "$HOME/.zsh"
clone() { [ -d "$HOME/.zsh/$2" ] || git clone --depth=1 "https://github.com/$1" "$HOME/.zsh/$2"; }
clone zsh-users/zsh-autosuggestions     zsh-autosuggestions
clone zsh-users/zsh-syntax-highlighting zsh-syntax-highlighting
clone Aloxaf/fzf-tab                     fzf-tab

echo "==> Backing up existing dotfiles and copying configs into place"
for f in .zshrc .bashrc .tmux.conf .gitconfig; do
  [ -f "$HOME/$f" ] && cp -n "$HOME/$f" "$HOME/$f.pre-bootstrap.bak" || true
  cp "$DOT/$f" "$HOME/$f"
done
mkdir -p "$HOME/.config"
cp "$DOT/.config/starship.toml" "$HOME/.config/starship.toml"

cat <<'NOTE'

==> Done with the Linux side.

Manual Windows-side steps (cannot be automated from a fresh WSL):
  1. Install a Nerd Font on Windows (e.g. JetBrainsMono Nerd Font) from
     https://www.nerdfonts.com/font-downloads and Install the .ttf files.
  2. Apply windows-terminal/settings.json to Windows Terminal, or just set
     the font face to "JetBrainsMono Nerd Font" in Settings -> profile -> Appearance.
  3. Run `gh auth login` to authenticate the GitHub CLI.

Open a new terminal to land in zsh + Starship.
NOTE
