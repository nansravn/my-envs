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
# Scrub the personal email to a placeholder so it never lands in the repo
sed -E 's/^([[:space:]]*email[[:space:]]*=).*/\1 your-email@example.com/' \
    "$HOME/.gitconfig" > "$DOT/.gitconfig"
cp "$HOME/.config/starship.toml" "$DOT/.config/starship.toml"
[ -f "$WT_SRC" ] && cp "$WT_SRC" "$HERE/windows-terminal/settings.json"

echo "Synced live config into the repo. Review with: git status && git diff"
