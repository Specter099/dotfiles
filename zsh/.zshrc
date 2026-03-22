# ~/.zshrc — Specter099 zsh config
# Managed by dotfiles: https://github.com/Specter099/dotfiles

# ── Performance: profile with ZSH_PROFILING=1 zsh -i -c exit ─────────────────
[[ "$ZSH_PROFILING" == "1" ]] && zmodload zsh/zprof

# ── Path ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"   # Apple Silicon
export PATH="$HOME/.npm-global/bin:$PATH"

# ── Pyenv ─────────────────────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null; then
  eval "$(pyenv init -)"
fi

# ── NVM ───────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
# Lazy-load nvm for faster shell startup
nvm() {
  unset -f nvm
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
  nvm "$@"
}

# ── Zsh options ───────────────────────────────────────────────────────────────
setopt AUTO_CD              # cd by typing directory name
setopt CORRECT              # command correction
setopt HIST_IGNORE_DUPS     # no duplicate history entries
setopt HIST_IGNORE_SPACE    # space-prefixed commands not saved
setopt SHARE_HISTORY        # share history across sessions
setopt EXTENDED_GLOB        # extended globbing

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# ── Completion ────────────────────────────────────────────────────────────────
autoload -Uz compinit
# Only rebuild compinit once per day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# ── Plugins ───────────────────────────────────────────────────────────────────
ZSH_PLUGIN_DIR="${HOME}/.zsh/plugins"

source_if_exists() { [[ -f "$1" ]] && source "$1"; }

source_if_exists "$ZSH_PLUGIN_DIR/zsh-completions/zsh-completions.plugin.zsh"
source_if_exists "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
source_if_exists "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# fzf
source_if_exists "$HOME/.fzf.zsh"

# ── AWS CLI completion ────────────────────────────────────────────────────────
if command -v aws_completer >/dev/null; then
  autoload bashcompinit && bashcompinit
  complete -C "$(which aws_completer)" aws
fi

# ── direnv ────────────────────────────────────────────────────────────────────
if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
fi

# ── zoxide (smart cd) ─────────────────────────────────────────────────────────
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ── Aliases & Functions ───────────────────────────────────────────────────────
source_if_exists "$HOME/.zsh_aliases"
source_if_exists "$HOME/.zsh_functions"

# ── SSH agent (reuse across sessions) ─────────────────────────────────────────
_ssh_agent_sock="$HOME/.ssh/agent.sock"
if [[ ! -S "$_ssh_agent_sock" ]]; then
  eval "$(ssh-agent -a "$_ssh_agent_sock")" > /dev/null
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519 2>/dev/null
fi
export SSH_AUTH_SOCK="$_ssh_agent_sock"

# ── Starship prompt ───────────────────────────────────────────────────────────
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# ── Local overrides (not in git) ──────────────────────────────────────────────
source_if_exists "$HOME/.zshrc.local"

# ── Profiling output ──────────────────────────────────────────────────────────
[[ "$ZSH_PROFILING" == "1" ]] && zprof
