import gleam/map.{Map}
import gleam/erlang/atom.{Atom}
import gleam/string
import snag.{Result}
import parse.{Day}
import gleam/list
import gleam/result
import gleam
import gleam/dynamic.{Dynamic}

pub const input_dir = "input/"

pub const days_dir = "src/days/"

pub type PartRunner =
  fn(String) -> Dynamic

pub type DayRunner =
  #(PartRunner, PartRunner)

pub type RunnerMap =
  Map(Day, DayRunner)

external fn find_files(matching: String, in: String) -> List(String) =
  "gladvent_ffi" "find_files"

type Module =
  Atom

fn to_module_name(file: String) -> String {
  file
  |> string.replace(".gleam", "")
  |> string.replace(".erl", "")
  |> string.replace("/", "@")
}

external fn module_exists(Module) -> Bool =
  "gladvent_ffi" "module_exists"

external fn do_function_exists(Module, Atom) -> gleam.Result(PartRunner, Nil) =
  "gladvent_ffi" "function_arity_one_exists"

fn function_exists(
  filename: String,
  mod: Atom,
  func_name: String,
) -> Result(PartRunner) {
  case module_exists(mod) {
    False ->
      ["module ", filename, " not found"]
      |> string.concat
      |> snag.error
    True ->
      func_name
      |> atom.create_from_string
      |> do_function_exists(mod, _)
      |> result.replace_error(snag.new(
        "module " <> days_dir <> filename <> " does not export a function \"" <> func_name <> "/1\"",
      ))
      |> snag.context("function missing")
  }
}

fn get_runner(filename: String) -> Result(#(Day, DayRunner)) {
  try day =
    string.replace(filename, "day_", "")
    |> string.replace(".gleam", "")
    |> parse.day
    |> snag.context(string.append("cannot create runner for ", filename))

  let module =
    filename
    |> string.append("days/", _)
    |> to_module_name
    |> atom.create_from_string

  try pt_1 = function_exists(filename, module, "pt_1")
  try pt_2 = function_exists(filename, module, "pt_2")

  Ok(#(day, #(pt_1, pt_2)))
}

pub fn build_from_days_dir() -> Result(Map(Day, DayRunner)) {
  find_files(matching: "day_*.gleam", in: days_dir)
  |> list.try_map(get_runner)
  |> result.map(map.from_list)
  |> snag.context("failed to generate runners list from filesystem")
}
