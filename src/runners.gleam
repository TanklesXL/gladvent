import gleam/map.{Map}
import gleam/erlang/atom.{Atom}
import gleam/string
import snag.{Result}
import parse.{Day}
import gleam/list
import gleam/result

pub const input_dir = "input/"

pub const days_dir = "src/days/"

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

fn get_runner(filename: String) -> Result(#(Day, DayRunner)) {
  try day =
    string.replace(filename, "day_", "")
    |> string.replace(".gleam", "")
    |> parse.day
    |> snag.context(string.append("cannot create runner for ", filename))

  let run =
    filename
    |> string.append("days/", _)
    |> to_module()
    |> get_run()

  Ok(#(day, run))
}

pub fn build_from_days_dir() -> Result(Map(Day, DayRunner)) {
  find_files(matching: "day_*.gleam", in: days_dir)
  |> list.try_map(get_runner)
  |> result.map(map.from_list)
  |> snag.context("failed to generate runners list from filesystem")
}
