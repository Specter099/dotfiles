# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS dotfiles repo for zsh, git, SSH, Starship prompt, AWS CLI profiles, and dev tool bootstrapping. Shell-only (no Python packages) — idempotent `install.sh` symlinks config files and installs tools via Homebrew. No Oh My Zsh; plugins are managed manually.

## Setup

```bash
git clone git@github.com:Specter099/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles

# Full install (tools + macOS preferences + signed commits)
./bootstrap/install.sh

# Minimal (dotfiles + shell only, no dev tools or macOS prefs)
./bootstrap/install.sh --minimal
```

## Common Commands

```bash
# Bootstrap variants
./bootstrap/install.sh                  # full install
./bootstrap/install.sh --minimal        # dotfiles + shell only
./bootstrap/install.sh --no-tools       # skip pyenv, nvm, cdk, ansible, terraform
./bootstrap/install.sh --no-macos       # skip macOS defaults (Finder, Dock, etc.)
./bootstrap/install.sh --no-nas         # skip NAS auto-mount

# Apply macOS preferences standalone
./bootstrap/macos.sh

# Set up SSH commit signing standalone
./bootstrap/setup-signed-commits.sh

# Reload shell after changes
source ~/.zshrc

# Profile shell startup time
ZSH_PROFILING=1 zsh -i -c exit
```

## Directory Structure

```
bootstrap/
  install.sh                # main idempotent bootstrap script
  macos.sh                  # macOS defaults (Finder, Dock, keyboard, etc.)
  setup-signed-commits.sh   # SSH-based git commit signing
  setup-nas-mount.sh        # SMB NAS auto-mount via launchd
zsh/
  .zshrc                    # main shell config (pyenv, nvm lazy-load, plugins)
  .zsh_aliases              # aliases: git, aws, cdk, docker, terraform, etc.
  .zsh_functions            # functions: awsp, cwlogs, ec2ls, mkpy, mkcdk, etc.
git/
  .gitconfig                # git config (SSH signing, delta pager, aliases)
  .gitignore_global         # global gitignore
starship/
  starship.toml             # Starship prompt (git, aws, python, terraform, docker)
ssh/
  config                    # SSH config (GitHub, SSM proxy, homelab hosts)
aws/
  config                    # AWS SSO profiles (multi-account org)
claude/
  statusline-command.sh     # Claude Code statusline (dir, git, model, ctx, aws, venv)
```

## Architecture

- **Symlink-based**: `install.sh` symlinks files from the repo into `$HOME`. Changes to the repo take effect immediately (no re-install needed).
- **Idempotent**: Every step checks before acting — existing tools are skipped, existing files are backed up to `~/.dotfiles-backup/<timestamp>/`.
- **NVM lazy-loading**: NVM is wrapped in a function stub to avoid ~200ms shell startup penalty. First call to `nvm`, `node`, or `npm` triggers the real load.
- **Compinit caching**: Completion dump is only rebuilt once per 24 hours.
- **SSH agent persistence**: A single agent socket at `~/.ssh/agent.sock` is reused across terminal sessions.
- **Local overrides**: `~/.zshrc.local` is sourced at the end of `.zshrc` for machine-specific config that shouldn't be committed.

## Key Shell Functions

| Function | Purpose |
|---|---|
| `awsp` | Switch AWS profile with fzf picker |
| `awsenv <profile>` | Export SSO credentials to env vars |
| `cwlogs [group]` | Tail CloudWatch logs (fzf group picker) |
| `ec2ls` | Table of EC2 instances |
| `feature <name>` | Create and push `feature/<name>` branch |
| `mkpy <name>` | Scaffold Python project with venv + .gitignore |
| `mkcdk <name>` | Scaffold CDK Python project |
| `cdk-bootstrap` | Bootstrap CDK in current account/region |

## Key Aliases

| Alias | Expands To |
|---|---|
| `gs` | `git status -sb` |
| `gd` / `gds` | `git diff` / `git diff --staged` |
| `gpl` | `git pull --rebase` |
| `gverify` | `git log --show-signature -1` |
| `venv` | `python3 -m venv .venv && source .venv/bin/activate` |
| `activate` | `source .venv/bin/activate` |
| `cs` / `cd-diff` | `cdk synth` / `cdk diff` |
| `tf` / `tfi` / `tfp` / `tfa` | terraform shortcuts |
