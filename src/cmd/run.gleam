import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import gleam/function
import snag.{Result}
import files
import time
import async
import parse

type DayRunner =
  fn(String) -> Result(#(Int, Int))

fn select_day_runner(day: Int) -> Result(DayRunner) {
  case day {
    // 1 -> day_1.run(input)
    // 2 -> day_2.run(input)
    // 3 -> day_3.run(input)
    _ ->
      Error(snag.new(string.append("unrecognized day: ", int.to_string(day))))
  }
}

pub fn exec(days: List(String), timeout: Int) -> List(String) {
  days
  |> async.list_map(run_day)
  |> iterator.from_list()
  |> async.iterator_try_await_many(timeout)
  |> iterator.map(result.flatten)
  |> iterator.zip(iterator.from_list(days), _)
  |> iterator.map(run_result_to_string)
  |> iterator.to_list()
}

fn run_result_to_string(day_res: #(String, Result(#(Int, Int)))) {
  let #(day, res) = day_res
  case res {
    Ok(#(pt_1, pt_2)) ->
      [
        "solved day ",
        day,
        "\n\t-> ",
        "part 1: ",
        int.to_string(pt_1),
        "\n\t-> part 2: ",
        int.to_string(pt_2),
      ]
      |> string.concat()
    Error(reason) ->
      reason
      |> snag.layer(string.append("failed to run day ", day))
      |> snag.pretty_print()
  }
}

fn run_day(day: String) -> Result(#(Int, Int)) {
  try day_runner =
    day
    |> parse.int()
    |> result.then(select_day_runner)

  let input_path = string.join(["input/day_", day, ".txt"], "")

  input_path
  |> files.read_file()
  |> result.replace_error(
    "failed to read input file: "
    |> string.append(input_path)
    |> snag.new(),
  )
  |> result.then(day_runner)
}
