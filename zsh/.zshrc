# Powerlevel10k instant prompt.
# Must be VERY FIRST — before any output or slow operations.
# .zshenv has already run at this point: $DOTFILES and Homebrew PATH are available.
[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]] && \
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# nvm is NOT in this list — the OMZ nvm plugin silently fails with Homebrew's nvm
# (which puts nvm.sh in /opt/homebrew/opt/nvm/, not ~/.nvm/).
# nvm is sourced manually in conf.d/exports.zsh instead.
#
# zsh-syntax-highlighting MUST be last — it wraps all other plugin hooks.
# Do not insert plugins after it.
plugins=(git docker z terraform node yarn zsh-autosuggestions zsh-syntax-highlighting)

source "$ZSH/oh-my-zsh.sh"

# Powerlevel10k prompt config.
# Run `p10k configure` to regenerate interactively.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Source conf.d partials via $DOTFILES (set in .zshenv).
# Do NOT use $(dirname $0) — $0 in .zshrc is the shell binary name, not the file path.
for f in "$DOTFILES/zsh/conf.d"/*.zsh; do
  [[ -f "$f" ]] && source "$f"
done

# Machine-local overrides (outside repo, never committed)
[[ -f ~/.secrets ]] && source ~/.secrets
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
