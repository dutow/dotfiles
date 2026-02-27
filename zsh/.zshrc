# PATH
typeset -U path
path=(~/.local/bin ~/.npm-global/bin $path)

# Environment
export EDITOR=nvim

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt hist_ignore_dups
setopt hist_ignore_space
setopt share_history

# Completion
autoload -Uz compinit && compinit

# Antidote (plugin manager)
source ~/.dotfiles/zsh/antidote/antidote.zsh
antidote load ~/.dotfiles/zsh/.zsh_plugins.txt

# ASDF
if [[ -z "$ASDF_DATA_DIR" ]]; then
  _asdf_shims="$HOME/.asdf/shims"
else
  _asdf_shims="$ASDF_DATA_DIR/shims"
fi
if [[ ":$PATH:" != *":$_asdf_shims:"* ]]; then
  path=($_asdf_shims $path)
fi
unset _asdf_shims

# Starship prompt
eval "$(starship init zsh)"
