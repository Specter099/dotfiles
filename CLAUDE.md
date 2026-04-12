# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS dotfiles and bootstrap automation for development machines. Manages zsh configuration, Git settings (including SSH commit signing), Starship prompt, SSH config, AWS config, and macOS system preferences. Includes an idempotent installer that handles everything from Homebrew to dev tool installation.

## Setup

```bash
git clone git@github.com:Specter099/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles

# Full install
./bootstrap/install.sh

# Minimal (dotfiles + shell only, no dev tools or macOS prefs)
./bootstrap/install.sh --minimal

# Selective
./bootstrap/install.sh --no-tools    # skip pyenv, nvm, cdk, ansible, terraform
./bootstrap/install.sh --no-macos    # skip macOS defaults
./bootstrap/install.sh --no-nas      # skip NAS auto-mount
```

## Common Commands

```bash
# Apply macOS preferences (Finder, Dock, keyboard, etc.)
./bootstrap/macos.sh

# Set up SSH commit signing
./bootstrap/setup-signed-commits.sh

# Set up NAS SMB auto-mount
./bootstrap/setup-nas-mount.sh

# After pulling changes, reload shell config
source ~/.zshrc
```

## Directory Structure

```
bootstrap/
  install.sh              # Main idempotent installer (Homebrew, tools, symlinks, signing)
  macos.sh                # macOS system preferences (Finder, Dock, keyboard, etc.)
  setup-signed-commits.sh # SSH commit signing setup + GitHub key registration
  setup-nas-mount.sh      # NAS SMB auto-mount configuration
zsh/
  .zshrc                  # Main zsh config (symlinked to ~/.zshrc)
  .zsh_aliases            # Shell aliases
  .zsh_functions          # Shell functions
git/
  .gitconfig              # Git config (symlinked to ~/.gitconfig)
  .gitignore_global       # Global gitignore
ssh/
  config                  # SSH client config (symlinked to ~/.ssh/config)
aws/
  config                  # AWS CLI config template
starship/
  starship.toml           # Starship prompt config (symlinked to ~/.config/starship.toml)
claude/
  statusline-command.sh   # Claude Code statusline integration
```

## How Dotfiles Are Applied

The installer creates symlinks from the repo into the home directory. Changes to files in this repo take effect immediately (no re-install needed). Machine-specific overrides go in `~/.zshrc.local` (not committed).

## Key Tools Managed

Homebrew, pyenv, nvm, AWS CLI, AWS CDK, Terraform, Ansible, GitHub CLI, Starship, fzf, ripgrep, bat, eza, zoxide, direnv
