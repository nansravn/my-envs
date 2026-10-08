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
#   ./sync_repos.sh scan           # Generate repos_manifest.tsv
#   ./sync_repos.sh pack-dirty     # Export bundles & tarballs to Google Drive
#   ./sync_repos.sh clone-clean    # Clone all remote-backed repos on New gMac
#   ./sync_repos.sh restore-dirty  # Unpack bundles & tarballs from Google Drive
#   ./sync_repos.sh restore-all    # Run clone-clean + restore-dirty
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$HERE/repos_manifest.tsv"

# Default Google Drive backup path on corporate gMac
DEFAULT_GDRIVE="$HOME/My Drive (renanvn@google.com)/gmac-migration-backup"
if [ ! -d "$(dirname "$DEFAULT_GDRIVE")" ] && [ -d "$HOME/My Drive" ]; then
  DEFAULT_GDRIVE="$HOME/My Drive/gmac-migration-backup"
fi
BACKUP_DIR="${GMAC_BACKUP_DIR:-$DEFAULT_GDRIVE}"

scan_repos() {
  printf "rel_path\tcategory\tremote_url\tbranch\tdirty_count\tunpushed_count\n" > "$MANIFEST"

  for base in GitHub GitLab; do
    [ -d "$HOME/$base" ] || continue
    for dir in "$HOME/$base"/*; do
      [ -d "$dir" ] || continue
      name="$(basename "$dir")"
      rel_path="$base/$name"

      # Skip self, Homebrew-managed SDKs, and legacy theme folder already in dotfiles/
      case "$rel_path" in
        GitHub/my-envs|GitLab/google-cloud-sdk|GitLab/terminal-configuration)
          continue
          ;;
      esac

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

pack_dirty_overlay() {
  local src_dir="$1"
  local archive_path="$2"
  local include_git_dirty="${3:-1}"
  local existing_list
  existing_list="$(mktemp)"

  while IFS= read -r -d '' rel_file; do
    if [ -n "$rel_file" ] && [ -e "$src_dir/$rel_file" ]; then
      printf "%s\0" "$rel_file" >> "$existing_list"
    fi
  done < <({
    if [ "$include_git_dirty" = "1" ]; then
      git -C "$src_dir" diff --name-only -z HEAD 2>/dev/null || \
        git -C "$src_dir" diff --name-only --cached -z 2>/dev/null || true
      git -C "$src_dir" ls-files -z --modified --others --exclude-standard 2>/dev/null || true
    fi
    (
      cd "$src_dir" && find . \
        \( -name '.git' -o -name 'node_modules' -o -name '.venv' -o -name 'venv' -o -name '__pycache__' -o -name '.terraform' -o -name '.next' \) -prune \
        -o -type f \( -name '.env' -o -name '.env.*' \) ! -name '*.example' ! -name '*-example' -print0 2>/dev/null
    )
  } | while IFS= read -r -d '' item; do
    printf "%s\0" "${item#./}"
  done | sort -zu)

  if [ -s "$existing_list" ]; then
    tar -czf "$archive_path" --null -C "$src_dir" -T "$existing_list" 2>/dev/null || true
  fi
  rm -f "$existing_list"
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

    [ -d "$src_dir" ] || continue

    case "$category" in
      clean)
        # Pack any gitignored .env / .env.* files (including nested subdirectories)
        pack_dirty_overlay "$src_dir" "$BACKUP_DIR/overlays/${safe_name}.tar.gz" 0
        if [ -f "$BACKUP_DIR/overlays/${safe_name}.tar.gz" ]; then
          echo "   [env-overlay]  Saved .env* files for $rel_path"
        fi
        ;;
      dirty-remote)
        echo "   [dirty-remote] Packing $rel_path (dirty=$dirty_count, unpushed=$unpushed_count)..."
        if [ "$unpushed_count" -gt 0 ] && git -C "$src_dir" rev-parse HEAD >/dev/null 2>&1; then
          git -C "$src_dir" bundle create "$BACKUP_DIR/bundles/${safe_name}.bundle" --all >/dev/null 2>&1 || true
        fi
        pack_dirty_overlay "$src_dir" "$BACKUP_DIR/overlays/${safe_name}.tar.gz" 1
        ;;
      local-git)
        echo "   [local-git]    Packing $rel_path (dirty=$dirty_count, commits=$unpushed_count)..."
        if git -C "$src_dir" rev-parse HEAD >/dev/null 2>&1; then
          git -C "$src_dir" bundle create "$BACKUP_DIR/bundles/${safe_name}.bundle" --all >/dev/null 2>&1 || true
        fi
        pack_dirty_overlay "$src_dir" "$BACKUP_DIR/overlays/${safe_name}.tar.gz" 1
        ;;
      untracked-dir)
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

  if [ -d "$HOME/cowork_workspace/skills" ]; then
    echo "   [extra]        Packing ~/cowork_workspace/skills..."
    tar -czf "$BACKUP_DIR/extras/cowork_skills.tar.gz" -C "$HOME" "cowork_workspace/skills" 2>/dev/null || true
  fi
  if [ -f "$HOME/cowork_workspace/AGENTS.md" ]; then
    cp "$HOME/cowork_workspace/AGENTS.md" "$BACKUP_DIR/extras/cowork_AGENTS.md"
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
      if [ ! -d "$target_dir/.git" ]; then
        echo "   [init]    Initializing 0-commit local git repo $rel_path (${branch:-main})..."
        git -C "$target_dir" init -b "${branch:-main}" >/dev/null 2>&1 || git -C "$target_dir" init >/dev/null 2>&1
      fi
    elif [ "$category" = "dirty-remote" ] && [ -d "$target_dir/.git" ]; then
      if [ -f "$BACKUP_DIR/bundles/${safe_name}.bundle" ] && [ "$branch" != "NONE" ] && [ "$branch" != "HEAD" ]; then
        echo "   [bundle]  Fetching unpushed commits for $rel_path ($branch)..."
        if git -C "$target_dir" fetch "$BACKUP_DIR/bundles/${safe_name}.bundle" "$branch" >/dev/null 2>&1; then
          if git -C "$target_dir" checkout "$branch" >/dev/null 2>&1; then
            git -C "$target_dir" merge --ff-only FETCH_HEAD >/dev/null 2>&1 || true
          else
            git -C "$target_dir" checkout -B "$branch" FETCH_HEAD >/dev/null 2>&1 || true
          fi
        fi
      elif [ "$branch" != "NONE" ] && [ "$branch" != "HEAD" ]; then
        git -C "$target_dir" checkout "$branch" >/dev/null 2>&1 || true
      fi
    elif [ "$category" = "clean" ] && [ -d "$target_dir/.git" ] && [ "$branch" != "NONE" ] && [ "$branch" != "HEAD" ]; then
      git -C "$target_dir" checkout "$branch" >/dev/null 2>&1 || true
    fi

    if [ "$category" = "clean" ] || [ "$category" = "dirty-remote" ] || [ "$category" = "local-git" ]; then
      if [ -f "$BACKUP_DIR/overlays/${safe_name}.tar.gz" ] && [ -d "$target_dir" ]; then
        echo "   [overlay] Restoring modified/untracked/.env* files for $rel_path..."
        tar -xzf "$BACKUP_DIR/overlays/${safe_name}.tar.gz" -C "$target_dir"
      fi
    fi

    if [ "$category" = "untracked-dir" ] && [ -f "$BACKUP_DIR/untracked_dirs/${safe_name}.tar.gz" ]; then
      echo "   [folder]  Restoring non-git folder $rel_path..."
      tar -xzf "$BACKUP_DIR/untracked_dirs/${safe_name}.tar.gz" -C "$HOME"
    fi

    if [ -f "$BACKUP_DIR/extras/${safe_name}.env" ] && [ -d "$target_dir" ] && [ ! -f "$target_dir/.env" ]; then
      echo "   [env]     Restoring $rel_path/.env"
      cp "$BACKUP_DIR/extras/${safe_name}.env" "$target_dir/.env"
    fi
  done < "$MANIFEST"

  if [ -f "$BACKUP_DIR/extras/cowork_skills.tar.gz" ]; then
    echo "   [extra]   Restoring ~/cowork_workspace/skills..."
    tar -xzf "$BACKUP_DIR/extras/cowork_skills.tar.gz" -C "$HOME"
  fi
  if [ -f "$BACKUP_DIR/extras/cowork_AGENTS.md" ]; then
    mkdir -p "$HOME/cowork_workspace"
    cp "$BACKUP_DIR/extras/cowork_AGENTS.md" "$HOME/cowork_workspace/AGENTS.md"
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
