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
import cli.{CommandInput}
import cli/flag

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

pub fn register_command(cli: cli.Command, runners: RunnerMap) -> cli.Command {
  cli.add_command(
    cli,
    ["run"],
    run(_, runners),
    [flag.int(called: "async", default: 0)],
  )
}

pub fn run(input: CommandInput, runners: RunnerMap) {
  let flag.IntFlag(timeout) =
    map.get(input.flags, "async")
    |> result.unwrap(flag.IntFlag(0))

  case parse.days(input.args), timeout {
    Ok(days), 0 ->
      string.append("running synchronously\n", exec(days, Sync, runners))
    Ok(_), _ if timeout < 0 -> invalid_timeout_err(timeout)
    Ok(days), _ ->
      [
        "running asynchronously with timeout of ",
        int.to_string(timeout),
        "ms \n",
        exec(days, Async(timeout), runners),
      ]
      |> string.concat()

    Error(err), _ -> failed_to_parse_err(err, input.args)
  }
  |> io.println()
}

fn invalid_timeout_err(timeout: Int) -> String {
  ["invalid timeout value ", "'", int.to_string(timeout), "'"]
  |> string.concat()
  |> snag.new()
  |> snag.layer("timeout must be greater than or equal to 1 ms")
  |> failed_to_run()
}

fn failed_to_parse_err(err: Snag, args: List(String)) -> String {
  err
  |> snag.layer(string.join(["failed to parse arguments", ..args], " "))
  |> failed_to_run()
}

fn failed_to_run(err: Snag) -> String {
  err
  |> snag.layer("failed to run advent of code")
  |> snag.pretty_print()
}
