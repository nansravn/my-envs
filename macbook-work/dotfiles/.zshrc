# ~/.zshrc — macbook-work (Google gMac: Oh My Zsh + Oh My Posh + Modern CLI Kit)
# Managed via https://github.com/nansravn/my-envs (macbook-work profile)

# ---------------------------------------------------------------------------
# 1. PATH & Corporate gMac Binary Priority
# ---------------------------------------------------------------------------
export PATH="/usr/local/git/git-google/bin:/usr/local/git/current/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Applications/iTerm.app/Contents/Resources/utilities:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$HOME/.jetski/jetski/bin:$HOME/bin:$PATH"

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ---------------------------------------------------------------------------
# 2. Oh My Zsh Base
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# ---------------------------------------------------------------------------
# 3. History & Sensible Shell Behaviour (Parity with windows-wsl)
# ---------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # share history live between open shells
setopt INC_APPEND_HISTORY     # write commands as they are entered
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicate of a repeated command
setopt HIST_IGNORE_SPACE      # a leading space hides a command from history
setopt HIST_REDUCE_BLANKS     # trim superfluous whitespace
setopt HIST_VERIFY            # show !! expansion before running it
setopt EXTENDED_HISTORY       # record timestamps

setopt AUTO_CD                # type a dir name to cd into it
setopt AUTO_PUSHD             # cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS   # allow # comments at the prompt
setopt NO_BEEP

# ---------------------------------------------------------------------------
# 4. Completion & Zsh Plugins (fzf-tab, autosuggestions, syntax-highlighting)
# ---------------------------------------------------------------------------
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# fzf-tab (if installed in ~/.zsh/fzf-tab)
[ -f "$HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh" ] && source "$HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh"

# zsh-autosuggestions (Homebrew or ~/.zsh fallback)
if [ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# zsh-syntax-highlighting (Keep last among completion/syntax plugins)
if [ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

bindkey '^[[C' forward-char

# ---------------------------------------------------------------------------
# 5. fzf & zoxide Integration
# ---------------------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh 2>/dev/null) || true
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ---------------------------------------------------------------------------
# 6. Modern CLI Replacements & Shortcuts (Parity with windows-wsl)
# ---------------------------------------------------------------------------
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias less='bat'
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --git --group-directories-first'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
fi

alias grep='grep --color=auto'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate --all'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gco='git checkout'

# Python / uv shortcuts
alias venv='uv venv'
alias py='python3'

# ---------------------------------------------------------------------------
# 7. Work / gMac Specific Aliases & Certificates
# ---------------------------------------------------------------------------
[ -x "$HOME/bin/autogen/autogen" ] && alias autogen="$HOME/bin/autogen/autogen"
[ -x "/usr/local/bin/jetski" ] && alias jetski="/usr/local/bin/jetski"

# Custom CA certificate for Node.js (properly expanded $HOME)
if [ -f "$HOME/custom-ca.pem" ]; then
  export NODE_EXTRA_CA_CERTS="$HOME/custom-ca.pem"
fi

# === dev-env (oi) ===
alias oi="$HOME/GitHub/dev_env/oi.sh"
alias reoi="$HOME/GitHub/dev_env/oi.sh --reconnect"
alias tchau="$HOME/GitHub/dev_env/tchau.sh"
alias devbackup="$HOME/GitHub/dev_env/backup.sh"
alias adeus="$HOME/GitHub/dev_env/adeus.sh"
alias devport="$HOME/GitHub/dev_env/port.sh"
alias devcode="$HOME/GitHub/dev_env/code.sh"
# === dev-env (oi) end ===

# ---------------------------------------------------------------------------
# 8. Prompt — Oh My Posh (atomic_renan theme, initialized once)
# ---------------------------------------------------------------------------
if [ "$TERM_PROGRAM" != "Apple_Terminal" ] && command -v oh-my-posh >/dev/null 2>&1; then
  if [ -f "$HOME/.config/oh-my-posh/atomic_renan.omp.json" ]; then
    eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/atomic_renan.omp.json")"
  elif [ -f "$HOME/GitLab/terminal-configuration/atomic_renan.omp.json" ]; then
    eval "$(oh-my-posh init zsh --config "$HOME/GitLab/terminal-configuration/atomic_renan.omp.json")"
  else
    eval "$(oh-my-posh init zsh)"
  fi
fi
