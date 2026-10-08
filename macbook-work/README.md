# macbook-work

Configuration and migration tooling for my Google corporate MacBook (**gMac**).

## Stack

- **Shell:** zsh + Oh My Zsh (`git` plugin)
- **Prompt:** [Oh My Posh](https://ohmyposh.dev) (`dotfiles/.config/oh-my-posh/atomic_renan.omp.json`)
- **History & autocomplete:** `fzf` (Ctrl-R / Ctrl-T / Alt-C), `zsh-autosuggestions`, `fzf-tab`, `zsh-syntax-highlighting`
- **Modern CLI kit (parity with `windows-wsl`):** `eza`, `bat`, `fd`, `zoxide`, `ripgrep`, `tmux`, `jq`, `tree`, `typst`, `ffmpeg`, `portaudio`
- **Cloud, AI & runtimes:** `gcloud-cli`, `gh`, `terraform`, `gemini-cli`, `claude-code`, `uv`, `pdm`, `node`, `go`, `dotnet-sdk`, `kubernetes-cli`, `minikube`, `skaffold`
- **Corporate gMac integrations:** `/usr/local/git/git-google/bin`, `gcert`, `jetski` / `agy`, `duboc/dev_env` aliases (`oi`, `reoi`, `tchau`, `devbackup`, `adeus`, `devport`, `devcode`), TouchID `sudo_local`
- **Font:** `MesloLGM Nerd Font` (`font-meslo-lg-nerd-font`)

## Layout

```text
macbook-work/
├── Brewfile                  # Homebrew taps, formulae, casks, fonts & VS Code extensions
├── bootstrap.sh              # Provision a fresh gMac (--osx-prefs for macOS defaults & TouchID sudo)
├── sync.sh                   # Copy live dotfiles, IDE settings & repo manifest back into this repo
├── sync_repos.sh             # Scan, bundle (to Google Drive) & restore ~/GitHub and ~/GitLab repos
├── repos_manifest.tsv        # Inventory of ~/GitHub and ~/GitLab repositories
├── dotfiles/                 # Mirrors $HOME (sanitized copies, zero secrets)
│   ├── .zshrc
│   ├── .gitconfig
│   ├── .tmux.conf
│   └── .config/oh-my-posh/atomic_renan.omp.json
└── ide/
    └── vscode-settings.json  # Shared user settings for VS Code, Jetski & Antigravity
```

## Bootstrap a fresh work MacBook

```bash
# 1. Authenticate corporate & GitHub credentials first
gcert
gnubby-ssh-keygen
gh auth login

# 2. Provision Homebrew, packages, zsh plugins, dotfiles & IDE settings
./bootstrap.sh --osx-prefs

# 3. Clone remote repos and restore local/dirty bundles from Google Drive
./sync_repos.sh restore-all
```

## Sync local changes into the repo

```bash
# Export live dotfiles, IDE settings, and updated repos_manifest.tsv
./sync.sh && git -C "$(git rev-parse --show-toplevel)" status

# Optional: package dirty/local repos & .env files to corporate Google Drive
./sync_repos.sh pack-dirty
```

## GUI Applications Reference (Managed Software Center / Manual Install)

CLI packages, fonts, and IDE extensions are installed automatically via `Brewfile`. For GUI applications on a new work MacBook, install as needed from **Managed Software Center (MSC)** or vendor downloads:

| Category | Applications |
| :--- | :--- |
| **Terminal & IDEs** | iTerm2, Visual Studio Code, Jetski, Antigravity, Cowork Agent |
| **Productivity & Notes** | Obsidian, Rectangle Pro, Asana, Miro, Slack, Microsoft Teams |
| **Hardware & Peripherals** | DisplayLink Manager, Elgato Stream Deck, Elgato Control Center, Logi Options+ |
| **Media & Recording** | Camtasia, Audacity, ScreenBrush, VLC |
