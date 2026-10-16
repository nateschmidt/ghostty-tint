#!/bin/bash
# Install ghostty-tint on this Mac. Safe to re-run.
#   1. ~/.local/bin/tint            -> bin/tint (symlink)
#   2. ~/.oh-my-zsh/custom/tint.zsh -> shell/tint.zsh (symlink)
#   3. ~/.config/tint/config.json    created from the old ghostty-repo-colors.zsh
#                                    mapping if missing (never overwritten)
#   4. ~/.claude/settings.json       hooks that call `tint hook` (tint install-hooks)
#   5. ~/Library/LaunchAgents/com.nateschmidt.ghostty-tint.plist
#                                    keeps the web UI running on http://127.0.0.1:7337
set -euo pipefail
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
else
  echo "shell:  oh-my-zsh not found; add 'source $REPO/shell/tint.zsh' to ~/.zshrc" >&2
fi

CONFIG="$("$REPO/bin/tint" config-path)"
mkdir -p "$(dirname "$CONFIG")"
if [ ! -f "$CONFIG" ]; then
  # Seed from the old ghostty-repo-colors.zsh mapping. Event colors come from
  # the defaults in bin/tint; the UI fills in the rest.
  cat >"$CONFIG" <<'JSON'
{
  "version": 1,
  "folders": [
    {"name": "Condoit Tags", "pattern": "~/code/condoit-tags*", "bg": "#3d2410"},
    {"name": "InstaGift", "pattern": "~/code/instagift", "bg": "#2b5a75"},
    {"name": "Cape Town (iCloud)", "pattern": "~/Library/Mobile Documents/com~apple~CloudDocs/Claude/capetown", "bg": "#1e2a20"},
    {"name": "n8lb", "pattern": "~/code/n8lb*", "bg": "#2e58aa", "fg": "#f5f5f5", "cursor": "#3cc262", "palette": [
      "#1a1a1a", "#ef4444", "#3cc262", "#f59e0b", "#7aa2e8", "#c084fc", "#4dd0c4", "#d4d4d4",
      "#4a4a4a", "#f87171", "#5fd985", "#fbbf24", "#a8c4f0", "#d8b4fe", "#7ee7dc", "#ffffff"]},
    {"name": "Rulings", "pattern": "~/code/rulings*", "bg": "#a0404b"},
    {"name": "Cape Town", "pattern": "~/code/capetown-danish", "bg": "#073a25", "fg": "#f5e6b8"}
  ]
}
JSON
  echo "config: $CONFIG (seeded from the old folder mapping)"
else
  echo "config: $CONFIG (kept)"
fi

if [ -f "$HOME/.claude/settings.json" ]; then
  "$REPO/bin/tint" install-hooks
  echo "hooks:  ~/.claude/settings.json (tint hook on Stop, Notification, prompts, session start/end, AskUserQuestion)"
fi

PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
mkdir -p "$HOME/Library/LaunchAgents"
sed -e "s|@TINT@|$HOME/.local/bin/tint|g" -e "s|@PORT@|$PORT|g" -e "s|@HOME@|$HOME|g" \
    "$REPO/launchd/$LABEL.plist" >"$PLIST"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "ui:     http://127.0.0.1:$PORT (launchd keeps it running; log in ~/.cache/tint/serve.log)"
