# NOTE: Homebrew is already in PATH via .zshenv — do not repeat eval here.

# Automatic post-install cleanup (runs on every install/upgrade/reinstall)
# purges cached downloads older than this many days instead of the 120-day default.
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=14

# nvm — Homebrew installs to /opt/homebrew/opt/nvm/, NOT ~/.nvm/
# The OMZ nvm plugin expects ~/.nvm/nvm.sh and silently fails with Homebrew nvm.
# Source from Homebrew prefix directly instead.
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \
  source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# mise — runtime version manager. `mise activate zsh` prepends its shim dir to
# PATH so it takes precedence over nvm/bun at lookup time regardless of source
# order; for tools mise doesn't manage, the shim falls through untouched.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# uv and local bins
export PATH="$HOME/.local/bin:$PATH"

# gcloud — Homebrew cask installs to /opt/homebrew/share/google-cloud-sdk/
if [ -f "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc" ]; then
  source "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc"
  source "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"
fi
