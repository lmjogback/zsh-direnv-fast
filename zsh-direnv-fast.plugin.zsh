# zsh-direnv-fast: run `direnv export` only when something it depends on changed.
# Adapted from zsh4humans' -z4h-direnv-hook (MIT, Copyright (c) 2020 Roman Perepelitsa).

(( $+commands[direnv] )) || return
zmodload -F zsh/stat b:zstat || return

typeset -g _direnv_fast_sig

_direnv_fast_hook() {
  emulate -L zsh -o extended_glob

  local sig
  local -a envrc=( ./(../)#.envrc(NY1:a) )
  if (( $#envrc )); then
    local -a deps=( ${XDG_DATA_HOME:-~/.local/share}/direnv/{allow,deny}
                    ${XDG_CONFIG_HOME:-~/.config}/direnv/{direnv.toml,config.toml} )
    local -a files=( $^deps(N) ) stat
    if zstat -A stat +mtime -- $envrc $files 2>/dev/null; then
      sig=$envrc$'\0'${(pj:\0:)stat}
    else
      sig=stat-error
    fi
  elif [[ ! -v DIRENV_WATCHES ]]; then
    _direnv_fast_sig=none
    return
  else
    sig=none
  fi

  [[ $sig == $_direnv_fast_sig ]] && return

  # Evaluate the output even on failure: a blocked .envrc must still unload.
  local out
  out=$(direnv export zsh)
  trap -- '' INT
  eval -- $out
  trap - INT
  _direnv_fast_sig=$sig
}

# mtimes have one-second resolution, so `direnv allow` right after the
# prompt could go unnoticed. Always re-check after a direnv command.
_direnv_fast_preexec() {
  local -a words=( ${(z)1} )
  if (( ${words[(Ie)direnv]} )); then
    _direnv_fast_sig=
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _direnv_fast_preexec
add-zsh-hook precmd _direnv_fast_hook
add-zsh-hook chpwd  _direnv_fast_hook
