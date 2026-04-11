# dotfiles

macOS dotfiles for `work` and `personal` machines. Manages shell config, Git config, and Homebrew packages via profiles.

## Structure

```
dotfiles/
├── install.sh              # Bootstrap script — run this on a new machine
├── .secrets.example        # Template for ~/.secrets (API keys, tokens)
├── profiles/
│   ├── personal/Brewfile   # Personal machine packages
│   └── work/Brewfile       # Work machine packages
├── zsh/
│   ├── .zshenv             # Sets $DOTFILES, $DOTFILES_PROFILE, Homebrew PATH
│   ├── .zshrc              # Oh My Zsh, Powerlevel10k, sources conf.d/
│   └── conf.d/
│       ├── aliases.zsh
│       ├── exports.zsh     # PATH exports (nvm, gcloud, etc.)
│       └── functions.zsh   # Shell utilities + Claude Code helpers
├── git/
│   ├── .gitconfig          # Shared config; includes ~/.gitconfig.local
│   └── .gitignore_global
└── powerlevel10k/
    └── .p10k.zsh           # Prompt config (regenerate with `p10k configure`)
```

## Setup

```bash
git clone <repo> ~/dotfiles
bash ~/dotfiles/install.sh
```

The installer will:

1. Install Homebrew if missing
2. Ask for a profile (`work` or `personal`)
3. Run `brew bundle` for that profile's Brewfile
4. Install Oh My Zsh, Powerlevel10k, and zsh plugins
5. Symlink dotfiles from `zsh/`, `git/`, and `powerlevel10k/` into `$HOME`
6. Create `~/.secrets` from `.secrets.example` (fill in API keys/tokens)
7. Create `~/.gitconfig.local` (fill in your name and email)

After install, open a new terminal or run `source ~/.zshrc`, then run `p10k configure` to set up your prompt.

## Updating packages

```bash
brewup
```

This runs `brew bundle --upgrade` against the active profile's Brewfile. Commit the updated `Brewfile.lock.json` afterwards.

## Machine-local overrides

| File | Purpose |
|---|---|
| `~/.secrets` | API keys, tokens — sourced by `.zshrc`, never committed |
| `~/.zshrc.local` | Shell overrides specific to this machine |
| `~/.gitconfig.local` | Git user name and email |
| `~/.dotfiles_profile` | Active profile (`work` or `personal`) — set by `install.sh` |

## Profiles

Profiles live in `profiles/<name>/Brewfile`. The active profile is saved to `~/.dotfiles_profile` by `install.sh` and picked up automatically by `.zshenv` and the `brewup` alias.

To add packages, edit the relevant Brewfile and run `brewup`.

## Claude Code

`functions.zsh` includes helpers for Claude Code MCP plugin management:

```bash
claude-plugin <name>   # enable an MCP plugin in .claude/settings.local.json
claude-setup           # enable serena + context7 for the current project
```
