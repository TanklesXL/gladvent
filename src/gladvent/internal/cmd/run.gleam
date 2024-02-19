import gleam/int
import gleam/list
import gleam/result
import gleam/string
import snag.{type Result, type Snag}
import simplifile
import gleam/erlang
import gleam/erlang/charlist.{type Charlist}
import gleam/erlang/atom
import gladvent/internal/parse.{type Day}
import gleam/dict as map
import gladvent/internal/cmd.{Ending, Endless}
import glint
import glint/flag
import gleam
import gladvent/internal/runners.{type RunnerMap}
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option, None}

type AsyncResult =
  gleam.Result(RunResult, String)

type RunErr {
  FailedToReadInput(String)
  FailedToParseInput(String)
  Unregistered(Day)
  Other(String)
}

type RunResult =
  gleam.Result(#(SolveResult, SolveResult), RunErr)

type SolveErr {
  Undef
  RunFailed(String)
}

type SolveResult =
  gleam.Result(Dynamic, SolveErr)

fn run_err_to_snag(err: RunErr) -> Snag {
  case err {
    Unregistered(day) ->
      "day" <> " " <> int.to_string(day) <> " " <> "unregistered"
    FailedToReadInput(input_path) -> "failed to read input file: " <> input_path
    FailedToParseInput(err) -> "failed to parse input: " <> err
    Other(s) -> s
  }
  |> snag.new
}

type Direction {
  // Leading
  // Trailing
  Both
}

fn string_trim(s: String, dir: Direction, sub: String) -> String {
  do_trim(s, dir, charlist.from_string(sub))
}

@external(erlang, "string", "trim")
fn do_trim(a: String, b: Direction, c: Charlist) -> String

fn do(year: Int, day: Day, runners: RunnerMap, allow_crash: Bool) -> RunResult {
  use #(pt_1, pt_2, parse) <- result.try(
    runners
    |> map.get(day)
    |> result.replace_error(Unregistered(day)),
  )

  let input_path =
    "input/" <> int.to_string(year) <> "/" <> int.to_string(day) <> ".txt"

  use input <- result.try(
    input_path
    |> simplifile.read()
    |> result.map(string_trim(_, Both, "\n"))
    |> result.replace_error(FailedToReadInput(input_path)),
  )

  let parse = option.unwrap(parse, dynamic.from)

  case allow_crash {
    True -> {
      let input = parse(input)
      Ok(#(Ok(pt_1(input)), Ok(pt_2(input))))
    }
    False -> {
      use input <- result.try(
        fn() { parse(input) }
        |> erlang.rescue
        |> result.map_error(crash_to_string)
        |> result.map_error(FailedToParseInput),
      )
      let pt_1 =
        fn() { pt_1(input) }
        |> erlang.rescue
        |> result.map_error(crash_to_solve_err)
      let pt_2 =
        fn() { pt_2(input) }
        |> erlang.rescue
        |> result.map_error(crash_to_solve_err)
      Ok(#(pt_1, pt_2))
    }
  }
}

fn crash_to_dyn(err: erlang.Crash) -> dynamic.Dynamic {
  case err {
    erlang.Errored(dyn) | erlang.Exited(dyn) | erlang.Thrown(dyn) -> dyn
  }
}

type GleamErr {
  GleamErr(
    gleam_error: atom.Atom,
    module: String,
    function: String,
    line: Int,
    message: String,
    value: Option(Dynamic),
  )
}

fn decode_gleam_err() {
  dynamic.decode6(
    GleamErr,
    dynamic.field(atom.create_from_string("gleam_error"), atom.from_dynamic),
    dynamic.field(atom.create_from_string("module"), dynamic.string),
    dynamic.field(atom.create_from_string("function"), dynamic.string),
    dynamic.field(atom.create_from_string("line"), dynamic.int),
    dynamic.field(atom.create_from_string("message"), dynamic.string),
    dynamic.any([
      dynamic.field(
        atom.create_from_string("value"),
        dynamic.optional(dynamic.dynamic),
      ),
      fn(_) { Ok(None) },
    ]),
  )
}

fn gleam_err_to_string(g: GleamErr) -> String {
  string.join(
    [
      "error:",
      atom.to_string(g.gleam_error),
      "-",
      g.message,
      "in module",
      g.module,
      "in function",
      g.function,
      "at line",
      int.to_string(g.line),
      g.value
      |> option.map(fn(val) { "with value " <> string.inspect(val) })
      |> option.unwrap(""),
    ],
    " ",
  )
}

fn crash_to_string(err: erlang.Crash) -> String {
  crash_to_dyn(err)
  |> decode_gleam_err()
  |> result.map(gleam_err_to_string)
  |> result.lazy_unwrap(fn() {
    "run failed for some reason: " <> string.inspect(err)
  })
}

fn crash_to_solve_err(err: erlang.Crash) -> SolveErr {
  err
  |> crash_to_string
  |> RunFailed
}

fn solve_err_to_string(solve_err: SolveErr) -> String {
  case solve_err {
    Undef -> "function undefined"
    RunFailed(s) -> s
  }
}

fn solve_res_to_string(res: SolveResult) -> String {
  case res {
    Ok(res) -> string.inspect(res)
    Error(err) -> solve_err_to_string(err)
  }
}

import gleam/pair

fn collect_async(year: Int, x: #(Day, AsyncResult)) -> String {
  x
  |> pair.map_second(result.map_error(_, Other))
  |> pair.map_second(result.flatten)
  |> collect(year, _)
}

fn collect(year: Int, x: #(Day, RunResult)) -> String {
  let day = int.to_string(x.0)

  case x.1 {
    Ok(#(res_1, res_2)) ->
      "Ran "
      <> int.to_string(year)
      <> " day "
      <> day
      <> ":\n"
      <> "  Part 1: "
      <> solve_res_to_string(res_1)
      <> "\n"
      <> "  Part 2: "
      <> solve_res_to_string(res_2)

    Error(err) ->
      err
      |> run_err_to_snag
      |> snag.layer("Failed to run " <> int.to_string(year) <> " day " <> day)
      |> snag.pretty_print()
  }
}

// ----- CLI -----

const timeout = "timeout"

const allow_crash = "allow-crash"

fn timeout_flag() {
  flag.int()
  |> flag.constraint(fn(i) {
    case i > 0 {
      True -> Ok(Nil)
      False -> snag.error("timeout value must greater than zero")
    }
  })
  |> flag.description("Run with specified timeout")
}

fn allow_crash_flag() {
  flag.bool()
  |> flag.default(False)
  |> flag.description("Don't catch exceptions thrown by runners")
}

pub fn run_command() -> glint.Command(Result(List(String))) {
  {
    use input <- glint.command()
    let assert Ok(year) = flag.get_int(input.flags, cmd.year)
    use runners <- result.then(runners.build_from_days_dir(year))
    use allow_crash <- result.try(flag.get_bool(input.flags, allow_crash))
    use days <- result.then(parse.days(input.args))

    days
    |> cmd.exec(
      timing(input.flags),
      do(year, _, runners, allow_crash),
      collect_async(year, _),
    )
    |> Ok
  }
  |> glint.flag(timeout, timeout_flag())
  |> glint.flag(allow_crash, allow_crash_flag())
  |> glint.description("Run the specified days")
  |> glint.unnamed_args(glint.MinArgs(1))
}

pub fn run_all_command() -> glint.Command(Result(List(String))) {
  {
    use input <- glint.command()
    use allow_crash <- result.then(flag.get_bool(input.flags, allow_crash))
    let assert Ok(year) = flag.get_int(input.flags, cmd.year)
    use runners <- result.then(runners.build_from_days_dir(year))

    runners
    |> all_days
    |> cmd.exec(
      timing(input.flags),
      do(year, _, runners, allow_crash),
      collect_async(year, _),
    )
    |> Ok
  }
  |> glint.flag(timeout, timeout_flag())
  |> glint.flag(allow_crash, allow_crash_flag())
  |> glint.description("Run all registered days")
}

fn timing(flags: flag.Map) {
  flag.get_int(flags, timeout)
  |> result.map(Ending)
  |> result.unwrap(Endless)
}

fn all_days(runners) {
  runners
  |> map.keys()
  |> list.sort(by: int.compare)
}
