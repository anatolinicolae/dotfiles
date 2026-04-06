#!/usr/bin/env bash
# Dotfiles installer — run with: bash install.sh
# Do NOT pipe this script (curl ... | bash) — it uses interactive prompts.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Dotfiles: $DOTFILES"

# ── 1. Homebrew ────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
echo "==> Homebrew ready"

# ── 2. Profile selection ───────────────────────────────────────────────────────
while true; do
  read -rp "==> Profile [work/personal]: " PROFILE
  [[ "$PROFILE" == "work" || "$PROFILE" == "personal" ]] && break
  echo "    Enter 'work' or 'personal'"
done

# ── 3. Persist profile ─────────────────────────────────────────────────────────
echo "export DOTFILES_PROFILE=$PROFILE" > "$HOME/.dotfiles_profile"
echo "==> Profile '$PROFILE' saved to ~/.dotfiles_profile"

# ── 4. Homebrew packages ───────────────────────────────────────────────────────
echo "==> Installing packages from profiles/$PROFILE/Brewfile..."
brew bundle --file="$DOTFILES/profiles/$PROFILE/Brewfile"
echo "==> Packages installed. Commit profiles/$PROFILE/Brewfile.lock.json if updated."

# ── 5. Oh My Zsh ───────────────────────────────────────────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "==> Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "==> Oh My Zsh already installed, skipping"
fi

# ── 6. ZSH_CUSTOM ─────────────────────────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ── 7. Powerlevel10k ──────────────────────────────────────────────────────────
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  echo "==> Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
else
  echo "==> Powerlevel10k already installed, skipping"
fi

# ── 8. Zsh plugins ────────────────────────────────────────────────────────────
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  echo "==> Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  echo "==> Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ── 9. nvm directory ──────────────────────────────────────────────────────────
mkdir -p "$HOME/.nvm"

# ── 10. Symlink topics ────────────────────────────────────────────────────────
echo "==> Symlinking dotfiles..."
for topic in zsh git powerlevel10k; do
  for file in "$DOTFILES/$topic"/.*; do
    name="$(basename "$file")"
    [[ "$name" == "." || "$name" == ".." ]] && continue
    [[ -d "$file" ]] && continue   # skip conf.d and other subdirs
    target="$HOME/$name"
    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "  Backing up $target → ${target}.backup"
      mv "$target" "${target}.backup"
    fi
    ln -sf "$file" "$target"
    echo "  Linked: ~/$name → $file"
  done
done

# ── 11. ~/.secrets ────────────────────────────────────────────────────────────
if [[ ! -f "$HOME/.secrets" ]]; then
  cp "$DOTFILES/.secrets.example" "$HOME/.secrets"
  echo "==> Created ~/.secrets from template — fill it in"
fi

# ── 12. ~/.gitconfig.local ────────────────────────────────────────────────────
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  cat > "$HOME/.gitconfig.local" <<'EOF'
[user]
  name = Your Name
  email = you@example.com
EOF
  echo "==> Created ~/.gitconfig.local — fill in your name and email"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✓ Done! Next steps:"
echo "  1. Open a new terminal (or: source ~/.zshrc)"
echo "  2. Edit ~/.gitconfig.local — add your name and email"
echo "  3. Edit ~/.secrets — add any API keys or tokens"
echo "  4. Run 'p10k configure' to set up your prompt"
echo "  5. Commit profiles/$PROFILE/Brewfile.lock.json if brew bundle updated it"
