# Gladvent

[![Hex Package](https://img.shields.io/hexpm/v/gladvent?color=ffaff3&label=%F0%9F%93%A6)](https://hex.pm/packages/gladvent)
[![Hex.pm](https://img.shields.io/hexpm/dt/gladvent?color=ffaff3)](https://hex.pm/packages/gladvent)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3?label=%F0%9F%93%9A)](https://hexdocs.pm/gladvent/)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/tanklesxl/gladvent/main)](https://github.com/tanklesxl/gladvent/actions)

An Advent Of Code runner for Gleam

This library is intended to be imported to your gleam project and used as a command runner for your advent of code project in gleam.

To add this library to your project run: `gleam add gladvent` and add `import gladvent` to your main gleam file.

## Using the library

This library provides 3 options to run your advent of code solvers:

1. The easiest way: call it via `gleam run -m gladvent [ARGS]`, not requiring a custom `main()` function.
1. The easy way: simply add `gladvent.main()` to the end of your project's `main` function.

## Multi-year support

Gladvent now comes with out-of-the-box multi-year support via the `--year` flag when running it. For convenience it defaults to the current year. Therefore, passing the `--year=YEAR`flag to either the`run`, `run all`or`new` commands will use the year specified or the current year if the flag was not provided.

## Available commands

This project provides your application with 2 commands, `new` and `run`:

- `new`: create `src/days/*.gleam` and `input/*.txt` files that correspond to the specified days
  - format: `gleam run new a b c ...`
  - used like `gleam run new 1 2` with days 1 and 2 creates `input/day_1.txt` and `input/day_2.txt` as well as `src/days/day_1.gleam` and `src/days/day_2.gleam`
- `run`: run the specified days

  - format: `gleam run run a b c ...`
  - flags:
    - `--timeout`: `gleam run run --timeout={timeout in ms} a b c ...`
      - usage example: `gleam run run --timeout=1000 1 2` with timeout 1000 milliseconds and days 1 and 2, runs and prints the output of running the `run` function of `day_1.gleam` and `day_2.gleam`
    - `--allow-crash`: runs days without the use of `rescue` functionality, rendering output text more verbose but also allowing for stacktraces to be printed
      - usage example: `gleam run run 1 2 3 --allow-crash`

- `run all`: run all registered days
  - format: `gleam run run all`
  - flags:
    - `--timeout`: `gleam run run all --timeout={timeout in ms}`
      - usage example: `gleam run run --timeout=1000 1 2` with timeout 1000 milliseconds and days 1 and 2, runs and prints the output of running the `run` function of `day_1.gleam` and `day_2.gleam`
    - `--allow-crash`: runs days without the use of `rescue` functionality, rendering output text more verbose but also allowing for stacktraces to be printed
      - usage example: `gleam run run all --allow-crash`

_Note:_

- the `new` command creates source files in `src/aoc_<YEAR>/` and input files in the `input/<YEAR>` directory.
- the `run` command expects input files to be in the `input/<YEAR>` directory, and code to be in `src/aoc_<YEAR>/`
- any triggered `assert` will be captured and printed, for example: `error: assert - Assertion pattern match failed in module days/day_1 in function pt_1 at line 2 with value 2`
- any message in a `todo` will be captured and printed, for example: `error: todo - test in module days/day_1 in function pt_2 at line 7`

## Seeing help messages

- To see available subcommands: `gleam run -- --help`
- To see help for the `run` command: `gleam run run --help`
- To see help for the `run` command: `gleam run run all --help`
- To see help for the `new` command: `gleam run new --help`

## General Workflow

Where X is the day you'd like to add (when using `gladvent.main()`):

_Note:_ this method requires all day solutions be in `src/days/` with filenames `day_X.gleam`, each solution module containing `fn pt_1(String) -> Int` and a `fn pt_2(String) -> Int`

1. run `gleam run -m gladvent run new X`
2. add your input to `input/<YEAR>/day_X.txt`
3. add your code to `src/aoc_<YEAR>/day_X.gleam`
4. run `gleam run -m gladvent run X`

## FAQ

### Why did you make this?

It seemed fun, I like small command line utilities and I wanted a way to get advent of code done in gleam without having the additional overhead of lots of copy-pasting and connecting things to get it to run

### Why does this not download the input from the advent of code website?

A few reasons:

1. I wanted to keep this utility as simple as possible to start with
2. I like the advent of code website and I felt like it was a shame to circumvent visiting it, especially since you should access it to read the daily challenge. On top of that, I would like to avoid spamming the `advent of code` api if possible.

### Why run as a command line utility and not just use unit tests?

I thought a lot about that and I prefer the overall interactivity of a CLI better, as well as allowing for endless runs or runs with configurable timeouts. Having it run as part of `eunit` doesnt provide as much flexibility as I would like.
