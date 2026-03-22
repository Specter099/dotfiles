# Dotfiles Setup Guide

Step-by-step instructions for deploying this dotfiles repo to a fresh or existing macOS machine.

---

## Prerequisites

- macOS (Apple Silicon or Intel)
- Admin access (for Homebrew, shell change, energy settings)
- GitHub account with SSH access configured (or willingness to set it up)

---

## Option A: Automated (Recommended)

### 1. Clone the repo

```bash
git clone git@github.com:Specter099/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
```

### 2. Run the installer

```bash
# Full install (tools + macOS preferences + signed commits)
./bootstrap/install.sh

# Minimal (dotfiles + shell only, no dev tools or macOS prefs)
./bootstrap/install.sh --minimal

# Skip specific parts
./bootstrap/install.sh --no-tools    # skip dev tools (pyenv, nvm, cdk, ansible, terraform)
./bootstrap/install.sh --no-macos    # skip macOS defaults (Finder, Dock, keyboard, etc.)
```

### 3. Restart your terminal

```bash
source ~/.zshrc
```

### 4. Verify

```bash
# Shell
starship --version          # prompt installed
echo $SHELL                 # should be zsh

# Git signing
git log --show-signature -1 # should show "Good signature"
gverify                     # alias for the above

# Tools (if not --minimal)
pyenv --version
node --version
cdk --version
aws --version
```

---

## Option B: Manual (Step-by-Step)

Use this if you want to cherry-pick components or understand what each piece does.

### Step 1: Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon: add to PATH
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Step 2: Install core CLI tools

```bash
brew install git curl wget jq yq fzf ripgrep bat eza zoxide direnv htop tree gnupg openssh
```

### Step 3: Install Starship prompt

```bash
brew install starship
```

### Step 4: Install zsh plugins

```bash
mkdir -p ~/.zsh/plugins
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-completions ~/.zsh/plugins/zsh-completions
```

### Step 5: Install fzf shell integration

```bash
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
```

### Step 6: Symlink dotfiles

Back up any existing files first, then link:

```bash
DOTFILES=~/dev/dotfiles

# Shell
ln -sf $DOTFILES/zsh/.zshrc           ~/.zshrc
ln -sf $DOTFILES/zsh/.zsh_aliases     ~/.zsh_aliases
ln -sf $DOTFILES/zsh/.zsh_functions   ~/.zsh_functions

# Git
ln -sf $DOTFILES/git/.gitconfig        ~/.gitconfig
ln -sf $DOTFILES/git/.gitignore_global ~/.gitignore_global

# Starship
mkdir -p ~/.config
ln -sf $DOTFILES/starship/starship.toml ~/.config/starship.toml
```

### Step 7: Set up SSH commit signing

```bash
./bootstrap/setup-signed-commits.sh

# Or with explicit options:
./bootstrap/setup-signed-commits.sh --email you@example.com --key-path ~/.ssh/id_ed25519
```

What this does:
1. Detects or generates an ed25519 SSH key
2. Configures `git config --global` for SSH signing
3. Creates `~/.ssh/allowed_signers` for local verification
4. Registers the signing key on GitHub (if `gh` is authenticated)
5. Runs a test signature to verify

After running, set your git email if not already set:

```bash
git config --global user.email "you@example.com"
```

### Step 8: Install dev tools

```bash
# GitHub CLI
brew install gh
gh auth login

# Python via pyenv
brew install pyenv pyenv-virtualenv
pyenv install 3.12.3
pyenv global 3.12.3

# Node via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.nvm/nvm.sh
nvm install --lts

# AWS CDK
npm install -g aws-cdk

# AWS CLI
brew install awscli

# Terraform
brew install terraform

# Ansible
pip3 install ansible ansible-lint
```

### Step 9: Apply macOS preferences

```bash
./bootstrap/macos.sh
```

Review what it changes before running:

| Category         | Setting                                      |
|------------------|----------------------------------------------|
| Keyboard         | Fast key repeat, disable press-and-hold      |
| Trackpad         | Tap to click                                 |
| Finder           | Show hidden files, extensions, path bar, list view, folders on top |
| Dock             | Auto-hide, smaller tiles, no recent apps     |
| Screenshots      | Save to `~/Desktop/Screenshots`, PNG, no shadow |
| Safari           | Show full URL                                |
| Terminal         | Secure keyboard entry                        |
| Activity Monitor | Show all processes, sort by CPU              |
| Dialogs          | Expanded save/print panels                   |
| Text             | Disable auto-correct, smart quotes/dashes    |

Some settings require logout to take effect.

### Step 10: Restart terminal

```bash
source ~/.zshrc
```

---

## Post-Install Checklist

- [ ] Terminal restarted (or `source ~/.zshrc`)
- [ ] `starship` prompt showing git branch, AWS profile, Python venv
- [ ] `git config --global user.email` is set
- [ ] `git config --global user.signingkey` is set
- [ ] `gverify` shows a valid signature on a test commit
- [ ] `awsp` opens fzf profile picker (if AWS profiles configured)
- [ ] `gh auth status` shows authenticated
- [ ] SSH agent persists across terminal tabs (`echo $SSH_AUTH_SOCK` shows `~/.ssh/agent.sock`)
- [ ] Finder shows hidden files and path bar
- [ ] Dock auto-hides

---

## Updating

```bash
cd ~/dev/dotfiles
git pull
source ~/.zshrc    # pick up any shell changes immediately
```

Symlinks mean changes take effect as soon as the repo is updated. No re-running of `install.sh` needed for dotfile changes.

For tool updates:

```bash
brew upgrade               # CLI tools
pyenv install 3.x.x        # new Python version
nvm install --lts           # new Node LTS
npm update -g aws-cdk       # CDK
```

---

## Local Overrides

For machine-specific config that shouldn't be committed:

```bash
# Shell overrides (sourced at end of .zshrc)
vim ~/.zshrc.local

# Example: homelab SSH shortcuts
alias pfsense='ssh admin@pfsense.local'
alias pihole='ssh pi@pihole.local'
export MY_SECRET_TOKEN="..."
```

---

## Troubleshooting

**Starship not showing:** Ensure `eval "$(starship init zsh)"` runs after all other prompt setup. Check with `which starship`.

**SSH signing fails:** Run `ssh-add -l` to check if your key is loaded. If empty: `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`.

**Slow shell startup:** Profile with `ZSH_PROFILING=1 zsh -i -c exit` to find bottlenecks.

**NVM is slow:** NVM is lazy-loaded in `.zshrc`. The first `nvm`, `node`, or `npm` call in a session loads it. This is intentional.

**`awsp` doesn't show profiles:** Ensure `~/.aws/config` has profiles configured. Run `aws configure list-profiles` to verify.
