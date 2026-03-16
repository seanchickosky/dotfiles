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

# Configure Claude Code (merge into existing settings, symlink hooks)
if [[ -d "$DOTFILES_DIR/.claude" ]]; then
  mkdir -p "$HOME/.claude"

  # Symlink hooks directory
  src="$DOTFILES_DIR/.claude/hooks"
  dst="$HOME/.claude/hooks"
  if [[ -d "$src" ]] && [[ ! -L "$dst" || "$(readlink "$dst")" != "$src" ]]; then
    echo "[dotfiles] Linking .claude/hooks -> $src"
    ln -sf "$src" "$dst"
  fi

  # Merge settings.json (preserves existing keys like auth)
  src="$DOTFILES_DIR/.claude/settings.json"
  dst="$HOME/.claude/settings.json"
  if [[ -f "$src" ]]; then
    if command -v jq &>/dev/null; then
      if [[ -f "$dst" ]] && [[ ! -L "$dst" ]]; then
        echo "[dotfiles] Merging dotfiles claude settings into $dst"
        jq -s '.[0] * .[1]' "$dst" "$src" > "$dst.tmp" && mv "$dst.tmp" "$dst"
      else
        # No existing file (or it's a stale symlink) — copy directly
        rm -f "$dst"
        echo "[dotfiles] Writing claude settings to $dst"
        cp "$src" "$dst"
      fi
    else
      echo "[dotfiles] Warning: jq not found, skipping claude settings merge"
    fi
  fi
fi

ensure "oh-my-zsh" "test -d \$HOME/.oh-my-zsh" \
  'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc'

ensure "starship" "command -v starship" \
  'curl -sS https://starship.rs/install.sh | sh -s -- -y'

ensure "fzf" "test -d \$HOME/.fzf" \
  'git -c url."https://github.com/".insteadOf="" clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all --no-bash --no-fish'

ensure "fzf-tab" "test -d \$HOME/fzf-tab" \
  'git -c url."https://github.com/".insteadOf="" clone https://github.com/Aloxaf/fzf-tab ~/fzf-tab'

ensure "direnv" "command -v direnv" \
  'curl -sfL https://direnv.net/install.sh | bash'

ensure "rust" "command -v cargo" \
  'curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && source "$HOME/.cargo/env"'

NODE_VERSION="22.12.0"
ensure "node" "command -v node" \
  'mkdir -p "$HOME/.local" && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" | tar -xJ -C "$HOME/.local" --strip-components=1'

ensure "graphite" "command -v gt" \
  'npm install -g @withgraphite/graphite-cli && echo "[dotfiles] Run: gt auth --token <token> (get token from https://app.graphite.com/activate)"'

# Graphite user config
if command -v gt &>/dev/null; then
  gt user branch-prefix --set seanchickosky/ 2>/dev/null

  cfg="$HOME/.graphite_user_config"
  # Seed auth token from workspaces secrets if available
  secrets_dir="/run/user/$(id -u)/secrets"
  if [[ -f "$secrets_dir/GRAPHITE_TOKEN" ]] && ! grep -q authToken "$cfg" 2>/dev/null; then
    token=$(cat "$secrets_dir/GRAPHITE_TOKEN")
    gt auth --token "$token" 2>/dev/null
  fi

  # Set PR metadata in CLI (no gt command for this, write directly)
  if [[ -f "$cfg" ]]; then
    jq '.submitViaCli = true' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
  else
    echo '{"submitViaCli":true}' > "$cfg"
  fi
fi

# Git rerere: remember conflict resolutions and auto-apply them
git config --global rerere.enabled true
git config --global rerere.autoUpdate true

# Stamp so .zshrc.workspace doesn't re-run on every shell
touch "$DOTFILES_DIR/.bootstrapped"

echo "[dotfiles] Bootstrap complete"
