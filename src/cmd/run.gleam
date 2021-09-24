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
import parse

type DayRunner =
  fn(String) -> Result(#(Int, Int))

fn select_day_runner(day: Int) -> Result(DayRunner) {
  case day {
    // 1 -> Ok(day_1.run)
    // 2 -> Ok(day_2.run)
    // 3 -> Ok(day_3.run)
    _ ->
      Error(snag.new(string.append("unrecognized day: ", int.to_string(day))))
  }
}

pub fn do(day: String) -> Result(#(Int, Int)) {
  try day_runner =
    day
    |> parse.day()
    |> result.then(select_day_runner)

  let input_path = string.join(["input/day_", day, ".txt"], "")

  input_path
  |> file.read_file()
  |> result.replace_error(
    input_path
    |> snag.new()
    |> snag.layer("failed to read input file"),
  )
  |> result.then(day_runner)
}

pub fn collect(day_res: #(Result(#(Int, Int)), String)) -> String {
  let #(res, day) = day_res
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
