# ghostty-tint shell plugin. Symlinked into ~/.oh-my-zsh/custom/ by install.sh,
# so oh-my-zsh sources it in every new shell.
#
# Before each prompt, recolor the window for $PWD when any of these changed:
#   - the directory (cd, worktree jump),
#   - the config file (saved from the web UI or by hand),
#   - a Claude Code event tinted this window (the state file exists), which
#     means Claude has exited or `clear` was typed and the folder color returns.
# Everything else is a single stat call, so prompts stay fast.

[[ $TERM_PROGRAM == ghostty ]] || return 0

# Claude Code and its hooks inherit this, so `tint hook` knows its window
# without walking the process tree.
export TINT_TTY=$TTY

typeset -g TINT_BIN=${TINT_BIN:-$HOME/.local/bin/tint}
typeset -g _tint_config=${TINT_CONFIG:-$HOME/.config/tint/config.json}
typeset -g _tint_state=${TINT_STATE_DIR:-$HOME/.cache/tint}/${TTY#/dev/}.json
typeset -g _tint_last_pwd='' _tint_last_mtime=''

zmodload zsh/stat 2>/dev/null

_tint_precmd() {
  local -a st
  zstat -A st +mtime -- "$_tint_config" 2>/dev/null
  if [[ $PWD != "$_tint_last_pwd" || ${st[1]:-0} != "$_tint_last_mtime" || -e $_tint_state ]]; then
    _tint_last_pwd=$PWD
    _tint_last_mtime=${st[1]:-0}
    [[ -x $TINT_BIN ]] && "$TINT_BIN" apply
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _tint_precmd
