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
import cmd

type Solution =
  #(Int, Int)

type DayRunner =
  fn(String) -> Solution

fn do(day: Day, runners: Map(Day, DayRunner)) -> Result(Solution) {
  try day_runner =
    map.get(runners, day)
    |> result.replace_error(snag.new(string.append(
      "unrecognized day: ",
      int.to_string(day),
    )))

  let input_path = string.join(["input/day_", int.to_string(day), ".txt"], "")

  try input =
    input_path
    |> file.read()
    |> result.replace_error(
      snag.new(input_path)
      |> snag.layer("failed to read input file"),
    )

  Ok(day_runner(input))
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

pub fn run(l: List(String), runners: Map(Day, DayRunner)) {
  case parse.days(l) {
    Ok([]) -> cmd.no_days_selected_err()
    Ok(days) ->
      days
      |> cmd.exec(cmd.Sync, do(_, runners), collect)
      |> string.join(with: "\n\n")
    Error(err) -> failed_to_run(err, l)
  }
  |> io.println()
}

pub fn run_async(l: List(String), runners: Map(Day, DayRunner)) {
  case parse.timeout_and_days(l) {
    Ok(#(_, [])) -> cmd.no_days_selected_err()
    Ok(#(timeout, days)) ->
      days
      |> cmd.exec(cmd.Async(timeout), do(_, runners), collect)
      |> string.join(with: "\n\n")
    Error(err) -> failed_to_run(err, l)
  }
  |> io.println()
}

pub fn failed_to_run(err: Snag, args: List(String)) -> String {
  err
  |> snag.layer(string.join(["failed to parse arguments:", ..args], " "))
  |> snag.layer("failed to run advent of code")
  |> snag.pretty_print()
}
