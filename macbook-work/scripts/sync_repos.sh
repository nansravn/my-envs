#!/usr/bin/env bash
# =============================================================================
# sync_repos.sh — Scattered Repository Scanner, Bundler & Restorer
# =============================================================================
# Handles all 4 categories of project directories in ~/GitHub and ~/GitLab:
#   1. clean          : Git repo with remote, 0 dirty files, 0 unpushed commits
#   2. dirty-remote   : Git repo with remote, but has uncommitted or unpushed work
#   3. local-git      : Git repo with NO remote configured
#   4. untracked-dir  : Project directory without a .git folder
#
# Usage:
#   ./scripts/sync_repos.sh scan           # Generate inventory/repos_manifest.tsv
#   ./scripts/sync_repos.sh pack-dirty     # Export bundles & tarballs to Google Drive
#   ./scripts/sync_repos.sh clone-clean    # Clone all remote-backed repos on New gMac
#   ./scripts/sync_repos.sh restore-dirty  # Unpack bundles & tarballs from Google Drive
#   ./scripts/sync_repos.sh restore-all    # Run clone-clean + restore-dirty
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$PROFILE_DIR/inventory/repos_manifest.tsv"

# Default Google Drive backup path on corporate gMac
DEFAULT_GDRIVE="$HOME/My Drive (renanvn@google.com)/gmac-migration-backup"
if [ ! -d "$(dirname "$DEFAULT_GDRIVE")" ] && [ -d "$HOME/My Drive" ]; then
  DEFAULT_GDRIVE="$HOME/My Drive/gmac-migration-backup"
fi
BACKUP_DIR="${GMAC_BACKUP_DIR:-$DEFAULT_GDRIVE}"

