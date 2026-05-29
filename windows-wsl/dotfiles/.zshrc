# ~/.zshrc — zsh config (managed setup: zsh + Starship + fzf + zoxide)
# Backups of the original bash dotfiles live at ~/.bashrc.bak and ~/.profile.bak
# To temporarily drop back to bash, just run: bash

# ---------------------------------------------------------------------------
# PATH (user-space bins: starship, uv, pipx, cargo)
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ---------------------------------------------------------------------------
# History — large, deduped, shared across sessions
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

# ---------------------------------------------------------------------------
# Sensible shell behaviour
# ---------------------------------------------------------------------------
setopt AUTO_CD                # type a dir name to cd into it
setopt AUTO_PUSHD             # cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS   # allow # comments at the prompt
setopt NO_BEEP

# ---------------------------------------------------------------------------
# Completion system
# ---------------------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# ---------------------------------------------------------------------------
# Plugins (order matters: fzf-tab before, syntax-highlighting LAST)
# ---------------------------------------------------------------------------
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Accept the autosuggestion with the right arrow or End key
bindkey '^[[C' forward-char

# ---------------------------------------------------------------------------
# fzf — Ctrl-R fuzzy history, Ctrl-T file picker, Alt-C cd
# ---------------------------------------------------------------------------
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ]   && source /usr/share/doc/fzf/examples/completion.zsh
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"

# ---------------------------------------------------------------------------
# zoxide — smart cd (use `z <part-of-path>` to jump, `zi` for interactive)
# ---------------------------------------------------------------------------
eval "$(zoxide init zsh)"

# ---------------------------------------------------------------------------
# Aliases — map Ubuntu's renamed binaries + modern replacements
# ---------------------------------------------------------------------------
alias cat='batcat --paging=never'
alias less='batcat'
alias fd='fdfind'
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --git --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
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
# Prompt — Starship (git + python aware). Keep this LAST.
# ---------------------------------------------------------------------------
eval "$(starship init zsh)"
