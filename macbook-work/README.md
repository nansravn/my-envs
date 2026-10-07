# macbook-work — Google Corporate MacBook (gMac) Environment & Migration Framework

Configuration and pair-agent migration framework for my Google corporate MacBook (**gMac**).
Combines the `my-envs` convention (`dotfiles/`, `bootstrap.sh`, `sync.sh`) with an automated **gMac Migration & Synchronization Framework** (`scripts/`, `inventory/`, and pair-agent prompts).

---

## 🧰 Stack

- **Shell:** zsh + Oh My Zsh (`git` plugin)
- **Prompt:** [Oh My Posh](https://ohmyposh.dev) with custom theme (`dotfiles/.config/oh-my-posh/atomic_renan.omp.json`)
- **History & Autocomplete:** `fzf` (Ctrl-R / Ctrl-T / Alt-C), `zsh-autosuggestions`, `fzf-tab`, `zsh-syntax-highlighting`
- **Modern CLI Kit (parity with `windows-wsl`):** `eza`, `bat`, `fd`, `zoxide`, `ripgrep`, `tmux`, `jq`, `tree`, `typst`, `ffmpeg`
- **Cloud, AI & Runtimes:** `gcloud-cli`, `gh`, `gemini-cli`, `claude-code`, `uv`, `pdm`, `python@3.10`, `node`, `go`, `dotnet-sdk` (8/9), `kubernetes-cli`, `minikube`, `skaffold`
- **Corporate gMac Integrations:** `/usr/local/git/git-google/bin`, `gcert`, `jetski` / `agy`, `duboc/dev_env` workflow aliases (`oi`, `reoi`, `tchau`, `devbackup`, `adeus`, `devport`, `devcode`), TouchID `sudo_local`
- **Font:** `MesloLGM Nerd Font` (`font-meslo-lg-nerd-font`)

---

## 🏗 Architecture (gMac Migration & Synchronization Framework)

```text
       ┌────────────────────────┐                    ┌────────────────────────┐
       │       OLD gMac         │                    │        NEW gMac        │
       │    (Source System)     │                    │    (Target System)     │
       ├────────────────────────┤                    ├────────────────────────┤
       │   Agent 1: Auditor     │                    │  Agent 2: Provisioner  │
       │                        │                    │   (Antigravity/Jetski) │
       │ • Runs ./sync.sh       │                    │ • Runs ./bootstrap.sh  │
       │   (audit_source.sh)    │                    │   (apply_target.sh)    │
       │ • Exports Brewfile     │                    │ • Installs Homebrew    │
       │ • Sanitizes dotfiles   │                    │ • Installs Brewfile    │
       │ • Scans ~/GitHub &     │                    │ • Deploys dotfiles/IDE │
       │   ~/GitLab (63 dirs)   │                    │ • Clones clean repos   │
       │ • Packs dirty/local    │                    │ • Unpacks dirty bundles│
       └───────────┬────────────┘                    └───────────▲────────────┘
                   │                                             │
                   │      1. Configs & Manifests (No Secrets)    │
                   ├───────────► github.com/nansravn/my-envs ────┤
                   │                                             │
                   │      2. Dirty Bundles, .tar.gz & .env       │
                   └───────────► Corporate Google Drive ─────────┘
                     (~/My Drive (renanvn@google.com)/gmac-migration-backup)
```

---

## 📂 Layout

```text
macbook-work/
├── README.md                    # This guide
├── AGENT_OLD_PROMPT.md          # Prompt to launch Agent 1 on the Old gMac
├── AGENT_NEW_PROMPT.md          # Prompt to launch Agent 2 on the New gMac
├── migration_status.md          # Living checklist shared between Old & New gMac
├── Brewfile                     # Homebrew taps, formulae, casks, fonts & VS Code extensions
├── bootstrap.sh                 # Entrypoint to provision a fresh gMac (calls scripts/apply_target.sh)
├── sync.sh                      # Entrypoint to sync live configs to repo (calls scripts/audit_source.sh)
├── dotfiles/                    # Mirrors $HOME (sanitized copies, zero secrets)
│   ├── .zshrc
│   ├── .profile
│   ├── .gitconfig
│   ├── .tmux.conf
│   ├── .ssh/config
│   └── .config/oh-my-posh/atomic_renan.omp.json
├── ide/
│   ├── vscode-settings.json     # Shared settings for VS Code & Jetski/Antigravity
│   └── vscode-extensions.txt    # Installed VS Code extension IDs
├── agents/
│   └── AGENTS.md                # Personal communication & agent guidelines (from cowork_workspace)
├── inventory/
│   ├── repos_manifest.tsv       # Full inventory of ~/GitHub and ~/GitLab repositories
│   ├── applications_list.txt    # Snapshot of /Applications and ~/Applications
│   └── system_info.txt          # Snapshot of system versions & user-space tools
└── scripts/
    ├── audit_source.sh          # Automated inventory, secret-scrubbing & export for Old gMac
    ├── apply_target.sh          # Automated provisioning & installation for New gMac
    ├── sync_repos.sh            # Scanner, bundler (Google Drive) & cloner for scattered repos
    └── osx_prefs.sh             # macOS defaults & TouchID sudo_local setup
```

---

## 🚀 Step-by-Step Migration Workflow

### Step 1: On the Old gMac (Source Machine)
1. Clone `my-envs` (if not already present):
   ```bash
   git clone https://github.com/nansravn/my-envs.git ~/GitHub/my-envs
   cd ~/GitHub/my-envs/macbook-work
   ```
2. Run the audit and sync live configs into the repository:
   ```bash
   ./sync.sh
   ```
3. Package all dirty repositories, local-only Git repositories (`NO_REMOTE`), and non-Git project folders (`NOT_A_GIT_REPO`) into your corporate Google Drive backup folder:
   ```bash
   ./scripts/sync_repos.sh pack-dirty
   ```
   *(Or paste [`AGENT_OLD_PROMPT.md`](./AGENT_OLD_PROMPT.md) into Antigravity/Jetski on the Old gMac to execute and verify everything automatically).*
4. Review changes, commit, and push to GitHub:
   ```bash
   git status && git diff
   git add .
   git commit -m "feat(macbook-work): sync gMac environment and migration inventory"
   git push origin main
   ```

### Step 2: On the New gMac (Target Machine)
1. Authenticate corporate & GitHub credentials:
   ```bash
   gcert
   gnubby-ssh-keygen   # if setting up FIDO2 SSH keys
   gh auth login
   ```
2. Clone `my-envs`:
   ```bash
   mkdir -p ~/GitHub
   git clone https://github.com/nansravn/my-envs.git ~/GitHub/my-envs
   cd ~/GitHub/my-envs/macbook-work
   ```
3. Open Antigravity/Jetski on the New gMac and paste [`AGENT_NEW_PROMPT.md`](./AGENT_NEW_PROMPT.md), **or** run manually:
   ```bash
   # 1. Provision Homebrew, packages, dotfiles, IDE settings, and macOS prefs:
   ./bootstrap.sh

   # 2. Clone all clean/remote repos and restore bundles from Google Drive:
   ./scripts/sync_repos.sh restore-all
   ```

---

## 🔄 Routine Usage (Post-Migration)

After changing any dotfile, Homebrew package, or IDE setting locally on your work MacBook:
```bash
cd ~/GitHub/my-envs/macbook-work
./sync.sh && git -C "$(git rev-parse --show-toplevel)" status
```
