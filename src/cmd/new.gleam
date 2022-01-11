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
import parse.{Day}
import gleam/erlang/charlist
import gleam/erlang/file as efile
import cmd
import cli.{CommandInput}

const input_dir = "input/"

const days_dir = "src/days/"

fn do(day: Day) -> Result(Nil) {
  let day = int.to_string(day)

  try _ =
    file.ensure_dir(input_dir)
    |> result.replace_error(failed_to_create_dir_err(input_dir))

  try _ =
    file.ensure_dir(days_dir)
    |> result.replace_error(failed_to_create_dir_err(days_dir))

  let input_path = string.concat([input_dir, "day_", day, ".txt"])
  let gleam_src_path = string.concat([days_dir, "day_", day, ".gleam"])

  try _ =
    file.open_file_exclusive(input_path)
    |> result.map_error(handle_file_open_failure(_, input_path))

  file.open_and_write_exclusive(gleam_src_path, gleam_starter)
  |> result.map_error(handle_file_open_failure(_, gleam_src_path))
}

const gleam_starter = "pub fn run(input) {
  #(pt_1(input), pt_2(input))
}

fn pt_1(input: String) -> Int {
  0
}

fn pt_2(input: String) -> Int {
  0
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
      |> cmd.exec(cmd.Sync, do, collect)
      |> string.join(with: "\n\n")
    Error(err) -> snag.pretty_print(err)
  }
  |> io.println()
}
