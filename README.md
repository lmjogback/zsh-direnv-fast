# zsh-direnv-fast

A faster [direnv](https://direnv.net/) hook for Zsh.

direnv's standard hook runs `direnv export zsh` before every prompt. That is a
fork and exec of a Go binary, typically a few milliseconds, on every command.
`zsh-direnv-fast` checks the modification times of the files direnv depends on
and runs direnv only when one of them has changed:

- the nearest `.envrc` in the current directory or its parents,
- direnv's `allow` and `deny` directories,
- `direnv.toml` and `config.toml` in direnv's configuration directory.

It also runs direnv after you leave a directory with a loaded environment, so
the environment is unloaded as usual, and after every command line that
contains `direnv` (e.g. `direnv allow`), because modification times have only
one-second resolution.

The approach is adapted from the direnv integration in
[zsh4humans](https://github.com/romkatv/zsh4humans).

## Installation

Requires `direnv` on `$PATH`; tested with Zsh 5.9 and direnv 2.32. Use this
plugin instead of `eval "$(direnv hook zsh)"` or a framework's direnv plugin,
not in addition to it.

With zinit:

```zsh
zinit light lmjogback/zsh-direnv-fast
```

Or source `zsh-direnv-fast.plugin.zsh` directly.

## Limitations

Changes to files that direnv watches but this plugin does not take effect the
next time you change directory or run `direnv reload`. This includes files
added with `watch_file`, files used by `use flake`, `dotenv` and `.env`, and a
parent `.envrc` loaded with `source_up`.

## Tests

```sh
./tests/run.sh
```

The tests need `zsh` and `direnv`, and use a temporary directory for direnv's
data and configuration.

## License

MIT. See [LICENSE](LICENSE).
