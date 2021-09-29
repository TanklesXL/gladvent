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

pub fn do(day: String) -> Result(Nil) {
  try _ = parse.day(day)

  let input_path = string.concat(["input/day_", day, ".txt"])
  let gleam_src_path = string.concat(["src/days/day_", day, ".gleam"])

  try _ =
    file.open_file_exclusive(input_path)
    |> result.map_error(handle_file_open_failure(_, input_path))

  try _ =
    file.open_and_write_exclusive(gleam_src_path, gleam_starter)
    |> result.map_error(handle_file_open_failure(_, gleam_src_path))

  Ok(Nil)
}

const gleam_starter = "import snag.{Result}

pub fn pt_1(input: String) -> Result(Int) {
  Error(snag.new(\"unimplemented\"))
}

pub fn pt_2(input: String) -> Result(Int) {
  Error(snag.new(\"unimplemented\"))
}
"

fn handle_file_open_failure(reason: file.Reason, filename: String) -> Snag {
  case reason {
    file.Eexist -> file_already_exists_err(filename)
    _ -> failed_to_create_file_err(filename)
  }
}

fn file_already_exists_err(filename: String) -> Snag {
  filename
  |> snag.new()
  |> snag.layer("file already exists")
}

fn failed_to_create_file_err(filename: String) -> Snag {
  filename
  |> snag.new()
  |> snag.layer("failed to create file")
}

pub fn collect(x: #(Result(Nil), String)) -> String {
  let #(res, day) = x
  case res
  |> snag.context(string.append("failed to initialize day ", day))
  |> result.map_error(snag.pretty_print) {
    Ok(_) -> string.append("initialized day: ", day)
    Error(reason) -> reason
  }
}
