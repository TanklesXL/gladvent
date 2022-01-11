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

type Solution =
  #(Int, Int)

type DayRunner =
  fn(String) -> Solution

fn do(day: Day, runners: Map(Day, DayRunner)) -> Result(Solution) {
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

fn exec(days: List(Day), timing: Timing, runners: Map(Day, DayRunner)) -> String {
  days
  |> cmd.exec(timing, do(_, runners), collect)
  |> string.join(with: "\n\n")
}

pub fn run(l: List(String), runners: Map(Day, DayRunner)) {
  case parse.days(l) {
    Ok(days) -> exec(days, Sync, runners)
    Error(err) -> failed_to_run(err, l)
  }
  |> io.println()
}

pub fn run_async(l: List(String), runners: Map(Day, DayRunner)) {
  case parse.timeout_and_days(l) {
    Ok(#(timeout, days)) -> exec(days, Async(timeout), runners)
    Error(err) -> failed_to_run(err, l)
  }
  |> io.println()
}

pub fn failed_to_run(err: Snag, args: List(String)) -> String {
  err
  |> snag.layer(string.join(["failed to parse arguments", ..args], " "))
  |> snag.layer("failed to run advent of code")
  |> snag.pretty_print()
}
