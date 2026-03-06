DOTFILES_DIR="${HOME}/.zshrc"
DOTFILES_DIR="${DOTFILES_DIR:A:h}"

autoload -Uz compinit; compinit

if [[ "$(uname)" == "Darwin" ]]; then
  source "$DOTFILES_DIR/.zshrc.local"
else
  source "$DOTFILES_DIR/.zshrc.workspace"
fi

source "$DOTFILES_DIR/.zshrc.shared"
