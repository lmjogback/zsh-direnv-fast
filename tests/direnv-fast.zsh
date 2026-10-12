#!/usr/bin/env zsh

set -eu

# Keep direnv's allow list and configuration away from the user's own.
tmp=$(mktemp -d)
trap 'rm -rf -- $tmp' EXIT
export XDG_DATA_HOME=$tmp/data XDG_CONFIG_HOME=$tmp/config XDG_CACHE_HOME=$tmp/cache
unset DIRENV_DIR DIRENV_DIFF DIRENV_FILE DIRENV_WATCHES FOO

# Count direnv invocations. The hook runs direnv in a command substitution,
# so the count goes through a file.
calls=$tmp/calls
: >$calls
direnv() { print >>$calls; command direnv "$@" }

source "${0:A:h}/../zsh-direnv-fast.plugin.zsh"

typeset -gi tests=0 failed=0

# Run the hooks as zsh would around a command line.
prompt() { _direnv_fast_hook 2>/dev/null || true }
run() { _direnv_fast_preexec "$*"; eval "$*" >/dev/null 2>&1 || true; prompt }
cdir() { cd -- $1; prompt; prompt }

check() {
  local name=$1 expected=$2
  (( ++tests ))
  if [[ ${FOO-<unset>} != $expected ]]; then
    print -u2 -- "FAIL: $name: expected FOO=$expected, got FOO=${FOO-<unset>}"
    (( ++failed ))
  fi
}

check_calls() {
  local name=$1 expected=$2 actual
  actual=$(wc -l <$calls)
  (( ++tests ))
  if (( actual != expected )); then
    print -u2 -- "FAIL: $name: expected $expected direnv calls, got $actual"
    (( ++failed ))
  fi
  : >$calls
}

mkdir -p $tmp/proj/sub $tmp/other
cdir $tmp/other
check 'no .envrc' '<unset>'
check_calls 'no .envrc' 0

cdir $tmp/proj
print 'export FOO=one' >.envrc
prompt
check 'new .envrc is blocked' '<unset>'

run direnv allow .
check 'direnv allow loads immediately' one
: >$calls

prompt
prompt
check 'unchanged' one
check_calls 'unchanged' 0

# mtimes have one-second resolution.
sleep 1.1
print 'export FOO=two' >.envrc
prompt
check 'edited .envrc is blocked and unloads' '<unset>'

run direnv allow .
check 'edited .envrc allowed' two

cdir sub
check 'subdirectory' two

cdir $tmp/other
check 'leaving unloads' '<unset>'
: >$calls
prompt
check_calls 'outside after unload' 0

cdir $tmp/proj
check 'returning loads' two

run direnv deny .
check 'direnv deny unloads' '<unset>'

: >$calls
run 'echo direnvx'
check_calls 'unrelated command' 0

print -- "$tests tests, $failed failed"
(( failed == 0 ))
