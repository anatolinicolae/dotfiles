# CLAUDE.md

macOS dotfiles repo — Zsh, Git, Homebrew, dev tools across `work` and `personal` profiles.

## Setup

`./install.sh` — prompts for profile, installs, symlinks dotfiles to `$HOME`. Profile in `~/.dotfiles_profile`. Idempotent.

## Architecture

```
.gitignore
.secrets.example      # template for ~/.secrets
install.sh
zsh/
  .zshenv             # derives $DOTFILES, sources ~/.dotfiles_profile, inits Homebrew
  .zshrc              # Oh My Zsh + Powerlevel10k + sources conf.d/*.zsh
  conf.d/
    aliases.zsh       # shell aliases + brewup, reload
    exports.zsh       # PATH setup (nvm, bun, uv, gcloud)
    functions.zsh     # utility fns + claude-plugin/claude-setup helpers
git/
  .gitconfig          # includes ~/.gitconfig.local for user-specific overrides
  .gitignore_global
powerlevel10k/
  .p10k.zsh           # Pure-style prompt config
profiles/
  work/Brewfile       # work machine packages
  personal/Brewfile   # personal machine packages
```

## Design Notes

- **$DOTFILES derived dynamically** — `.zshenv` resolves symlink to find repo root
- **nvm sourced manually** — OMZ nvm plugin skipped; Homebrew installs to non-standard path
- **Local files never committed** — `~/.secrets`, `~/.zshrc.local`, `~/.gitconfig.local`, `~/.dotfiles_profile`
- **Brewfile.lock.json committed** — tracks exact versions per profile

## Working With This Repo

- Modify aliases/functions/exports in `zsh/conf.d/` — one file per concern
- Brewfiles use Bundle syntax: `brew`, `cask`, `tap`, `mas`
- `brewup` — runs `brew bundle` for active profile (`$DOTFILES_PROFILE`)
- `reload` — `exec $SHELL -l`; use after editing dotfiles
- `claude-plugin <name>` — enables MCP plugin in `.claude/settings.local.json`
- `claude-setup` — enables serena + context7 for current project
- Never read `~/.secrets` / `.secrets` (`.secrets.example` is safe)
