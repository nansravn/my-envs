#!/usr/bin/env bash
# Copy the current live config from this machine back into the repo.
# Run after changing any dotfile, then commit.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT="$HERE/dotfiles"
WT_SRC="/mnt/c/Users/vnova/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"

cp "$HOME/.zshrc"                 "$DOT/.zshrc"
cp "$HOME/.bashrc"                "$DOT/.bashrc"
cp "$HOME/.tmux.conf"             "$DOT/.tmux.conf"
cp "$HOME/.gitconfig"             "$DOT/.gitconfig"
cp "$HOME/.config/starship.toml" "$DOT/.config/starship.toml"
[ -f "$WT_SRC" ] && cp "$WT_SRC" "$HERE/windows-terminal/settings.json"

echo "Synced live config into the repo. Review with: git status && git diff"
