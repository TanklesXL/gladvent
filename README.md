# Advent Of Code Gleam Template

A repository template for getting started with advent of code in gleam.

This template is intended to be forked, modified and run by the gleam build tool using `gleam run`.

It has 2 commands, `new` and `run`:

- `new`:
  - format: `gleam run new a b c ...`
  - used like `gleam run new 1 2` with days 1 and 2 creates `input/day_1.txt` and `input/day_2.txt` as well as `src/days/day_1.gleam` and `src/days/day_2.gleam`
- `run`:
  - format:
    - sync: `gleam run run a b c ...`
    - async: `gleam run run async {timeout in ms} a b c ...`
  - used like `gleam run run async 1000 1 2` with timeout 1000 milliseconds and days 1 and 2, runs and prints the output of running the `run` function of `day_1.gleam` and `day_2.gleam`

## General Workflow

1. run the `new` command with the desired day to set up the code stub and create the input file
2. copy-paste the input from the `advent of code` website for that day into the input file that was created
3. fill in your implementation for the day's problem in the `.gleam` file that was created
4. add a reference to your solution to the code handling the `run` command
5. compile your code and generate the escript
6. run your new solution and whatever other days you want with the `run` command

## Adding solutions and running them

### Adding your first 3 solutions

For the sake of convenience,   `advent_of_code.gleam` contains commented imports for `days/day_1`, `days/day_2` and `days/day_3` and commented uses for them in  `runners()`

Where `X` is the day number to create:

1. to create input/day_1.txt and src/days/day_1.gleam, run `gleam run new X`
2. add your input and solution to the created files
3. uncomment `import days/day_X` in `advent_of_code.gleam`
4. uncomment  `// X -> Ok(day_X.run)` in `runners()`
5. to run day_x, run `gleam run run X`

### Adding subsequent solutions

Where `X` is the day number to create:

It should be fairly obvious here,

1. follow steps 1-2 above
1. add `import days/day_X` to `advent_of_code.gleam`
2. add  `X -> Ok(day_X.run)` in `runners()`
3. follow step 5 above

## FAQ

### Why did you make this?

It seemed fun, I like small command line utilities and I wanted a way to get advent of code done in gleam without having the additional overhead of lots of copy-pasting and connecting things to get it to run

### Why does this not download the input from the advent of code website?

A few reasons:

1. I wanted to keep this utility as simple as possible to start with
2. I like the advent of code website and I felt like it was a shame to circumvent visiting it, especially since you should access it to read the daily challenge. On top of that, I would like to avoid spamming the `advent of code` api if possible.

### Why run as a command line utility and not just use unit tests?

I thought a lot about that and I prefer the overally interactivity of a CLI better, as well as allowing for endless runs or runs with configurable timeouts. Having it run as part of `eunit` doesnt provide as much flexibility as I would like.
