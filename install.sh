#!/usr/bin/env bash
# Bootstrap packages for workspace environments. Idempotent — safe to re-run.
set -euo pipefail

ensure() {
  local name="$1" check="$2" install="$3"
  if ! eval "$check" &>/dev/null; then
    echo "[dotfiles] Installing $name..."
    eval "$install"
  else
    echo "[dotfiles] $name already installed"
  fi
}

# Symlink dotfiles into $HOME
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
for f in .zshrc; do
  if [[ ! -L "$HOME/$f" || "$(readlink "$HOME/$f")" != "$DOTFILES_DIR/$f" ]]; then
    echo "[dotfiles] Linking $f -> $DOTFILES_DIR/$f"
    ln -sf "$DOTFILES_DIR/$f" "$HOME/$f"
  fi
done

ensure "oh-my-zsh" "test -d \$HOME/.oh-my-zsh" \
  'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc'

ensure "starship" "command -v starship" \
  'curl -sS https://starship.rs/install.sh | sh -s -- -y'

ensure "fzf" "command -v fzf" \
  'git -c url."https://github.com/".insteadOf="" clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all --no-bash --no-fish'

ensure "fzf-tab" "test -d \$HOME/fzf-tab" \
  'git -c url."https://github.com/".insteadOf="" clone https://github.com/Aloxaf/fzf-tab ~/fzf-tab'

ensure "direnv" "command -v direnv" \
  'curl -sfL https://direnv.net/install.sh | bash'

if command -v npm &>/dev/null; then
  ensure "claude-code" "command -v claude" \
    'npm install -g @anthropic-ai/claude-code'
fi

# Stamp so .zshrc.workspace doesn't re-run on every shell
touch "$DOTFILES_DIR/.bootstrapped"

echo "[dotfiles] Bootstrap complete"
