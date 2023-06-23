import gleam/int
import gleam/result
import gleam/list
import gleam/string
import gladvent/internal/file
import gleam/erlang/file as efile
import gladvent/internal/cmd
import glint
import glint/flag
import gladvent/internal/parse.{Day}
import gleam/pair

type Context {
  Context(year: Int, day: Day)
}

fn create_src_dir(ctx: Context) {
  ctx.year
  |> cmd.src_dir()
  |> create_dir
}

fn create_src_file(ctx: Context) {
  let gleam_src_path = gleam_src_path(ctx.year, ctx.day)

  gleam_src_path
  |> file.do_with_file(file.write(_, gleam_starter))
  |> result.flatten
  |> result.map_error(handle_file_open_failure(_, gleam_src_path))
  |> result.replace(gleam_src_path)
}

fn create_input_root(_ctx: Context) {
  cmd.input_root
  |> create_dir
}

fn create_input_dir(ctx: Context) {
  ctx.year
  |> cmd.input_dir
  |> create_dir
}

fn create_input_file(ctx: Context) {
  let input_path = input_path(ctx.year, ctx.day)

  file.do_with_file(input_path, fn(_) { Nil })
  |> result.map_error(handle_file_open_failure(_, input_path))
  |> result.replace(input_path)
}

type Err {
  FailedToCreateDir(String)
  FailedToCreateFile(String)
  FileAlreadyExists(String)
}

fn err_to_string(e: Err) -> String {
  case e {
    FailedToCreateDir(d) -> "failed to create dir: " <> d
    FailedToCreateFile(f) -> "failed to create file: " <> f
    FileAlreadyExists(f) -> "file already exists: " <> f
  }
}

fn input_path(year: Int, day: Day) -> String {
  cmd.input_dir(year) <> int.to_string(day) <> ".txt"
}

fn gleam_src_path(year: Int, day: Day) -> String {
  cmd.src_dir(year) <> "day_" <> int.to_string(day) <> ".gleam"
}

fn create_dir(dir: String) -> Result(String, Err) {
  efile.make_directory(dir)
  |> handle_dir_open_res(dir)
}

fn handle_dir_open_res(
  res: Result(_, efile.Reason),
  filename: String,
) -> Result(String, Err) {
  case res {
    Ok(_) -> Ok(filename)
    Error(efile.Eexist) -> Ok("")
    _ ->
      filename
      |> FailedToCreateDir
      |> Error
  }
}

fn handle_file_open_failure(reason: efile.Reason, filename: String) -> Err {
  case reason {
    efile.Eexist -> FileAlreadyExists(filename)
    _ -> FailedToCreateFile(filename)
  }
}

fn do(ctx: Context) -> String {
  let seq = [
    create_input_root,
    create_input_dir,
    create_input_file,
    create_src_dir,
    create_src_file,
  ]

  let successes = fn(good) {
    case good {
      "" -> ""
      _ -> "created:" <> good
    }
  }

  let errors = fn(errs) {
    case errs {
      "" -> ""
      _ -> "errors:" <> errs
    }
  }

  let newline_tab = fn(a, b) { a <> "\n\t" <> b }

  let #(good, bad) =
    {
      use acc, f <- list.fold(seq, #("", ""))
      case f(ctx) {
        Ok("") -> acc
        Ok(o) -> pair.map_first(acc, newline_tab(_, o))
        Error(err) -> pair.map_second(acc, newline_tab(_, err_to_string(err)))
      }
    }
    |> pair.map_first(successes)
    |> pair.map_second(errors)

  [good, bad]
  |> list.filter(fn(s) { s != "" })
  |> string.join("\n\n")
}

const gleam_starter = "pub fn pt_1(input: String) {
  todo
}

pub fn pt_2(input: String) {
  todo
}
"

fn collect(year: Int, x: #(Day, Result(String, String))) -> String {
  let day = int.to_string(x.0)
  let year = int.to_string(year)

  "initialized " <> year <> " day " <> day <> "\n" <> {
    case x.1 {
      Ok(ok) -> ok
      Error(err) -> err
    }
  }
}

pub fn new_command() {
  {
    use input <- glint.command()
    use days <- result.map(parse.days(input.args))
    let assert Ok(year) = flag.get_int(input.flags, cmd.year)
    cmd.exec(
      days,
      cmd.Endless,
      fn(day) { do(Context(year, day)) },
      collect(year, _),
    )
  }
  |> glint.description("Create .gleam and input files")
}
