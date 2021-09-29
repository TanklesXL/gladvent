# Advent Of Code Gleam Template

A repository template for getting started with advent of code in gleam

This project is intended to be forked, modified and run as an `escript`

It has 2 commands, `new` and `run`:

- `new`:
  - format: `_build/default/bin/advent_of_code new a b c ...`
  - used like `_build/default/bin/advent_of_code new 1 2` with days 1 and 2 creates `input/day_1.txt` and `input/day_2.txt` as well as `src/days/day_1.gleam` and `src/days/day_2.gleam`
- `run`:
  - format:
    - sync: `_build/default/bin/advent_of_code run a b c ...`
    - async: `_build/default/bin/advent_of_code run async {timeout in ms} a b c ...`
  - used like `_build/default/bin/advent_of_code run async 1000 1 2` with timeout 1000 milliseconds and days 1 and 2, runs and prints the output of running the `run` function of `day_1.gleam` and `day_2.gleam`

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

Where `X` is the day number to create:

1. to create input/day_1.txt and src/days/day_1.gleam, run `_build/default/bin/advent_of_code new X`
2. add your input and solution to the created files
3. uncomment `import days/day_X` in `cmd/run.gleam`
4. uncomment  `// X -> Ok(#(day_X.pt_1, day_X.pt_2))` in `select_day_runner`
5. to run day_x, run `_build/default/bin/advent_of_code run X`

### Adding subsequent solutions

Where `X` is the day number to create:

It should be fairly obvious here,

1. follow steps 1-2 above
1. add `import days/day_X` to `cmd/run.gleam`
1. add  `X -> Ok(#(day_X.pt_1, day_X.pt_2))` in `select_day_runner`
1. follow step 5 above
