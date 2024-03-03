import gleam/dict as map
import gleam/erlang/atom
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
import gleam/bool
import gladvent/internal/util.{defer}

pub type PartRunner =
  fn(Dynamic) -> Dynamic

pub type DayRunner =
  #(PartRunner, PartRunner, Option(fn(String) -> Dynamic))

const package_interface_path = "build/.gladvent/pkg.json"

type PkgInterfaceErr {
  FailedToGeneratePackageInterface(String)
  FailedToReadPackageInterface(simplifile.FileError)
  FailedToDecodePackageInterface(json.DecodeError)
}

fn package_interface_error_to_snag(e: PkgInterfaceErr) -> snag.Snag {
  case e {
    FailedToGeneratePackageInterface(s) ->
      snag.new(s)
      |> snag.layer("failed to generate " <> package_interface_path)
    FailedToReadPackageInterface(e) ->
      snag.new(string.inspect(e))
      |> snag.layer("failed to read " <> package_interface_path)
    FailedToDecodePackageInterface(e) ->
      snag.new(string.inspect(e))
      |> snag.layer("failed to decode package interface json")
  }
}

pub fn pkg_interface() -> Result(package_interface.Package) {
  use <- snagify_error(with: package_interface_error_to_snag)
  let spinner =
    spinner.new("generating " <> package_interface_path)
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

  spinner.set_text(spinner, "reading " <> package_interface_path)
  use pkg_interface_contents <- result.try(
    simplifile.read(package_interface_path)
    |> result.map_error(FailedToReadPackageInterface),
  )

  spinner.set_text(spinner, "decoding package interface JSON")
  use pkg_interface_details <- result.try(
    json.decode(from: pkg_interface_contents, using: package_interface.decoder)
    |> result.map_error(FailedToDecodePackageInterface),
  )

  Ok(pkg_interface_details)
}

pub type RunnerRetrievalErr {
  ModuleNotFound(String)
  ParseFunctionInvalid(String)
  FunctionNotFound(module: String, function: String)
  IncorrectInputParameters(
    function: String,
    expected: String,
    got: List(package_interface.Type),
  )
}

pub fn runner_retrieval_error_to_snag(e: RunnerRetrievalErr) -> snag.Snag {
  case e {
    ModuleNotFound(m) -> snag.new("module " <> m <> " not found")
    ParseFunctionInvalid(f) ->
      snag.new(f)
      |> snag.layer("parse function invalid")
    FunctionNotFound(m, f) ->
      snag.new("module " <> m <> " does not export function " <> f)
    IncorrectInputParameters(f, e, g) ->
      {
        "function '"
        <> f
        <> "' has parameter(s) "
        <> string.inspect(g)
        <> ", but should only have one parameter and it must be of type "
        <> e
      }
      |> snag.new
  }
}

fn snagify_error(
  do f: fn() -> gleam.Result(out, err),
  with m: fn(err) -> snag.Snag,
) -> Result(out) {
  f()
  |> result.map_error(m)
}

pub fn get_day(
  package: package_interface.Package,
  year: Int,
  day: Day,
) -> Result(DayRunner) {
  use <- snagify_error(with: runner_retrieval_error_to_snag)
  let module_name =
    "aoc_" <> int.to_string(year) <> "/day_" <> int.to_string(day)
  // let module_atom = atom.create_from_string(to_erlang_module_name(module_name))

  // get the module for the specified year + day
  use module <- result.try(
    map.get(package.modules, module_name)
    |> result.replace_error(ModuleNotFound(module_name)),
  )

  // get the optional parse function
  let parse = map.get(module.functions, "parse")

  use runner_param_type <- result.try(case parse {
    Error(Nil) -> Ok(string)
    Ok(package_interface.Function(parameters: [param], return: return, ..)) if param.type_ == string ->
      Ok(return)
    _ ->
      Error(ParseFunctionInvalid(
        "parse function must have 1 input parameter of type String",
      ))
  })

  let retrieve_runner = retrieve_runner(
    module_name,
    module,
    _,
    runner_param_type,
  )
  // get pt_1
  use pt_1 <- result.try(retrieve_runner("pt_1"))
  // get pt_2
  use pt_2 <- result.try(retrieve_runner("pt_2"))

  Ok(#(
    pt_1,
    pt_2,
    parse
    |> result.replace(parse_function(module_name))
    |> option.from_result,
  ))
}

fn retrieve_runner(
  module_name: String,
  module: package_interface.Module,
  function_name: String,
  runner_param_type: package_interface.Type,
) -> gleam.Result(fn(Dynamic) -> Dynamic, RunnerRetrievalErr) {
  use pt_1 <- result.try(
    module.functions
    |> map.get(function_name)
    |> result.replace_error(FunctionNotFound(module_name, function_name)),
  )
  use <- bool.guard(
    when: case pt_1.parameters {
      [param] -> param.type_ != runner_param_type
      _ -> True
    },
    return: Error(IncorrectInputParameters(
      function: function_name,
      expected: string.inspect(runner_param_type),
      got: list.map(pt_1.parameters, fn(p) { p.type_ }),
    )),
  )

  Ok(function_arity_one(
    atom.create_from_string(to_erlang_module_name(module_name)),
    atom.create_from_string(function_name),
  ))
}

fn to_erlang_module_name(name) {
  string.replace(name, "/", "@")
}

@external(erlang, "gladvent_ffi", "function_arity_one")
fn function_arity_one(
  module: atom.Atom,
  function: atom.Atom,
) -> fn(Dynamic) -> Dynamic

fn parse_function(module: String) -> fn(String) -> Dynamic {
  do_parse_function(atom.create_from_string(to_erlang_module_name(module)))
}

@external(erlang, "gladvent_ffi", "parse_function")
fn do_parse_function(module: atom.Atom) -> fn(String) -> Dynamic

const string = package_interface.Named(
  name: "String",
  module: "gleam",
  package: "",
  parameters: [],
)