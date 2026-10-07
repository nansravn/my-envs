# Agent 2: New gMac Provisioner Prompt

Copy and paste the prompt below into Antigravity / Jetski on your **New gMac** (`/Users/renanvn`):

---

```markdown
You are **Agent 2 (Provisioner)** operating on my **New gMac** (`/Users/renanvn`).
I have cloned `https://github.com/nansravn/my-envs` into `~/GitHub/my-envs` and need you to provision this machine from the `macbook-work/` profile.

Please execute the following workflow step by step:

1. **Pre-Flight & Corporate Auth Check:**
   - Review `~/GitHub/my-envs/macbook-work/migration_status.md` and `~/GitHub/my-envs/macbook-work/inventory/repos_manifest.tsv`.
   - Check if Xcode Command Line Tools (`xcode-select -p`), corporate certificate (`gcertstatus` / `gcert`), and GitHub CLI (`gh auth status`) are active. Prompt me if any interactive login/Titan key touch is needed.

2. **Bootstrap Environment (`./bootstrap.sh`):**
   - Run `~/GitHub/my-envs/macbook-work/bootstrap.sh` (which executes `scripts/apply_target.sh`).
   - Verify that Homebrew is installed, all packages/casks/fonts/extensions in `Brewfile` are installed, `uv` and zsh plugins (`fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`) are present, and `dotfiles/` + `ide/vscode-settings.json` + `agents/AGENTS.md` are deployed.
   - Ask if I want to apply macOS productivity preferences and TouchID for `sudo` via `./scripts/osx_prefs.sh`.

3. **Restore Scattered Repositories (`./scripts/sync_repos.sh restore-all`):**
   - Run `./scripts/sync_repos.sh clone-clean` to clone all repositories with valid remotes into `~/GitHub` and `~/GitLab` (Note: `sso://` repos require `gcert` first).
   - Check if Google Drive (`~/My Drive (renanvn@google.com)/gmac-migration-backup`) has finished syncing; once available, run `./scripts/sync_repos.sh restore-dirty` to unpack local git bundles, dirty working tree overlays, non-git project folders, `~/GitHub/dev_env/.env`, and `~/cowork_workspace/skills`.

4. **Final Parity Verification:**
   - Verify CLI tools (`brew`, `git`, `gh`, `gcloud`, `uv`, `node`, `go`, `kubectl`, `oh-my-posh`, `fzf`, `zoxide`, `eza`, `bat`, `rg`, `fd`, `tmux`).
   - Update `~/GitHub/my-envs/macbook-work/migration_status.md` marking the New gMac provisioning as complete!
```
