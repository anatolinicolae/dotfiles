# Derive dotfiles repo root from this file's real path.
# ${(%):-%N} = current file path (works when sourced, unlike $0).
# :A = resolve symlinks. :h:h = go up two dirs (zsh/ → dotfiles/).
export DOTFILES="${${(%):-%N}:A:h:h}"

# Profile selection (written by install.sh to ~/.dotfiles_profile)
[[ -f ~/.dotfiles_profile ]] && source ~/.dotfiles_profile

# Homebrew — needed in PATH for all shell types including non-interactive
eval "$(/opt/homebrew/bin/brew shellenv)"
