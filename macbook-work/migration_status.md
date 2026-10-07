# 📋 gMac Migration Status Tracker (`macbook-work`)

Living checklist shared between **Agent 1 (Old gMac)** and **Agent 2 (New gMac)**.

## 🖥 Phase 1: Old gMac (Source System — `/Users/renanvn`)

- [x] Audit local environment (`$HOME`, dotfiles, Homebrew, `/Applications`, IDEs, `cowork_workspace`)
- [x] Initialize `macbook-work/` profile in `nansravn/my-envs`
- [x] Run `./sync.sh` (`scripts/audit_source.sh`) to export live configs & `inventory/repos_manifest.tsv`
- [ ] Run `./scripts/sync_repos.sh pack-dirty` to export dirty/local repos & `.env` to Google Drive (`~/My Drive (renanvn@google.com)/gmac-migration-backup`)
- [ ] Move or archive loose `~/*.mp4` files from `$HOME` root
- [ ] Verify zero secrets in `git status` / `git diff` and push `my-envs` to GitHub

### Snapshot Summary (Old gMac)
| Category | Count | Details |
| :--- | :---: | :--- |
| **Homebrew Formulae** | 23 | 15 existing + 8 modern CLI kit (`fzf`, `zoxide`, `eza`, `bat`, `fd`, `ripgrep`, `tmux`, `zsh-syntax-highlighting`) |
| **Homebrew Casks** | 6 | `claude-code`, `dotnet-sdk`, `dotnet-sdk@8`, `dotnet-sdk@9`, `gcloud-cli`, `font-meslo-lg-nerd-font` |
| **VS Code Extensions** | 24 | Exported in `Brewfile` and `ide/vscode-extensions.txt` |
| **Clean Git Repos** | 6 | Auto-cloned via `sync_repos.sh clone-clean` |
| **Dirty / Unpushed Git Repos** | 18 | Cloned from remote + dirty overlay tarballs in Google Drive backup |
| **Local Git Repos (`NO_REMOTE`)** | 7 | Exported as `.bundle` + working tree tarballs in Google Drive backup |
| **Non-Git Folders (`NOT_A_GIT_REPO`)** | 27 | Exported as `.tar.gz` archives in Google Drive backup |

---

## 🚀 Phase 2: New gMac (Target System — `/Users/renanvn`)

- [ ] Complete initial macOS login, CorpSSO, and run `gcert`
- [ ] Generate FIDO2 SSH key (`gnubby-ssh-keygen`) and authenticate GitHub (`gh auth login`) & GCP (`gcloud auth login`)
- [ ] Clone `https://github.com/nansravn/my-envs.git` into `~/GitHub/my-envs`
- [ ] Run `./bootstrap.sh` (`scripts/apply_target.sh`) to install Homebrew, `Brewfile`, dotfiles, IDE settings, and `AGENTS.md`
- [ ] Run `./scripts/osx_prefs.sh` to configure macOS defaults and TouchID for `sudo` (`/etc/pam.d/sudo_local`)
- [ ] Run `./scripts/sync_repos.sh clone-clean` to clone all remote-backed repositories
- [ ] Wait for Google Drive (`~/My Drive (renanvn@google.com)/gmac-migration-backup`) sync and run `./scripts/sync_repos.sh restore-dirty`
- [ ] Verify terminal prompt (`oh-my-posh`), aliases (`oi`, `tchau`, `ll`, `z`), and IDEs (VS Code, Antigravity, Jetski, Cowork Agent)
