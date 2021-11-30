// import days/day_1
// import days/day_2
// import days/day_3
import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import gleam/function
import snag.{Result}
import ffi/file
import ffi/time
import async
import parse.{Day}
import gleam/map.{Map}
import cmd.{Exec, Timing}

type Solution =
  #(Int, Int)

type DayRunner =
  fn(String) -> Solution

pub fn exec(timing: Timing, runners: Map(Day, DayRunner)) -> Exec(Solution) {
  Exec(do: do(_, runners), collect: collect, timing: timing)
}

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
    |> file.read_file()
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
