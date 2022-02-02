# Gladvent

An Advent Of Code runner for Gleam

This library is intended to be imported to your gleam project and used as a command runner for your advent of code project in gleam.

To add this library to your project run: `gleam add gladvent` and add `import gladvent` to your main gleam file.

## Using the library

This library provides 2 options to run your advent of code solvers:

1. The easy way: simply add `gladvent.main()` to the end of your project's `main` function.
2. Create your own `Map(Int, fn(String) -> #(Int, Int))` and pass it to `gladvent.execute`

## Available commands

This project provides your application with 2 commands, `new` and `run`:

- `new`: create `.gleam` and `.txt` days that correspond to the specified days
  - format: `gleam run new a b c ...`
  - used like `gleam run new 1 2` with days 1 and 2 creates `input/day_1.txt` and `input/day_2.txt` as well as `src/days/day_1.gleam` and `src/days/day_2.gleam`
- `run`: run the specified days
  - format: `gleam run run a b c ...`
  - flags:
    - `--timeout`: `gleam run run --timeout={timeout in ms} a b c ...`
      - usage example: `gleam run run --timeout=1000 1 2` with timeout 1000 milliseconds and days 1 and 2, runs and prints the output of running the `run` function of `day_1.gleam` and `day_2.gleam`
    - `--all`: runs all registered days in ascending numerical order..
      - usage example: `gleam run run --all=true` or  `gleam run run --timeout=1000 --all=true`

## General Workflow

Where X is the day you'd like to add (when using `gladvent.main()`):

1. run `gleam run new X`
2. add your input to `input/day_X.txt`
3. add your code to `src/days/day_X.gleam`
4. run `gleam run run X`

## FAQ

### Why did you make this?

It seemed fun, I like small command line utilities and I wanted a way to get advent of code done in gleam without having the additional overhead of lots of copy-pasting and connecting things to get it to run

### Why does this not download the input from the advent of code website?

A few reasons:

1. I wanted to keep this utility as simple as possible to start with
2. I like the advent of code website and I felt like it was a shame to circumvent visiting it, especially since you should access it to read the daily challenge. On top of that, I would like to avoid spamming the `advent of code` api if possible.

### Why run as a command line utility and not just use unit tests?

I thought a lot about that and I prefer the overall interactivity of a CLI better, as well as allowing for endless runs or runs with configurable timeouts. Having it run as part of `eunit` doesnt provide as much flexibility as I would like.