scan_repos() {
  mkdir -p "$(dirname "$MANIFEST")"
  printf "rel_path\tcategory\tremote_url\tbranch\tdirty_count\tunpushed_count\n" > "$MANIFEST"

  for base in GitHub GitLab; do
    [ -d "$HOME/$base" ] || continue
    for dir in "$HOME/$base"/*; do
      [ -d "$dir" ] || continue
      name="$(basename "$dir")"
      rel_path="$base/$name"

      # Skip my-envs itself from migration manifest
      if [ "$rel_path" = "GitHub/my-envs" ]; then
        continue
      fi

      if [ -d "$dir/.git" ]; then
        remote_url="$(git -C "$dir" remote get-url origin 2>/dev/null || echo "NONE")"
        branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")"
        dirty_count="$({ git -C "$dir" status --porcelain 2>/dev/null || true; } | wc -l | tr -d ' ')"
        if [ "$remote_url" != "NONE" ]; then
          unpushed_count="$({ git -C "$dir" log --branches --not --remotes --oneline 2>/dev/null || true; } | wc -l | tr -d ' ')"
          if [ "$dirty_count" = "0" ] && [ "$unpushed_count" = "0" ]; then
            category="clean"
          else
            category="dirty-remote"
          fi
        else
          unpushed_count="$({ git -C "$dir" log --oneline 2>/dev/null || true; } | wc -l | tr -d ' ')"
          category="local-git"
        fi
      else
        remote_url="NONE"
        branch="NONE"
        dirty_count="0"
        unpushed_count="0"
        category="untracked-dir"
      fi

      printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$rel_path" "$category" "$remote_url" "$branch" "$dirty_count" "$unpushed_count" >> "$MANIFEST"
    done
  done

  echo "✅ Repository manifest written to: $MANIFEST"
  awk -F'\t' 'NR>1 {count[$2]++} END {for (c in count) printf "   - %-15s: %d\n", c, count[c]}' "$MANIFEST" | sort
}

pack_dirty() {
  [ -f "$MANIFEST" ] || scan_repos
  echo "==> Backing up dirty/local repositories and workspace configs to:"
  echo "    $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR/bundles" "$BACKUP_DIR/overlays" "$BACKUP_DIR/untracked_dirs" "$BACKUP_DIR/extras"

  while IFS=$'\t' read -r rel_path category remote_url branch dirty_count unpushed_count; do
    [ "$rel_path" = "rel_path" ] && continue
    src_dir="$HOME/$rel_path"
    safe_name="${rel_path//\//__}"

    if [ ! -d "$src_dir" ]; then
      continue
    fi

    case "$category" in
      clean)
        # Check if it has a local .env (like GitHub/dev_env/.env)
        if [ -f "$src_dir/.env" ]; then
          echo "   [env]     Saving $rel_path/.env"
          cp "$src_dir/.env" "$BACKUP_DIR/extras/${safe_name}.env"
        fi
        ;;
      dirty-remote)
        echo "   [dirty-remote] Packing $rel_path (dirty=$dirty_count, unpushed=$unpushed_count)..."
        if [ "$unpushed_count" -gt 0 ] && git -C "$src_dir" rev-parse HEAD >/dev/null 2>&1; then
          git -C "$src_dir" bundle create "$BACKUP_DIR/bundles/${safe_name}.bundle" --all >/dev/null 2>&1 || true
        fi
        if [ "$dirty_count" -gt 0 ]; then
          git -C "$src_dir" ls-files -z --modified --others --exclude-standard | \
            tar -czf "$BACKUP_DIR/overlays/${safe_name}.tar.gz" --null -C "$src_dir" -T - 2>/dev/null || true
        fi
        ;;
      local-git)
        echo "   [local-git]    Packing $rel_path (dirty=$dirty_count, commits=$unpushed_count)..."
        if git -C "$src_dir" rev-parse HEAD >/dev/null 2>&1; then
          git -C "$src_dir" bundle create "$BACKUP_DIR/bundles/${safe_name}.bundle" --all >/dev/null 2>&1 || true
        fi
        if [ "$dirty_count" -gt 0 ]; then
          git -C "$src_dir" ls-files -z --modified --others --exclude-standard | \
            tar -czf "$BACKUP_DIR/overlays/${safe_name}.tar.gz" --null -C "$src_dir" -T - 2>/dev/null || true
        fi
        ;;
      untracked-dir)
        # Skip google-cloud-sdk inside ~/GitLab since gcloud-cli cask installs it cleanly
        if [ "$rel_path" = "GitLab/google-cloud-sdk" ]; then
          echo "   [skip]         Skipping GitLab/google-cloud-sdk (managed via Homebrew cask gcloud-cli)"
          continue
        fi
        echo "   [archive]      Packing non-git folder $rel_path..."
        tar -czf "$BACKUP_DIR/untracked_dirs/${safe_name}.tar.gz" \
          --exclude='node_modules' \
          --exclude='.venv' \
          --exclude='venv' \
          --exclude='__pycache__' \
          --exclude='.terraform' \
          --exclude='.next' \
          -C "$HOME" "$rel_path" 2>/dev/null || true
        ;;
    esac
  done < "$MANIFEST"

  # Also pack cowork_workspace skills & custom-ca.pem if present
  if [ -d "$HOME/cowork_workspace/skills" ]; then
    echo "   [extra]   Packing ~/cowork_workspace/skills..."
    tar -czf "$BACKUP_DIR/extras/cowork_skills.tar.gz" -C "$HOME" "cowork_workspace/skills" 2>/dev/null || true
  fi
  if [ -f "$HOME/custom-ca.pem" ]; then
    cp "$HOME/custom-ca.pem" "$BACKUP_DIR/extras/custom-ca.pem"
  fi
  if [ -d "$HOME/bin/autogen" ]; then
    tar -czf "$BACKUP_DIR/extras/bin_autogen.tar.gz" -C "$HOME" "bin/autogen" 2>/dev/null || true
  fi

  echo "✅ All dirty/local projects and extras exported to: $BACKUP_DIR"
}

clone_clean() {
  if [ ! -f "$MANIFEST" ]; then
    echo "❌ Manifest not found at $MANIFEST"
    exit 1
  fi

  echo "==> Cloning remote-backed repositories into ~/GitHub and ~/GitLab..."
  while IFS=$'\t' read -r rel_path category remote_url branch dirty_count unpushed_count; do
    [ "$rel_path" = "rel_path" ] && continue
    [ "$remote_url" = "NONE" ] && continue

    target_dir="$HOME/$rel_path"
    mkdir -p "$(dirname "$target_dir")"

    if [ -d "$target_dir/.git" ]; then
      echo "   [exists]  $rel_path already cloned."
    else
      echo "   [clone]   $rel_path <- $remote_url"
      git clone "$remote_url" "$target_dir" || echo "   ⚠️ Warning: Failed to clone $rel_path (check gcert / SSH / GitLab auth)."
    fi
  done < "$MANIFEST"
}

restore_dirty() {
  if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory not found at: $BACKUP_DIR"
    echo "   Ensure Google Drive has synced or set GMAC_BACKUP_DIR=/path/to/backup."
    exit 1
  fi

  echo "==> Restoring local git repos, dirty overlays, and non-git folders from $BACKUP_DIR..."

  # 1. Restore local-git bundles first
  while IFS=$'\t' read -r rel_path category remote_url branch dirty_count unpushed_count; do
    [ "$rel_path" = "rel_path" ] && continue
    safe_name="${rel_path//\//__}"
    target_dir="$HOME/$rel_path"

    if [ "$category" = "local-git" ]; then
      mkdir -p "$target_dir"
      if [ -f "$BACKUP_DIR/bundles/${safe_name}.bundle" ] && [ ! -d "$target_dir/.git" ]; then
        echo "   [bundle]  Restoring local git repo $rel_path..."
        rm -rf "$target_dir"
        git clone "$BACKUP_DIR/bundles/${safe_name}.bundle" "$target_dir" 2>/dev/null || mkdir -p "$target_dir"
      fi
    elif [ "$category" = "dirty-remote" ] && [ -f "$BACKUP_DIR/bundles/${safe_name}.bundle" ] && [ -d "$target_dir/.git" ]; then
      echo "   [bundle]  Fetching unpushed commits for $rel_path..."
      git -C "$target_dir" fetch "$BACKUP_DIR/bundles/${safe_name}.bundle" "$branch" 2>/dev/null && \
        git -C "$target_dir" checkout "$branch" 2>/dev/null && \
        git -C "$target_dir" merge --ff-only FETCH_HEAD 2>/dev/null || true
    fi

    # Unpack working tree overlay for dirty-remote and local-git
    if [ "$category" = "dirty-remote" ] || [ "$category" = "local-git" ]; then
      if [ -f "$BACKUP_DIR/overlays/${safe_name}.tar.gz" ]; then
        echo "   [overlay] Restoring modified/untracked files for $rel_path..."
        mkdir -p "$target_dir"
        tar -xzf "$BACKUP_DIR/overlays/${safe_name}.tar.gz" -C "$target_dir"
      fi
    fi

    # Unpack untracked-dir
    if [ "$category" = "untracked-dir" ] && [ -f "$BACKUP_DIR/untracked_dirs/${safe_name}.tar.gz" ]; then
      echo "   [folder]  Restoring non-git folder $rel_path..."
      tar -xzf "$BACKUP_DIR/untracked_dirs/${safe_name}.tar.gz" -C "$HOME"
    fi

    # Restore .env if saved
    if [ -f "$BACKUP_DIR/extras/${safe_name}.env" ] && [ -d "$target_dir" ]; then
      echo "   [env]     Restoring $rel_path/.env"
      cp "$BACKUP_DIR/extras/${safe_name}.env" "$target_dir/.env"
    fi
  done < "$MANIFEST"

  # 2. Restore extras
  if [ -f "$BACKUP_DIR/extras/cowork_skills.tar.gz" ]; then
    echo "   [extra]   Restoring ~/cowork_workspace/skills..."
    tar -xzf "$BACKUP_DIR/extras/cowork_skills.tar.gz" -C "$HOME"
  fi
  if [ -f "$BACKUP_DIR/extras/custom-ca.pem" ]; then
    cp "$BACKUP_DIR/extras/custom-ca.pem" "$HOME/custom-ca.pem"
  fi
  if [ -f "$BACKUP_DIR/extras/bin_autogen.tar.gz" ]; then
    tar -xzf "$BACKUP_DIR/extras/bin_autogen.tar.gz" -C "$HOME"
  fi

  echo "✅ Restore from $BACKUP_DIR complete!"
}

cmd="${1:-scan}"
case "$cmd" in
  scan)          scan_repos ;;
  pack-dirty)    pack_dirty ;;
  clone-clean)   clone_clean ;;
  restore-dirty) restore_dirty ;;
  restore-all)   clone_clean && restore_dirty ;;
  *)
    echo "Usage: $0 {scan|pack-dirty|clone-clean|restore-dirty|restore-all}"
    exit 1
    ;;
esac
