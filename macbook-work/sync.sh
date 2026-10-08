#!/usr/bin/env bash
# =============================================================================
# sync.sh — Copy current live config and repo manifest back into the repo
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT_DIR="$HERE/dotfiles"
IDE_DIR="$HERE/ide"

mkdir -p "$DOT_DIR/.config/oh-my-posh" "$IDE_DIR"

echo "==> [1/4] Syncing and sanitizing dotfiles from $HOME..."
if grep -q "macbook-work" "$HOME/.zshrc" 2>/dev/null; then
  cp "$HOME/.zshrc" "$DOT_DIR/.zshrc"
fi

[ -f "$HOME/.tmux.conf" ] && cp "$HOME/.tmux.conf" "$DOT_DIR/.tmux.conf"

if [ -f "$HOME/.config/oh-my-posh/atomic_renan.omp.json" ]; then
  cp "$HOME/.config/oh-my-posh/atomic_renan.omp.json" "$DOT_DIR/.config/oh-my-posh/atomic_renan.omp.json"
fi

if grep -q "gitconfig.local" "$HOME/.gitconfig" 2>/dev/null; then
  sed -E 's/^([[:space:]]*email[[:space:]]*=).*/\1 your-email@example.com/' \
    "$HOME/.gitconfig" > "$DOT_DIR/.gitconfig"
fi

echo "==> [2/4] Syncing IDE settings (VS Code / Jetski)..."
VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
JETSKI_SETTINGS="$HOME/Library/Application Support/Jetski/User/settings.json"

if [ -f "$VSCODE_SETTINGS" ]; then
  src_settings="$VSCODE_SETTINGS"
elif [ -f "$JETSKI_SETTINGS" ]; then
  src_settings="$JETSKI_SETTINGS"
else
  src_settings=""
fi

if [ -n "$src_settings" ] && command -v jq >/dev/null 2>&1; then
  jq --indent 4 'del(."cloudcode.project", ."geminicodeassist.project", ."http.systemCertificates")' \
    "$src_settings" > "$IDE_DIR/vscode-settings.json"
fi

echo "==> [3/4] Scanning repositories in ~/GitHub and ~/GitLab..."
"$HERE/sync_repos.sh" scan

echo "==> [4/4] Running Zero-Secrets safety check..."
FORBIDDEN_MATCHES=$(find "$HERE" -type f \( -name "id_rsa*" -o -name "id_ed25519*" -o -name "id_ecdsa*" -o -name "google_compute_engine*" -o -name ".netrc" -o -name "*oauth-token*" -o -name ".env" \) 2>/dev/null || true)
if [ -n "$FORBIDDEN_MATCHES" ]; then
  echo "❌ ERROR: Secret file(s) detected inside $HERE:"
  echo "$FORBIDDEN_MATCHES"
  exit 1
fi

echo "✅ Synced live config into the repo. Review with: git -C \"$HERE/..\" status && git -C \"$HERE/..\" diff"
