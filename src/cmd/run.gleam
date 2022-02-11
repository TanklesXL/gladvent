import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import gleam/function
import snag.{Result, Snag}
import gleam/erlang/file
import gleam/erlang/atom.{Atom}
import parse.{Day}
import gleam/map.{Map}
import cmd.{Ending, Endless, days_dir}
import glint.{CommandInput}
import glint/flag
import gleam

pub type Solution =
  #(Int, Int)

pub type DayRunner =
  fn(String) -> Solution

pub type RunnerMap =
  Map(Day, DayRunner)

external fn find_files(matching: String, in: String) -> List(String) =
  "gladvent_ffi" "find_files"

type Module =
  Atom

fn to_module(file: String) -> Module {
  file
  |> string.replace(".gleam", "")
  |> string.replace(".erl", "")
  |> string.replace("/", "@")
  |> atom.create_from_string()
}

external fn get_run(Module) -> DayRunner =
  "gladvent_ffi" "get_run"

pub external fn do_run(
  fn(String) -> Solution,
  String,
) -> gleam.Result(Solution, RunError) =
  "gladvent_ffi" "do_run"

fn get_runner(filename: String) -> Result(#(Day, DayRunner)) {
  try day =
    string.replace(filename, "day_", "")
    |> string.replace(".gleam", "")
    |> parse.day()
    |> snag.context(string.append("cannot create runner for ", filename))

  let run =
    filename
    |> string.append("days/", _)
    |> to_module()
    |> get_run()

  Ok(#(day, run))
}

fn get_runners() -> Result(List(#(Day, DayRunner))) {
  find_files(matching: "day_*.gleam", in: days_dir)
  |> list.try_map(get_runner)
}

pub fn build_runners_from_days_dir() -> Result(
  Map(Day, fn(String) -> #(Int, Int)),
) {
  try runners = get_runners()
  Ok(map.from_list(runners))
}

pub type RunError {
  Undef
  RunFailed
}

fn do(day: Day, runners: RunnerMap) -> Result(Solution) {
  try day_runner =
    map.get(runners, day)
    |> result.replace_error(unrecognized_day_err(day))

  let input_path = string.join(["input/day_", int.to_string(day), ".txt"], "")

  try input =
    input_path
    |> file.read()
    |> result.replace_error(failed_to_read_input_err(input_path))
    |> result.map(string.trim)

  case do_run(day_runner, input) {
    Error(Undef) -> snag.error("run function undefined")
    Error(_) -> snag.error("some error occurred")
    Ok(res) -> Ok(res)
  }
}

fn unrecognized_day_err(day: Day) -> Snag {
  day
  |> int.to_string()
  |> string.append("unrecognized day: ", _)
  |> snag.new()
}

fn failed_to_read_input_err(input_path: String) -> Snag {
  input_path
  |> snag.new()
  |> snag.layer("failed to read input file")
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
        int.to_string(res_1),
        "\n  Part 2: ",
        int.to_string(res_2),
      ]
      |> string.concat()
    Error(err) ->
      string.append("Error on day ", day)
      |> snag.layer(err, _)
      |> snag.pretty_print()
  }
}

pub fn register_command(
  glint: glint.Command(Result(List(String))),
  runners: RunnerMap,
) -> glint.Command(Result(List(String))) {
  glint.add_command(
    glint,
    ["run"],
    run(_, runners),
    [
      flag.int(called: "timeout", default: 0),
      flag.bool(called: "all", default: False),
    ],
  )
}

pub fn run(input: CommandInput, runners: RunnerMap) -> Result(List(String)) {
  assert Ok(flag.I(timeout)) = map.get(input.flags, "timeout")

  try timing = case timeout {
    0 -> Ok(Endless)
    _ if timeout < 0 -> invalid_timeout_err(timeout)
    _ -> Ok(Ending(timeout))
  }

  assert Ok(flag.B(all)) = map.get(input.flags, "all")

  try days = case all {
    True ->
      runners
      |> map.keys()
      |> list.sort(by: int.compare)
      |> Ok

    False ->
      parse.days(input.args)
      |> wrap_failed_to_parse_err(input.args)
  }

  days
  |> cmd.exec(timing, do(_, runners), collect)
  |> Ok
}

fn invalid_timeout_err(timeout: Int) -> Result(a) {
  ["invalid timeout value ", "'", int.to_string(timeout), "'"]
  |> string.concat()
  |> snag.error()
  |> snag.context("timeout must be greater than or equal to 1 ms")
  |> snag.context("failed to run advent of code")
}

fn wrap_failed_to_parse_err(res: Result(a), args: List(String)) -> Result(a) {
  res
  |> snag.context(string.join(["failed to parse arguments:", ..args], " "))
  |> snag.context("failed to run advent of code")
}
