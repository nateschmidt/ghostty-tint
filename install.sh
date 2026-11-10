#!/bin/bash
# Install ghostty-tint on this Mac. Safe to re-run.
#   1. ~/.local/bin/tint            -> bin/tint (symlink)
#   2. ~/.oh-my-zsh/custom/tint.zsh -> shell/tint.zsh (symlink), or without
#      oh-my-zsh a `source` line appended to ~/.zshrc
#   3. ~/.config/tint/config.json    created with one color per project folder
#                                    in ~/code if missing (never overwritten)
#   4. ~/.claude/settings.json       hooks that call `tint hook` (tint install-hooks),
#                                    created if Claude Code has no settings file yet
#   5. ~/Library/LaunchAgents/com.nateschmidt.ghostty-tint.plist
#                                    keeps the web UI running on http://127.0.0.1:7337
set -euo pipefail
if ! python3 -c '' 2>/dev/null; then
  echo "tint needs python3. Run: xcode-select --install   then run this installer again." >&2
  exit 1
fi
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${TINT_PORT:-7337}"
LABEL=com.nateschmidt.ghostty-tint

mkdir -p "$HOME/.local/bin" "$HOME/.cache/tint"
chmod +x "$REPO/bin/tint"
ln -sfn "$REPO/bin/tint" "$HOME/.local/bin/tint"
echo "cli:    ~/.local/bin/tint"

if [ -d "$HOME/.oh-my-zsh/custom" ]; then
  ln -sfn "$REPO/shell/tint.zsh" "$HOME/.oh-my-zsh/custom/tint.zsh"
  old="$HOME/.oh-my-zsh/custom/ghostty-repo-colors.zsh"
  if [ -f "$old" ]; then
    mv "$old" "$old.replaced-by-tint"
    echo "shell:  retired $old (kept as .replaced-by-tint)"
  fi
  echo "shell:  ~/.oh-my-zsh/custom/tint.zsh"
elif grep -qs 'shell/tint\.zsh' "$HOME/.zshrc"; then
  echo "shell:  ~/.zshrc already sources tint.zsh"
else
  # Plain zsh, as on a new Mac: source the plugin from ~/.zshrc.
  printf '\n# ghostty-tint: window colors by folder\nsource "%s/shell/tint.zsh"\n' "$REPO" >>"$HOME/.zshrc"
  echo "shell:  added tint.zsh to ~/.zshrc (open a new window to pick it up)"
fi

CONFIG="$("$REPO/bin/tint" config-path)"
if [ "$("$REPO/bin/tint" seed-config)" = seeded ]; then
  echo "config: $CONFIG (one color per project folder in ~/code)"
else
  echo "config: $CONFIG (kept)"
fi

"$REPO/bin/tint" install-hooks
echo "hooks:  ~/.claude/settings.json (tint hook on Stop, Notification, prompts, session start/end, AskUserQuestion)"

PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
mkdir -p "$HOME/Library/LaunchAgents"
sed -e "s|@TINT@|$HOME/.local/bin/tint|g" -e "s|@PORT@|$PORT|g" -e "s|@HOME@|$HOME|g" \
    "$REPO/launchd/$LABEL.plist" >"$PLIST"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "ui:     http://127.0.0.1:$PORT (launchd keeps it running; log in ~/.cache/tint/serve.log)"
