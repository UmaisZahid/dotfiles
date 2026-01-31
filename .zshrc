# ~/.zshrc - Minimal, portable zsh configuration
# ============================================

# Path setup
export PATH="$HOME/.local/bin:$PATH"

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Basic options
setopt AUTO_CD
setopt CORRECT
setopt NO_BEEP

# Vi mode
bindkey -v
export KEYTIMEOUT=1

# ============================================
# Zinit Plugin Manager
# ============================================

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Auto-install zinit if not present
if [[ ! -d "$ZINIT_HOME" ]]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Plugins
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-history-substring-search

# History substring search keybindings (after plugin loads)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# ============================================
# FZF Configuration
# ============================================

if command -v fzf &>/dev/null; then
    # FZF default options
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

    # Use fd or find for file listing
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    fi

    # Enable fzf keybindings
    if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh
    elif [[ -f ~/.fzf.zsh ]]; then
        source ~/.fzf.zsh
    fi

    # Ctrl+R for history search
    fzf-history-widget() {
        local selected
        selected=$(fc -rl 1 | fzf --query="$LBUFFER" +s --tac | sed 's/^ *[0-9]* *//')
        if [[ -n "$selected" ]]; then
            LBUFFER="$selected"
        fi
        zle redisplay
    }
    zle -N fzf-history-widget
    bindkey '^R' fzf-history-widget
fi

# ============================================
# Aliases
# ============================================

# General
alias ls='eza -a --icons 2>/dev/null || ls -a --color=auto'
alias ll='eza -la --icons 2>/dev/null || ls -la --color=auto'
alias la='eza -a --icons 2>/dev/null || ls -a --color=auto'
alias lt='eza --tree --icons 2>/dev/null || tree'
alias cat='bat --paging=never 2>/dev/null || cat'

# Git - Basic operations
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gst='git status'
alias gss='git status --short'

# Git - Commits
alias gc='git commit --verbose'
alias 'gc!'='git commit --verbose --amend'
alias gcm='git commit -m'

# Git - Branches
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'

# Git - Diffs
alias gd='git diff'
alias gdc='git diff --cached'

# Git - Pull/Push
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpsup='git push --set-upstream origin $(git branch --show-current)'

# Git - Fetch
alias gf='git fetch'
alias gfa='git fetch --all --tags --prune'
alias gfu='git fetch upstream'

# Git - Merge/Rebase
alias gm='git merge'
alias grb='git rebase'
alias grba='git rebase --abort'

# Git - Logs
alias glo='git log --oneline'
alias glog='git log --oneline --decorate --graph'

# Git - Reset/Restore
alias grh='git reset'
alias grhh='git reset --hard'
alias grs='git restore'
alias grst='git restore --staged'

# ============================================
# Functions
# ============================================

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Go up N directories
up() {
    local count="${1:-1}"
    local path=""
    for ((i = 0; i < count; i++)); do
        path="../$path"
    done
    cd "$path"
}

# Copy current directory path to clipboard
cpwd() {
    if command -v xclip &>/dev/null; then
        pwd | tr -d '\n' | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        pwd | tr -d '\n' | xsel --clipboard
    elif command -v pbcopy &>/dev/null; then
        pwd | tr -d '\n' | pbcopy
    else
        echo "No clipboard tool found (xclip, xsel, or pbcopy)"
        return 1
    fi
    echo "Copied: $(pwd)"
}

# Universal archive extractor
extract() {
    if [[ -z "$1" ]]; then
        echo "Usage: extract <archive>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: '$1' is not a valid file"
        return 1
    fi

    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.tar)     tar xf "$1" ;;
        *.tbz2)    tar xjf "$1" ;;
        *.tgz)     tar xzf "$1" ;;
        *.zip)     unzip "$1" ;;
        *.Z)       uncompress "$1" ;;
        *.7z)      7z x "$1" ;;
        *.rar)     unrar x "$1" ;;
        *)         echo "Error: Unknown archive format '$1'" ;;
    esac
}

# Fuzzy checkout git branches
gch() {
    local branch
    branch=$(git branch --all | fzf --height 40% --reverse | sed 's/^[* ]*//' | sed 's/remotes\/origin\///')
    if [[ -n "$branch" ]]; then
        git checkout "$branch"
    fi
}

# Show available shortcuts
shelp() {
    echo "=== Git Aliases ==="
    echo "  g      = git"
    echo "  ga     = git add"
    echo "  gaa    = git add --all"
    echo "  gst    = git status"
    echo "  gss    = git status --short"
    echo "  gc     = git commit --verbose"
    echo "  gc!    = git commit --amend"
    echo "  gcm    = git commit -m"
    echo "  gco    = git checkout"
    echo "  gb     = git branch"
    echo "  gba    = git branch --all"
    echo "  gbd    = git branch --delete"
    echo "  gbD    = git branch --delete --force"
    echo "  gd     = git diff"
    echo "  gdc    = git diff --cached"
    echo "  gl     = git pull"
    echo "  gp     = git push"
    echo "  gpf    = git push --force-with-lease"
    echo "  gpsup  = git push --set-upstream"
    echo "  gf     = git fetch"
    echo "  gfa    = git fetch --all --tags --prune"
    echo "  gfu    = git fetch upstream"
    echo "  gm     = git merge"
    echo "  grb    = git rebase"
    echo "  grba   = git rebase --abort"
    echo "  glo    = git log --oneline"
    echo "  glog   = git log --oneline --graph"
    echo "  grh    = git reset"
    echo "  grhh   = git reset --hard"
    echo "  grs    = git restore"
    echo "  grst   = git restore --staged"
    echo "  gch    = fuzzy checkout branch"
    echo ""
    echo "=== Functions ==="
    echo "  mkcd <dir>    = mkdir + cd"
    echo "  up [N]        = go up N directories"
    echo "  cpwd          = copy current path to clipboard"
    echo "  extract <f>   = extract archive"
    echo ""
    echo "=== Navigation ==="
    echo "  z <dir>       = zoxide jump"
    echo "  Ctrl+R        = fuzzy history search"
    echo "  Up/Down       = history substring search"
}

# ============================================
# Tool Integrations
# ============================================

# Starship prompt
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# Zoxide (smart cd)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# ============================================
# Local Configuration
# ============================================

# Source machine-specific config if it exists
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
