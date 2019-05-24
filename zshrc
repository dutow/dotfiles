# Based on: https://github.com/pgilad/dotfiles/blob/master/link/.zshrc

export DOTFILES="$HOME/.dotfiles"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
export CACHE_DIR="$HOME/.cache"

[[ ! -d "$CACHE_DIR" ]] && mkdir -p "$CACHE_DIR"

export EDITOR=vim
export VISUAL=vim
export MC_SKIN="$HOME/.mc/solarized.ini"

export ZPLUG_HOME="$HOME/.zplug"

# set the correct term with TMUX
if [[ -n "$TMUX" ]]; then
    export TERM=screen-256color
else
    export TERM=xterm-256color
fi

# language settings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

setopt no_beep # disable sound
unsetopt beep # no bell on error
unsetopt hist_beep # no bell on error in history
unsetopt list_beep # no bell on ambiguous completion

if [[ ! -d "$ZPLUG_HOME" ]]; then
    echo "Installing zplug"
    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
    # zplug.sh domain has expired
    # curl -sL --proto-redir -all,https https://zplug.sh/installer | zsh
    source "$ZPLUG_HOME/init.zsh"
    zplug update
else
    source "$ZPLUG_HOME/init.zsh"
fi

# zplug stuff

# Theme
SPACESHIP_TIME_SHOW=true
SPACESHIP_DIR_TRUNC=0
SPACESHIP_DIR_TRUNC_REPO=false
SPACESHIP_EXIT_CODE_SHOW=true
zplug denysdovhan/spaceship-prompt, use:spaceship.zsh, from:github, as:theme

if ! zplug check; then
    zplug install
fi

zplug load

