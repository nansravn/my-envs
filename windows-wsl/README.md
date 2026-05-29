# windows-wsl

Configuration for my Windows laptop running **Ubuntu 26.04 (WSL2)** under
**Windows Terminal**.

## Stack

- **Shell:** zsh (bash auto-execs into it; see `dotfiles/.bashrc`)
- **Prompt:** [Starship](https://starship.rs) — git + Python aware (`dotfiles/.config/starship.toml`)
- **History/autocomplete:** fzf (Ctrl-R / Ctrl-T / Alt-C), zsh-autosuggestions, fzf-tab, zsh-syntax-highlighting
- **CLI tools:** eza, bat, fd, zoxide, ripgrep, tmux
- **Python:** uv
- **GitHub:** gh CLI
- **Font:** JetBrainsMono Nerd Font (installed on the Windows side; set in `windows-terminal/settings.json`)

## Layout

```
dotfiles/                 # mirrors $HOME
  .zshrc
  .bashrc
  .tmux.conf
  .gitconfig
  .config/starship.toml
windows-terminal/
  settings.json           # Windows Terminal config (font + default profile)
bootstrap.sh              # set up a fresh machine from these files
sync.sh                   # copy current live config back into this repo
```

## Bootstrap a fresh machine

```bash
./bootstrap.sh
```

Installs the apt packages, Starship, uv, gh, and the zsh plugins, then copies the
dotfiles into place. Review the script before running. The Nerd Font and Windows
Terminal `settings.json` must be applied on the Windows side manually (see script
notes).

## Sync local changes into the repo

```bash
./sync.sh && git -C "$(git rev-parse --show-toplevel)" status
```
