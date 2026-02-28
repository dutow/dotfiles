# PATH
typeset -U path
path=(~/.local/bin $path)

# Environment
export EDITOR=nvim
export DOTFILES_AICONT_DIR="${DOTFILES_AICONT_DIR:-$HOME/.aicont}"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt hist_ignore_dups
setopt hist_ignore_space
setopt share_history

# Completion
fpath=(~/.dotfiles/zsh/completions $fpath)
autoload -Uz compinit && compinit

# Antidote (plugin manager)
source ~/.dotfiles/zsh/antidote/antidote.zsh
antidote load ~/.dotfiles/zsh/.zsh_plugins.txt

# mise (version manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# Starship prompt
eval "$(starship init zsh)"
