#!/usr/bin/env bash
# install.sh — Idempotent dotfiles bootstrap for macOS + zsh
# Usage: ./install.sh [--minimal] [--no-tools] [--no-macos]
#
# One-liner: curl -fsSL https://raw.githubusercontent.com/Specter099/dotfiles/main/install.sh | bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# ── Flags ─────────────────────────────────────────────────────────────────────
MINIMAL=false
SKIP_TOOLS=false
SKIP_MACOS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --minimal)   MINIMAL=true;     shift ;;
    --no-tools)  SKIP_TOOLS=true;  shift ;;
    --no-macos)  SKIP_MACOS=true;  shift ;;
    *) warn "Unknown argument: $1"; shift ;;
  esac
done

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${GREEN}▸${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
step()    { echo -e "\n${BOLD}${CYAN}── $* ──${NC}"; }
success() { echo -e "${GREEN}✓${NC}  $*"; }
skip()    { echo -e "  ${YELLOW}↷${NC}  $* (already installed)"; }

# ── Helpers ───────────────────────────────────────────────────────────────────
is_mac() { [[ "$OSTYPE" == "darwin"* ]]; }

installed() { command -v "$1" >/dev/null 2>&1; }

link() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/"
    warn "Backed up existing $dst → $BACKUP_DIR/"
  fi
  ln -sf "$src" "$dst"
  success "Linked: $dst → $src"
}

brew_install() {
  local pkg="$1"
  if brew list "$pkg" &>/dev/null; then
    skip "$pkg"
  else
    info "Installing $pkg..."
    brew install "$pkg"
    success "Installed: $pkg"
  fi
}

brew_cask_install() {
  local pkg="$1"
  if brew list --cask "$pkg" &>/dev/null; then
    skip "$pkg (cask)"
  else
    info "Installing cask: $pkg..."
    brew install --cask "$pkg"
    success "Installed cask: $pkg"
  fi
}

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Dotfiles Bootstrap"
echo "  Specter099 / $(hostname)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Xcode CLI Tools ────────────────────────────────────────────────────────
if is_mac; then
  step "Xcode CLI Tools"
  if xcode-select -p &>/dev/null; then
    skip "Xcode CLI Tools"
  else
    info "Installing Xcode CLI Tools..."
    xcode-select --install
    info "Waiting for Xcode CLI Tools installation..."
    until xcode-select -p &>/dev/null; do sleep 5; done
    success "Xcode CLI Tools installed"
  fi
fi

# ── 2. Homebrew ───────────────────────────────────────────────────────────────
step "Homebrew"
if installed brew; then
  skip "Homebrew"
  info "Updating Homebrew..."
  brew update --quiet
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add to PATH for the rest of this script (Apple Silicon)
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  success "Homebrew installed"
fi

# ── 3. Core shell tools ───────────────────────────────────────────────────────
step "Core Tools"
CORE_PACKAGES=(
  git
  curl
  wget
  jq
  yq
  fzf
  ripgrep
  bat
  eza          # modern ls
  zoxide       # smart cd
  direnv
  htop
  tree
  gnupg
  openssh
)
for pkg in "${CORE_PACKAGES[@]}"; do
  brew_install "$pkg"
done

