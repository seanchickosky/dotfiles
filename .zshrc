DOTFILES_DIR="${0:A:h}"

if [[ "$(uname)" == "Darwin" ]]; then
  source "$DOTFILES_DIR/.zshrc.local"
else
  source "$DOTFILES_DIR/.zshrc.workspace"
fi

source "$DOTFILES_DIR/.zshrc.shared"
