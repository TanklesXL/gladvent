import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import snag.{Result, Snag}
import ffi/file
import ffi/time
import async
import parse
import gleam/erlang/charlist

pub fn do(day: String) -> Result(Int) {
  try day_num = parse.int(day)

  let input_path = string.concat(["input/day_", day, ".txt"])
  let gleam_src_path = string.concat(["src/days/day_", day, ".gleam"])

  try _ =
    file.open_file(input_path)
    |> result.replace_error(failed_to_create_file_err(input_path))

  try _ =
    file.open_and_write(gleam_src_path, gleam_starter)
    |> result.replace_error(failed_to_write_file_err(gleam_src_path))

  Ok(day_num)
}

const gleam_starter = "import snag.{Result}

pub fn run(input: String) -> Result(#(Int, Int)) {
  try pt_1 =
    input
    |> pt_1()
    |> snag.context(\"failed part 1\")

  try pt_2 =
    input
    |> pt_2()
    |> snag.context(\"failed part 2\")

  Ok(#(pt_1, pt_2))
}

fn pt_1(input: String) -> Result(Int) {
  todo
}

fn pt_2(input: String) -> Result(Int) {
  todo
}
"

fn failed_to_create_file_err(s: String) -> Snag {
  s
  |> string.append("failed to create file: ", _)
  |> snag.new()
}

fn failed_to_write_file_err(s: String) -> Snag {
  s
  |> string.append("failed to write file: ", _)
  |> snag.new()
}

pub fn collect(x: #(Result(Int), String)) -> String {
  let #(res, day) = x
  case res
  |> snag.context(string.append("failed to initialize day ", day))
  |> result.map_error(snag.pretty_print) {
    Ok(_) -> string.append("initialized day: ", day)
    Error(reason) -> reason
  }
}
