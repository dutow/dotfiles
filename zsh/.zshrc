# PATH
typeset -U path
path=(~/.local/bin $path)

# Environment
export EDITOR=nvim
# Preserve forwarded SSH agent when connected via SSH; use local agent otherwise
if [[ -z "$SSH_CONNECTION" ]] || [[ -z "$SSH_AUTH_SOCK" ]]; then
  if [[ -n "$XDG_RUNTIME_DIR" && -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
  fi
fi
export DOTFILES_AICONT_DIR="${DOTFILES_AICONT_DIR:-$HOME/.aicont}"
export VAGRANT_DEFAULT_PROVIDER=libvirt

# Load SSH keys into agent on first interactive shell (console/WSL)
# Desktop (Hyprland) handles this via exec-once with askpass
if [[ -n "$SSH_AUTH_SOCK" && -z "$SSH_CONNECTION" && -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
  if ! ssh-add -l &>/dev/null && [[ -t 0 ]]; then
    SSH_ASKPASS_REQUIRE=prefer ssh-add
  fi
fi

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

# Android SDK lives at one fixed path on host and in containers alike, so a
# project built inside dcont opens unchanged in host Android Studio (sdk.dir and
# NDK paths match everywhere). In containers ~/Android/Sdk is a symlink into the
# per-context persist dir, so the SDK still survives rebuilds.
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
path=("$ANDROID_HOME/cmdline-tools/latest/bin" "$ANDROID_HOME/platform-tools" $path)

# Container-only aliases (dcont / docker / podman)
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
  alias yclaude='claude --dangerously-skip-permissions'
  alias ycodex='codex --dangerously-bypass-approvals-and-sandbox'

  # Keep mutable Android state (gradle cache, adb keys, AVDs) in the per-context
  # persist dir so it stays isolated and survives rebuilds. These paths don't
  # leak into project files, so they don't need to match the host.
  export ANDROID_USER_HOME="$HOME/.aicontext/persist/android/user"
  export GRADLE_USER_HOME="$HOME/.aicontext/persist/android/gradle"
  if [[ -z "${JAVA_HOME:-}" ]] && command -v java &>/dev/null; then
    export JAVA_HOME="${$(readlink -f "$(command -v java)"):h:h}"
  fi
fi

# Starship prompt
eval "$(starship init zsh)"
