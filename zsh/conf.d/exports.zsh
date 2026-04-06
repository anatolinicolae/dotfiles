# NOTE: Homebrew is already in PATH via .zshenv — do not repeat eval here.

# nvm — Homebrew installs to /opt/homebrew/opt/nvm/, NOT ~/.nvm/
# The OMZ nvm plugin expects ~/.nvm/nvm.sh and silently fails with Homebrew nvm.
# Source from Homebrew prefix directly instead.
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \
  source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# uv and local bins
export PATH="$HOME/.local/bin:$PATH"
