import gleam/dict.{type Dict as Map} as map
import gleam/erlang/atom.{type Atom}
import gleam/string
import snag.{type Result}
import gladvent/internal/parse.{type Day}
import gleam/list
import gleam/result
import gleam
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/option.{type Option}
import shellout
import gleam/json
import gleam/package_interface
import spinner
import simplifile
import gleam/io

pub type PartRunner =
  fn(Dynamic) -> Dynamic

pub type DayRunner =
  #(PartRunner, PartRunner, Option(fn(String) -> Dynamic))

pub type RunnerMap =
  Map(Day, DayRunner)

@external(erlang, "gladvent_ffi", "find_files")
fn find_files(matching matching: String, in in: String) -> List(String)

type Module =
  Atom

fn to_module_name(file: String) -> String {
  file
  |> string.replace(".gleam", "")
  |> string.replace(".erl", "")
  |> string.replace("/", "@")
}

@external(erlang, "gladvent_ffi", "module_exists")
fn module_exists(a: Module) -> Bool

@external(erlang, "gladvent_ffi", "function_arity_one_exists")
fn do_function_exists(a: Module, b: Atom) -> gleam.Result(fn(a) -> b, Nil)

fn function_exists(
  year: Int,
  filename: String,
  mod: Atom,
  func_name: String,
) -> Result(fn(a) -> b) {
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
        "module "
          <> "src/"
          <> int.to_string(year)
          <> "/"
          <> filename
          <> " does not export a function \""
          <> func_name
          <> "/1\"",
      ))
      |> snag.context("function missing")
  }
}

fn get_runner(year: Int, filename: String) -> Result(#(Day, DayRunner)) {
  use day <- result.then(
    string.replace(filename, "day_", "")
    |> string.replace(".gleam", "")
    |> parse.day
    |> snag.context(string.append("cannot create runner for ", filename)),
  )

  let module =
    { "aoc_" <> int.to_string(year) <> "/" <> filename }
    |> to_module_name
    |> atom.create_from_string

  use pt_1 <- result.then(function_exists(year, filename, module, "pt_1"))
  use pt_2 <- result.then(function_exists(year, filename, module, "pt_2"))

  Ok(
    #(day, #(
      pt_1,
      pt_2,
      option.from_result(function_exists(year, filename, module, "parse")),
    )),
  )
}

pub fn build_from_days_dir(year: Int) -> Result(Map(Day, DayRunner)) {
  let assert Ok(package_interface) = pkg_interface()
  dict.get(package_interface.modules, "aoc_")
  find_files(matching: "day_*.gleam", in: "src/aoc_" <> int.to_string(year))
  |> list.try_map(get_runner(year, _))
  |> result.map(map.from_list)
  |> snag.context("failed to generate runners list from filesystem")
}

const package_interface_path = "./build/.gladvent/pkg.json"

pub type PkgInterfaceErr {
  FailedToGeneratePackageInterface(String)
  FailedToReadPackageInterface(simplifile.FileError)
  FailedToDecodePackageInterface(json.DecodeError)
}

pub fn pkg_interface() {
  let spinner =
    spinner.new("generating package interface")
    |> spinner.start()

  use <- defer(do: fn() { spinner.stop(spinner) })

  use _ <- result.try(
    shellout.command(
      "gleam",
      ["export", "package-interface", "--out", package_interface_path],
      ".",
      [],
    )
    |> result.map_error(fn(e) { FailedToGeneratePackageInterface(e.1) }),
  )

  use pkg_interface_contents <- result.try(
    simplifile.read(package_interface_path)
    |> result.map_error(FailedToReadPackageInterface),
  )
  use pkg_interface_details <- result.try(
    json.decode(from: pkg_interface_contents, using: package_interface.decoder)
    |> result.map_error(FailedToDecodePackageInterface),
  )

  Ok(io.debug(pkg_interface_details))
}

fn defer(do b: fn() -> _, after a: fn() -> a) -> a {
  let a_out = a()
  b()
  a_out
}
