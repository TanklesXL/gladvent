import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import snag.{Result, Snag}
import ffi/file
import parse.{Day}
import gleam/erlang/charlist
import gleam/erlang/file as efile
import cmd
import glint.{CommandInput}

const input_dir = "input/"

fn input_path(day: Day) -> String {
  string.concat([input_dir, "day_", int.to_string(day), ".txt"])
}

const days_dir = "src/days/"

fn gleam_src_path(day: Day) -> String {
  string.concat([days_dir, "day_", int.to_string(day), ".gleam"])
}

fn do(day: Day) -> Result(Nil) {
  try _ = case efile.make_directory(input_dir) {
    Ok(_) | Error(efile.Eexist) -> Ok(Nil)
    _ -> Error(failed_to_create_dir_err(input_dir))
  }

  try _ = case efile.make_directory(days_dir) {
    Ok(_) | Error(efile.Eexist) -> Ok(Nil)
    _ -> Error(failed_to_create_dir_err(days_dir))
  }

  let input_path = input_path(day)

  try _ =
    file.open_file_exclusive(input_path)
    |> result.map_error(handle_file_open_failure(_, input_path))

  let gleam_src_path = gleam_src_path(day)

  try _ =
    file.open_and_write_exclusive(gleam_src_path, gleam_starter)
    |> result.map_error(handle_file_open_failure(_, gleam_src_path))

  Ok(Nil)
}

const gleam_starter = "pub fn run(input) {
  #(pt_1(input), pt_2(input))
}

fn pt_1(input: String) -> Int {
  todo
}

fn pt_2(input: String) -> Int {
  todo
}
"

fn handle_file_open_failure(reason: efile.Reason, filename: String) -> Snag {
  case reason {
    efile.Eexist -> file_already_exists_err(filename)
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

fn failed_to_create_dir_err(dir: String) -> Snag {
  dir
  |> snag.new()
  |> snag.layer("failed to create dir")
}

fn collect(x: #(Result(Nil), Day)) -> String {
  let day = int.to_string(x.1)
  case x.0
  |> snag.context(string.append("failed to initialize day ", day))
  |> result.map_error(snag.pretty_print) {
    Ok(_) -> string.append("initialized day: ", day)
    Error(reason) -> reason
  }
}

pub fn run(input: CommandInput) {
  case parse.days(input.args) {
    Ok(days) ->
      days
      |> cmd.exec(cmd.Endless, do, collect)
      |> string.join(with: "\n\n")
    Error(err) -> snag.pretty_print(err)
  }
  |> io.println()
}
