# ghostty-tint

Ghostty window colors by folder, and by what Claude Code is doing in that
window, managed from a small local web page instead of by editing shell files.

Open the page at <http://127.0.0.1:7337> (a launch agent keeps it running), or
run `tint ui`.

## What it does

- **Folders.** Each rule maps a folder pattern (`~/code/instagift`,
  `~/code/n8lb*`) to a background color, and optionally a text color, a cursor
  color, and a full 16-color palette. The longest matching pattern wins, and a
  pattern covers everything under it. The shell recolors the window before
  each prompt whenever the directory or the config changed.
- **Events.** Claude Code hooks recolor the window when something happens in
  it: the turn ended on the /issue sign-off ("Finished"), Claude needs you
  ("Needs you": a Nate Needs To Do This callout, an AskUserQuestion, a
  permission prompt, or "Waiting on Nate."), the turn ended with nothing to
  flag ("Turn ended"), or Claude has been waiting on you for over a minute
  ("Idle a while"). Each event has an on/off switch and a color.
- **Back to the folder color** on your next message, on `/clear`, when the
  Claude session ends, and at the next shell prompt. The reset re-applies the
  folder rule rather than Ghostty's default, which is the bug the old hook had.
- **Open windows.** The page lists every Ghostty window with its folder and
  current state, previews color edits live on the windows that are in that
  folder, and has a Try button to flash an event color on a chosen window.

Everything is sent as OSC escape sequences to one tty, so only that window
changes and Ghostty's own config is untouched.

## Layout

| Path | Purpose |
| --- | --- |
| `bin/tint` | The CLI and hook entry point, plus the web server (Python 3, no dependencies). |
| `shell/tint.zsh` | oh-my-zsh custom plugin: a precmd hook that calls `tint apply` when needed. |
| `ui/index.html` | The web page, vanilla HTML/JS, served by `tint serve`. |
| `install.sh` | Symlinks, seeds the config, wires the Claude Code hooks, loads the launch agent. Safe to re-run. |
| `launchd/` | Template for the launch agent that keeps the UI running. |

State on this Mac:

| Path | Purpose |
| --- | --- |
| `~/.config/tint/config.json` | The folder rules and event colors. The UI edits this file. |
| `~/.cache/tint/<tty>.json` | Which event a window is currently showing, if any. |
| `~/.cache/tint/serve.log` | Web server log. |
| `~/.claude/settings.json` | The hooks (`"$HOME/.local/bin/tint" hook` on Stop, Notification, UserPromptSubmit, SessionStart, SessionEnd, and AskUserQuestion). |

## CLI

```
tint apply [DIR]        recolor this window for DIR (default: cwd); clears any event tint
tint reset              recolor this window for the shell's current folder
tint event NAME         apply the configured color for done | needs_you | stopped | idle
tint hook               Claude Code hook entry point (reads the hook JSON on stdin)
tint windows            list open Ghostty windows with folder and state
tint apply-all [--force]  recolor every open window (skips windows showing an event unless --force)
tint serve [--port N]   run the web UI in the foreground
tint ui                 open the web UI (starts the server if it is not running)
tint config-path        print the config file path
```

Every command exits 0 and stays silent on failure, because a hook must never
break a Claude Code session.

## Install

```
git clone git@github.com:nateschmidt/ghostty-tint.git ~/code/ghostty-tint
~/code/ghostty-tint/install.sh
```

Re-run `install.sh` after pulling changes that touch the hooks or the launch
agent. Code changes to `bin/tint` and `ui/index.html` take effect on the next
call; restart the UI server with
`launchctl kickstart -k gui/$(id -u)/com.nateschmidt.ghostty-tint`.

## Writing style

No em dashes or en dashes anywhere in this repo: UI copy, docs, commit
messages, code comments. Use a comma, colon, parentheses, or two sentences.
