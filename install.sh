#!/bin/bash
# Install ghostty-tint on this Mac. Safe to re-run.
#   1. ~/.local/bin/tint            -> bin/tint (symlink)
#   2. ~/.oh-my-zsh/custom/tint.zsh -> shell/tint.zsh (symlink)
#   3. ~/.config/tint/config.json    created from the old ghostty-repo-colors.zsh
#                                    mapping if missing (never overwritten)
#   4. ~/.claude/settings.json       hooks that call `tint hook`
#   5. ~/Library/LaunchAgents/com.nateschmidt.ghostty-tint.plist
#                                    keeps the web UI running on http://127.0.0.1:7337
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${TINT_PORT:-7337}"
LABEL=com.nateschmidt.ghostty-tint

mkdir -p "$HOME/.local/bin" "$HOME/.config/tint" "$HOME/.cache/tint"
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

if [ ! -f "$HOME/.config/tint/config.json" ]; then
  python3 - "$HOME/.config/tint/config.json" <<'PY'
import json, sys
folders = [
    {"name": "Condoit Tags", "pattern": "~/code/condoit-tags*", "bg": "#3d2410", "fg": "", "cursor": "", "palette": []},
    {"name": "InstaGift", "pattern": "~/code/instagift", "bg": "#2b5a75", "fg": "", "cursor": "", "palette": []},
    {"name": "Cape Town (iCloud)", "pattern": "~/Library/Mobile Documents/com~apple~CloudDocs/Claude/capetown", "bg": "#1e2a20", "fg": "", "cursor": "", "palette": []},
    {"name": "n8lb", "pattern": "~/code/n8lb*", "bg": "#2e58aa", "fg": "#f5f5f5", "cursor": "#3cc262", "palette": [
        "#1a1a1a", "#ef4444", "#3cc262", "#f59e0b", "#7aa2e8", "#c084fc", "#4dd0c4", "#d4d4d4",
        "#4a4a4a", "#f87171", "#5fd985", "#fbbf24", "#a8c4f0", "#d8b4fe", "#7ee7dc", "#ffffff"]},
    {"name": "Rulings", "pattern": "~/code/rulings*", "bg": "#a0404b", "fg": "", "cursor": "", "palette": []},
    {"name": "Cape Town", "pattern": "~/code/capetown-danish", "bg": "#073a25", "fg": "#f5e6b8", "cursor": "", "palette": []},
]
events = {
    "done": {"enabled": True, "bg": "#0f3d1f", "fg": ""},
    "needs_you": {"enabled": True, "bg": "#5c3a00", "fg": ""},
    "stopped": {"enabled": False, "bg": "#2a2a3a", "fg": ""},
    "idle": {"enabled": False, "bg": "#3a2a2a", "fg": ""},
}
json.dump({"version": 1, "folders": folders, "events": events}, open(sys.argv[1], "w"), indent=2)
PY
  echo "config: ~/.config/tint/config.json (seeded from the old folder mapping)"
else
  echo "config: ~/.config/tint/config.json (kept)"
fi

SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  python3 - "$SETTINGS" <<'PY'
import json, sys
path = sys.argv[1]
settings = json.load(open(path))
hooks = settings.setdefault("hooks", {})
cmd = '"$HOME/.local/bin/tint" hook'

def is_tint(entry):
    return any("tint" in (h.get("command") or "") for h in entry.get("hooks", []))

wanted = {
    "Stop": None, "Notification": None, "UserPromptSubmit": None,
    "SessionStart": None, "SessionEnd": None,
    "PreToolUse": "AskUserQuestion", "PostToolUse": "AskUserQuestion",
}
for event, entries in list(hooks.items()):
    hooks[event] = [e for e in entries if not is_tint(e)]
for event, matcher in wanted.items():
    entry = {"hooks": [{"type": "command", "command": cmd, "timeout": 10}]}
    if matcher:
        entry["matcher"] = matcher
    hooks.setdefault(event, []).append(entry)
hooks = {k: v for k, v in hooks.items() if v}
settings["hooks"] = hooks
json.dump(settings, open(path, "w"), indent=2)
open(path, "a").write("\n")
PY
  echo "hooks:  ~/.claude/settings.json (tint hook on Stop, Notification, prompts, session start/end, AskUserQuestion)"
fi

PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
mkdir -p "$HOME/Library/LaunchAgents"
sed -e "s|@TINT@|$HOME/.local/bin/tint|g" -e "s|@PORT@|$PORT|g" -e "s|@HOME@|$HOME|g" \
    "$REPO/launchd/$LABEL.plist" >"$PLIST"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "ui:     http://127.0.0.1:$PORT (launchd keeps it running; log in ~/.cache/tint/serve.log)"
