# aoc_template

A template for doing advent of code in gleam

This project is intended to be run as an `escript` & has 2 commands: `new` and `run`.

- `new`: used like `_build/default/bin/aoc_template new 1 2 ...` with day numbers * creates `input/day_*.txt` and `src/day_*.gleam`
- `run`: used like `_build/default/bin/aoc_template run 1 2 ...` with day numbers * runs and prints the output of running `day_*.gleam`

## Quick start

```sh
# Run the eunit tests
rebar3 eunit

# Run the Erlang REPL
rebar3 shell

# Build and run the escript
rebar3 escriptize
_build/default/bin/aoc_template
```
