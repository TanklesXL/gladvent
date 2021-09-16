# aoc_template

A template for getting started with advent of code in gleam

This project is intended to be forked, modified and run as an `escript`
It has 2 commands: `new` and `run`.

- `new`: used like `_build/default/bin/aoc_template new 1 2` with day \* 1 2 ... creates `input/day_*.txt` and `src/days/day_*.gleam`
- `run`: used like `_build/default/bin/aoc_template run 1000 1 2` with timeout 1000 milliseconds and day \* 1 2 ... runs and prints the output of running `day_*.gleam`

*note:* the first argument of each command is the total run time allowed for the entirety of the command execution, in milliseconds.

## Quick start

```sh
# Run the eunit tests
rebar3 eunit
# Run the Erlang REPL
rebar3 shell
# Build the escript
rebar3 escriptize
```

## Adding solutions and running them

### Adding your first 3 solutions

For the sake of convenience,   `cmd/run.gleam` contains commented imports for `days/day_1`, `days/day_2` and `days/day_3` and commented uses for them in  `select_day_runner`

Where `x` is the day number to create:

1. to create input/day_1.txt and src/days/day_1.gleam, run `_build/default/bin/aoc_template new X`
2. add your input and solution to the created files
3. uncomment `import days/day_x` in `cmd/run.gleam`
4. uncomment  `// 1 -> day_1.run(input)` in `select_day_runner`
5. to run day_x, allowing a max 1 second time run time, run `_build/default/bin/aoc_template run 1000 x`

### Adding subsequent solutions

Where `x` is the day number to create:

It should be fairly obvious here,

1. follow steps 1-2 above
1. add `import days/day_x` to `cmd/run.gleam`
1. add  `x -> day_x.run(input)` in `select_day_runner`
1. follow step 5 above
