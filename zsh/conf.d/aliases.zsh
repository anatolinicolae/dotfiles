# Update Homebrew packages for this machine's profile.
# Regenerates Brewfile.lock.json — commit it after running.
# $DOTFILES and $DOTFILES_PROFILE are set in .zshenv before .zshrc runs.
alias brewup='brew bundle --file="$DOTFILES/profiles/$DOTFILES_PROFILE/Brewfile"'
