# Gladvent

[![Hex Package](https://img.shields.io/hexpm/v/gladvent?color=ffaff3&label=%F0%9F%93%A6)](https://hex.pm/packages/gladvent)
[![Hex.pm](https://img.shields.io/hexpm/dt/gladvent?color=ffaff3)](https://hex.pm/packages/gladvent)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3?label=%F0%9F%93%9A)](https://hexdocs.pm/gladvent/)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/tanklesxl/gladvent/main)](https://github.com/tanklesxl/gladvent/actions)

An Advent Of Code runner for Gleam

This library is intended to be imported to your gleam project and used as a command runner for your advent of code project in gleam.

To add this library to your project run: `gleam add gladvent` and add `import gladvent` to your main gleam file.

> [!IMPORTANT]
> This package works only on gleam's erlang target!

> [!NOTE]
> Due to changes made in gleam 1.5, users that were calling gladvent via `gleam run -m` should upgrade to v2 and add a call to `gladvent.run` in their project `main` function.

## Using the library

- Add gladvent as a dependency via `gleam add gladvent`
- Add `gladvent.run()` to your project's `main` function.

## Multi-year support

Gladvent now comes with out-of-the-box multi-year support via the `--year` flag when running it.

For convenience it defaults to the current year. Therefore, passing `--year=YEAR` to either the `run`, `run all` or `new` commands will use the year specified or the current year if the flag was not provided.

## Seeing help messages

- To see available subcommands: `gleam run -- --help`
- To see help for the `run` command: `gleam run run --help`
- To see help for the `run` command: `gleam run run all --help`
- To see help for the `new` command: `gleam run new --help`

## General Workflow

Where X is the day you'd like to add:

_Note:_ this method requires all day solutions be in `src/aoc_<year>/` with filenames `day_X.gleam`, each solution module containing `fn pt_1(String) -> Int` and a `fn pt_2(String) -> Int`

1. run `gleam run new X`
2. add your input to `input/<YEAR>/X.txt`
3. add your code to `src/aoc_<YEAR>/day_X.gleam`
4. run `gleam run run X`

### Available commands

This project provides your application with 2 command groups, `new` and `run`:

#### New

- `new`: create `src/aoc_<year>/day_<day>.gleam` and `input/<year>/<day>.txt` files that correspond to the specified days
  - format: `gleam run new a b c ...`

#### Run

The `run` command expects input files to be in the `input/<year>` directory, and code to be in `src/aoc_<year>/`
(corresponding to the files created by the `new` command).

- `run`: run the specified days
  - format: `gleam run run a b c ...`

- `run all`: run all registered days
  - format: `gleam run run all`

_Note:_

- any triggered `assert`, `panic` or `todo` will be captured and printed, for example:

```
Part 1: error: todo - unimplemented in module aoc_2024/day_1 in function pt_1 at line 2
```


## Reusable parse funtions

Gladvent supports modules with functions that provide a `pub fn parse(String) -> a` where the type `a` matches with the type of the argument for the runner functions `pt_1` and `pt_2`.
If this `parse` function is present, gladvent will pick it up and run it only once, providing the output to both runner functions.

An example of which looks like this:

```gleam
pub fn parse(input: String) -> Int {
    let assert Ok(i) = int.parse(input)
    i
}

pub fn pt_1(input: Int) -> Int {
    input + 1
}

pub fn pt_2(input: Int) -> Int {
    input + 2
}
```

_Note_: `gladvent` now leverages gleam's `export package-interface` functionality to type-check your `parse` and `pt_{1|2}` functions to make sure that they are compatible with each other.

## Defining expectations for easy refactoring

One of the most satisfying aspects of advent of code (for me), second only to that sweet feeling of first solving a problem, is *iteration and refactoring*.

Gladvent makes it easy for you to define expected outputs in your `gleam.toml` for all your solutions so that you can have the confidence to refactor your solutions as much as you want without having to constantly compare with your submissions on the advent of code website.

### Expectations in `gleam.toml`

Defining expectations is as simple as adding sections to your `gleam.toml` in the following format:

```toml
[gladvent.<year as int>.<day as int>]
pt_1 = <int or string>
pt_2 = <int or string>
```

For example, to set the expectations for Dec 1st 2024 (2024 day 1) you would add something like:

```toml
[gladvent.2024.1]
pt_1 = 1
pt_2 = 2
```

When running, gladvent will detect whether a specific day has it's expectations set and if so will print out the result for you.

Let's say that your computed solution for 2024 day 1 is actually 1 for pt\_1 and 3 for pt\_2, the output will look like this:

```
Ran 2024 day 1:
  Part 1: ✅ met expected value: 1
  Part 2: ❌ unmet expectation: got 3, expected 2
```

## Example inputs

Sometimes it's helpful to run advent of code solutions against example inputs to verify expectations.
Gladvent now provides a `--example` flag in both the `new` and `run` commands to conveniently support that workflow without needing to modify your actual problem input files.
Example input files will be generated at and run from `input/<year>/<day>.example.txt`.

_Note_: gladvent will not compare your solution output against the expectations defined in `gleam.toml` when running in example mode.

## FAQ

### Why did you make this?

It seemed fun, I like small command line utilities and I wanted a way to get advent of code done in gleam without having the additional overhead of lots of copy-pasting and connecting things to get it to run

### Why does this not download the input from the advent of code website?

A few reasons:

1. I wanted to keep this utility as simple as possible to start with
2. I like the advent of code website and I felt like it was a shame to circumvent visiting it, especially since you should access it to read the daily challenge. On top of that, I would like to avoid spamming the `advent of code` api if possible.

### Why run as a command line utility and not just use unit tests?

I thought a lot about that and I just prefer the overall interactivity of a CLI better, as well as allowing for endless runs or runs with configurable timeouts.
Having it run as part of `eunit` doesnt provide as much flexibility as I would like. Other testing frameworks have been popping up but I leave the decision to use them up to you!
