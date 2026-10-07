# Agent 1: Old gMac Auditor & Exporter Prompt

Copy and paste the prompt below into Antigravity / Jetski on your **Old gMac** (`/Users/renanvn`):

---

```markdown
You are **Agent 1 (Auditor & Exporter)** operating on my **Old gMac** (`/Users/renanvn`).
We are migrating my work environment to a new gMac using the `macbook-work` profile inside `~/GitHub/my-envs` (`https://github.com/nansravn/my-envs`).

Please execute the following workflow step by step:

1. **Run Config & Inventory Audit (`./sync.sh`):**
   - Execute `~/GitHub/my-envs/macbook-work/sync.sh` (which runs `scripts/audit_source.sh`).
   - Verify that `Brewfile`, `dotfiles/`, `ide/`, `agents/AGENTS.md`, and `inventory/repos_manifest.tsv` are updated.

2. **Package Dirty / Local Repositories to Google Drive (`./scripts/sync_repos.sh pack-dirty`):**
   - Execute `~/GitHub/my-envs/macbook-work/scripts/sync_repos.sh pack-dirty`.
   - This creates git bundles, uncommitted diffs/stashes, and `.tar.gz` archives for all `dirty-remote`, `local-git` (`NO_REMOTE`), and `untracked-dir` (`NOT_A_GIT_REPO`) folders from `~/GitHub` and `~/GitLab`, saving them safely into `~/My Drive (renanvn@google.com)/gmac-migration-backup/` (along with `~/GitHub/dev_env/.env` and `~/cowork_workspace/skills`).
   - Also check the root of `~` for loose media files (e.g. `~/*.mp4`) and warn me or offer to move them into the Google Drive backup folder so they aren't left behind.

3. **Zero-Secrets Verification (Mandatory Gate):**
   - Inspect `git -C ~/GitHub/my-envs status` and `git -C ~/GitHub/my-envs diff`.
   - Ensure NO private keys (`id_*`, `google_compute_engine*`), `.netrc`, `.gitcookies`, OAuth tokens, or `.env` files are staged in the Git repository.

4. **Update Status & Push:**
   - Update `~/GitHub/my-envs/macbook-work/migration_status.md` marking the Old gMac export tasks as completed with today's timestamp and summary counts.
   - Commit the changes and push to `origin main` (after confirming with me).
```
