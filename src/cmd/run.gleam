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
import gleam
import cmd/base.{Exec, Timing}

type Solution =
  #(Result(Int), Result(Int))

pub fn exec(timing: Timing) -> Exec(Solution) {
  Exec(do: do, collect: collect, timing: timing)
}

fn do(day: Day) -> Result(Solution) {
  try day_runner = select_day_runner(day)
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

type DayRunner =
  fn(String) -> Solution

fn select_day_runner(day: Int) -> Result(DayRunner) {
  try #(pt_1, pt_2) = case day {
    // 1 -> Ok(day_1.runners())
    // 2 -> Ok(day_2.runners())
    // 3 -> Ok(day_3.runners())
    _ ->
      Error(snag.new(string.append("unrecognized day: ", int.to_string(day))))
  }

  Ok(fn(input) { #(pt_1(input), pt_2(input)) })
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
        unpack_result(res_1),
        "\n  Part 2: ",
        unpack_result(res_2),
      ]
      |> string.concat()
    Error(err) -> snag.pretty_print(err)
  }
}

fn unpack_result(res: Result(Int)) -> String {
  case res {
    Ok(out) -> string.append("success, result: ", int.to_string(out))
    Error(err) ->
      err
      |> snag.layer("failure")
      |> snag.line_print()
  }
}
