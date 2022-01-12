import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import gleam/function
import snag.{Result, Snag}
import gleam/erlang/file
import ffi/time
import async
import parse.{Day}
import gleam/map.{Map}
import cmd.{Async, Sync, Timing}
import glint.{CommandInput}
import glint/flag

type Solution =
  #(Int, Int)

type DayRunner =
  fn(String) -> Solution

type RunnerMap =
  Map(Day, DayRunner)

fn do(day: Day, runners: RunnerMap) -> Result(Solution) {
  try day_runner =
    map.get(runners, day)
    |> result.replace_error(unrecognized_day_err(day))

  let input_path = string.join(["input/day_", int.to_string(day), ".txt"], "")

  input_path
  |> file.read()
  |> result.replace_error(failed_to_read_input_err(input_path))
  |> result.map(string.trim)
  |> result.map(day_runner)
}

fn unrecognized_day_err(day: Day) -> Snag {
  day
  |> int.to_string()
  |> string.append("unrecognized day: ", _)
  |> snag.new()
}

fn failed_to_read_input_err(input_path: String) -> Snag {
  input_path
  |> snag.new()
  |> snag.layer("failed to read input file")
}

fn collect(x: #(Result(Solution), Day)) -> String {
  let day = int.to_string(x.1)
  case x.0 {
    Ok(#(res_1, res_2)) ->
      [
        "Ran day ",
        day,
        ":",
        "\n  Part 1: ",
        int.to_string(res_1),
        "\n  Part 2: ",
        int.to_string(res_2),
      ]
      |> string.concat()
    Error(err) ->
      string.append("Error on day ", day)
      |> snag.layer(err, _)
      |> snag.pretty_print()
  }
}

fn exec(days: List(Day), timing: Timing, runners: RunnerMap) -> String {
  days
  |> cmd.exec(timing, do(_, runners), collect)
  |> string.join(with: "\n\n")
}

pub fn register_command(
  glint: glint.Command,
  runners: RunnerMap,
) -> glint.Command {
  glint.add_command(
    glint,
    ["run"],
    run(_, runners),
    [
      flag.int(called: "async", default: 0),
      flag.bool(called: "all", default: False),
    ],
  )
}

pub fn run(input: CommandInput, runners: RunnerMap) {
  let flag.IntFlag(timeout) =
    map.get(input.flags, "async")
    |> result.unwrap(flag.IntFlag(0))

  let timing = case timeout {
    0 -> Ok(Sync)
    _ if timeout < 0 -> Error(invalid_timeout_err(timeout))
    _ -> Ok(Async(timeout))
  }

  let flag.BoolFlag(all) =
    map.get(input.flags, "all")
    |> result.unwrap(flag.BoolFlag(False))

  let days = case all {
    True ->
      runners
      |> map.keys()
      |> list.sort(by: int.compare)
      |> Ok()

    False -> parse.days(input.args)
  }

  case days, timing {
    Ok(days), Ok(timing) -> exec(days, timing, runners)
    _, Error(err) -> snag.pretty_print(err)
    Error(err), _ -> failed_to_parse_err(err, input.args)
  }
  |> io.println()
}

fn invalid_timeout_err(timeout: Int) -> Snag {
  ["invalid timeout value ", "'", int.to_string(timeout), "'"]
  |> string.concat()
  |> snag.new()
  |> snag.layer("timeout must be greater than or equal to 1 ms")
  |> snag.layer("failed to run advent of code")
}

fn failed_to_parse_err(err: Snag, args: List(String)) -> String {
  err
  |> snag.layer(string.join(["failed to parse arguments", ..args], " "))
  |> snag.layer("failed to run advent of code")
  |> snag.pretty_print()
}
