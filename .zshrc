DOTFILES_DIR="${0:A:h}"

autoload -Uz compinit; compinit

if [[ "$(uname)" == "Darwin" ]]; then
  source "$DOTFILES_DIR/.zshrc.local"
else
  source "$DOTFILES_DIR/.zshrc.workspace"
fi

source "$DOTFILES_DIR/.zshrc.shared"