# ── 4. Dev tools (unless --no-tools) ─────────────────────────────────────────
if ! $SKIP_TOOLS && ! $MINIMAL; then
  step "Dev Tools"

  # GitHub CLI
  brew_install gh

  # AWS CLI v2
  if installed aws; then
    skip "aws-cli"
  else
    info "Installing AWS CLI v2..."
    brew_install awscli
  fi

  # Node via nvm
  if [[ -d "$HOME/.nvm" ]]; then
    skip "nvm"
  else
    info "Installing nvm..."
    NVM_VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    success "nvm + Node LTS installed"
  fi

  # AWS CDK
  if installed cdk; then
    skip "aws-cdk"
  else
    info "Installing AWS CDK..."
    npm install -g aws-cdk
    success "AWS CDK installed"
  fi

  # Python via pyenv
  if installed pyenv; then
    skip "pyenv"
  else
    info "Installing pyenv..."
    brew_install pyenv
    brew_install pyenv-virtualenv
  fi
  PYTHON_VERSION="${PYTHON_VERSION:-3.12.3}"
  if pyenv versions 2>/dev/null | grep -q "$PYTHON_VERSION"; then
    skip "Python $PYTHON_VERSION"
  else
    info "Installing Python $PYTHON_VERSION via pyenv..."
    pyenv install "$PYTHON_VERSION"
    pyenv global "$PYTHON_VERSION"
    success "Python $PYTHON_VERSION set as global"
  fi

  # Ansible
  if installed ansible; then
    skip "ansible"
  else
    pip3 install --quiet ansible ansible-lint
    success "Ansible installed"
  fi

  # Terraform (useful for occasional reference)
  brew_install terraform

  # Docker Desktop (cask)
  # brew_cask_install docker   # uncomment if desired
fi

# ── 5. zsh + Starship ─────────────────────────────────────────────────────────
step "Shell: zsh + Starship"

# Ensure zsh is default shell
if [[ "$SHELL" != *zsh* ]]; then
  info "Switching default shell to zsh..."
  chsh -s "$(which zsh)"
  success "Default shell set to zsh"
else
  skip "zsh (already default)"
fi

# Starship prompt
if installed starship; then
  skip "Starship"
else
  info "Installing Starship..."
  brew_install starship
fi

# zsh plugins (manual, no Oh My Zsh to keep it lean)
ZSH_PLUGIN_DIR="${ZSH_CUSTOM_PLUGINS:-$HOME/.zsh/plugins}"
mkdir -p "$ZSH_PLUGIN_DIR"

declare -A ZSH_PLUGINS=(
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
  ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
)
for name in "${!ZSH_PLUGINS[@]}"; do
  if [[ -d "$ZSH_PLUGIN_DIR/$name" ]]; then
    skip "zsh plugin: $name"
  else
    info "Installing zsh plugin: $name..."
    git clone --depth=1 "${ZSH_PLUGINS[$name]}" "$ZSH_PLUGIN_DIR/$name"
    success "Installed: $name"
  fi
done

# ── 6. Symlink dotfiles ───────────────────────────────────────────────────────
step "Symlinking Dotfiles"

mkdir -p "$HOME/.config" "$HOME/.ssh"

link "$DOTFILES_DIR/zsh/.zshrc"             "$HOME/.zshrc"
link "$DOTFILES_DIR/zsh/.zsh_aliases"       "$HOME/.zsh_aliases"
link "$DOTFILES_DIR/zsh/.zsh_functions"     "$HOME/.zsh_functions"
link "$DOTFILES_DIR/git/.gitconfig"         "$HOME/.gitconfig"
link "$DOTFILES_DIR/git/.gitignore_global"  "$HOME/.gitignore_global"
link "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# ── 7. Signed commits ─────────────────────────────────────────────────────────
step "SSH Commit Signing"
if [[ -f "$DOTFILES_DIR/bootstrap/setup-signed-commits.sh" ]]; then
  bash "$DOTFILES_DIR/bootstrap/setup-signed-commits.sh"
else
  warn "setup-signed-commits.sh not found in bootstrap/ — skipping"
fi

# ── 8. macOS preferences ──────────────────────────────────────────────────────
if is_mac && ! $SKIP_MACOS && ! $MINIMAL; then
  step "macOS Preferences"
  bash "$DOTFILES_DIR/bootstrap/macos.sh"
fi

# ── 9. fzf shell integration ──────────────────────────────────────────────────
step "fzf Shell Integration"
if [[ ! -f "$HOME/.fzf.zsh" ]]; then
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
  success "fzf shell integration installed"
else
  skip "fzf shell integration"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Bootstrap complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Restart your terminal or run: source ~/.zshrc"
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
  warn "Some files were backed up to: $BACKUP_DIR"
fi
