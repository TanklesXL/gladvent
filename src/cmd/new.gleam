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
  Combo(String, String)
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

fn create_files(day: Day) -> Result(Nil, Err) {
  let input_path = input_path(day)
  let gleam_src_path = gleam_src_path(day)

  let create_src_res =
    file.open_file_exclusive(gleam_src_path)
    |> result.then(file.write(_, gleam_starter(day)))
    |> result.map_error(handle_file_open_failure(_, gleam_src_path))

  let create_input_res =
    file.open_file_exclusive(input_path)
    |> result.map_error(handle_file_open_failure(_, input_path))

  case create_input_res, create_src_res {
    Ok(_), Ok(_) -> Ok(Nil)
    Error(e1), Ok(_) -> Error(e1)
    Ok(_), Error(e2) -> Error(e2)
    Error(e1), Error(e2) ->
      Error(Combo(
        e1
        |> to_snag
        |> snag.line_print,
        e2
        |> to_snag
        |> snag.line_print,
      ))
  }
}

fn handle_file_open_failure(reason: efile.Reason, filename: String) -> Err {
  case reason {
    efile.Eexist -> FileAlreadyExists(filename)
    _ -> FailedToCreateFile(filename)
  }
}

fn do(day: Day) -> Result(Nil, Err) {
  try _ = list.try_map([input_dir, days_dir], create_dir)
  create_files(day)
}

fn gleam_starter(day: Day) {
  let day = int.to_string(day)
  string.concat([
    "pub fn pt_1(input: String) -> Int {\n",
    "  todo(\"day ",
    day,
    " part 1 unimplemented\")\n}\n\n",
    "pub fn pt_2(input: String) -> Int {\n",
    "  todo(\"day ",
    day,
    " part 2 unimplemented\")\n}\n",
  ])
}

fn collect(x: #(Day, Result(Nil, Err))) -> String {
  let day = int.to_string(x.0)
  case
    x.1
    |> result.map_error(to_snag)
    |> snag.context(string.append("error occurred when initializing day ", day))
    |> result.map_error(snag.pretty_print)
  {
    Ok(_) -> string.append("initialized day: ", day)
    Error(reason) -> reason
  }
}

pub const new_command = glint.Stub(
  path: ["new"],
  run: run,
  flags: [],
  description: "Create .gleam and input files",
  usage: "gleam run new <dayX> <dayY> <...> ",
)

fn run(input: CommandInput) -> snag.Result(List(String)) {
  input.args
  |> parse.days
  |> result.map(cmd.exec(_, cmd.Endless, do, Other, collect))
}

fn to_snag(e: Err) -> Snag {
  case e {
    FailedToCreateDir(d) -> string.append("failed to create dir: ", d)
    FailedToCreateFile(f) -> string.append("failed to create file: ", f)
    FileAlreadyExists(f) -> string.append("file already exists: ", f)
    Combo(e1, e2) ->
      [e1, e2]
      |> list.filter(fn(s) { s != "" })
      |> string.join(" && ")
    Other(s) -> s
  }
  |> snag.new
}
