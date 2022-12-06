import gleam/int
import gleam/result
import gleam/list
import gleam/string
import snag.{Snag}
import ffi/file
import runners.{days_dir, input_dir}
import gleam/erlang/file as efile
import cmd
import glint.{CommandInput}
import parse.{Day}

type Err {
  FailedToCreateDir(String)
  FailedToCreateFile(String)
  FileAlreadyExists(String)
  Combo(Err, Err)
  Other(String)
}

fn input_path(day: Day) -> String {
  string.concat([input_dir, "day_", int.to_string(day), ".txt"])
}

fn gleam_src_path(day: Day) -> String {
  string.concat([days_dir, "day_", int.to_string(day), ".gleam"])
}

fn create_dir(dir: String) -> Result(Nil, Err) {
  dir
  |> efile.make_directory()
  |> handle_dir_open_res(dir)
}

fn handle_dir_open_res(
  res: Result(Nil, efile.Reason),
  filename: String,
) -> Result(Nil, Err) {
  case res {
    Ok(Nil) | Error(efile.Eexist) -> Ok(Nil)
    _ ->
      filename
      |> FailedToCreateDir
      |> Error
  }
}

fn create_files(day: Day) -> snag.Result(Nil) {
  let input_path = input_path(day)
  let gleam_src_path = gleam_src_path(day)

  let create_src_res =
    file.open_file_exclusive(gleam_src_path)
    |> result.then(file.write(_, gleam_starter))
    |> result.map_error(handle_file_open_failure(_, gleam_src_path))

  let create_input_res =
    file.open_file_exclusive(input_path)
    |> result.map_error(handle_file_open_failure(_, input_path))

  case create_input_res, create_src_res {
    Ok(_), Ok(_) -> Ok(Nil)
    Error(e1), Ok(_) ->
      Error(
        ["created ", gleam_src_path, ", but failed to create ", input_path]
        |> string.concat
        |> snag.layer(to_snag(e1), _),
      )
    Ok(_), Error(e2) ->
      Error(
        ["created ", input_path, ", but failed to create ", gleam_src_path]
        |> string.concat
        |> snag.layer(to_snag(e2), _),
      )
    Error(e1), Error(e2) ->
      Error(
        Combo(e1, e2)
        |> to_snag,
      )
  }
}

fn handle_file_open_failure(reason: efile.Reason, filename: String) -> Err {
  case reason {
    efile.Eexist -> FileAlreadyExists(filename)
    _ -> FailedToCreateFile(filename)
  }
}

fn do(day: Day) -> snag.Result(Nil) {
  try _ =
    list.try_map([input_dir, days_dir], create_dir)
    |> result.map_error(to_snag)

  create_files(day)
}

const gleam_starter = "pub fn pt_1(input: String) {
  todo
}

pub fn pt_2(input: String) {
  todo
}
"

fn collect(x: #(Day, snag.Result(Nil))) -> String {
  let day = int.to_string(x.0)
  case
    x.1
    |> snag.context("error occurred when initializing day " <> day)
    |> result.map_error(snag.pretty_print)
  {
    Ok(_) -> "initialized day: " <> day
    Error(reason) -> reason
  }
}

pub fn new_command() {
  glint.Stub(
    path: ["new"],
    run: run,
    flags: [],
    description: "Create .gleam and input files",
  )
}

fn run(input: CommandInput) -> snag.Result(List(String)) {
  input.args
  |> parse.days
  |> snag.context(string.join(["failed to initialize:", ..input.args], " "))
  |> result.map(cmd.exec(_, cmd.Endless, do, snag.new, collect))
}

fn to_snag(e: Err) -> Snag {
  case e {
    FailedToCreateDir(d) -> "failed to create dir: " <> d
    FailedToCreateFile(f) -> "failed to create file: " <> f
    FileAlreadyExists(f) -> "file already exists: " <> f
    Combo(e1, e2) ->
      [e1, e2]
      |> list.map(to_snag)
      |> list.map(snag.line_print)
      |> list.filter(fn(s) { s != "" })
      |> string.join(" && ")
    Other(s) -> s
  }
  |> snag.new
}
