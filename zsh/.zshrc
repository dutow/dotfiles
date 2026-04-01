# PATH
typeset -U path
path=(~/.local/bin $path)

# Environment
export EDITOR=nvim
# Preserve forwarded SSH agent when connected via SSH; use local agent otherwise
if [[ -z "$SSH_CONNECTION" ]] || [[ -z "$SSH_AUTH_SOCK" ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
export DOTFILES_AICONT_DIR="${DOTFILES_AICONT_DIR:-$HOME/.aicont}"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt hist_ignore_dups
setopt hist_ignore_space
setopt share_history

# Key bindings
bindkey '^[[1;5D' backward-word    # Ctrl+Left
bindkey '^[[1;5C' forward-word     # Ctrl+Right
bindkey '^[[H'    beginning-of-line # Home
bindkey '^[[F'    end-of-line       # End
bindkey '^[[3~'   delete-char       # Delete

# Completion
fpath=(~/.dotfiles/zsh/completions $fpath)
autoload -Uz compinit && compinit

# Antidote (plugin manager)
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
source ~/.dotfiles/zsh/antidote/antidote.zsh
antidote load ~/.dotfiles/zsh/.zsh_plugins.txt

# git-subrepo
if [[ -f ~/.git-subrepo/.rc ]]; then
  source ~/.git-subrepo/.rc
fi

# mise (version manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# Starship prompt
eval "$(starship init zsh)"
