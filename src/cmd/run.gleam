import gleam/int
import gleam/list
import gleam/result
import gleam/string
import snag.{Result, Snag}
import gleam/erlang/file
import gleam/erlang
import gleam/erlang/charlist.{Charlist}
import gleam/erlang/atom
import parse.{Day}
import gleam/map
import cmd.{Ending, Endless}
import glint
import glint/flag
import gleam
import runners.{RunnerMap}
import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option}

type SolveErr {
  Undef
  RunFailed(String)
}

type Err {
  FailedToReadInput(String)
  Unregistered(Day)
  Other(String)
}

fn err_to_snag(err: Err) -> Snag {
  case err {
    Unregistered(day) ->
      "day" <> " " <> int.to_string(day) <> " " <> "unregistered"
    FailedToReadInput(input_path) -> "failed to read input file: " <> input_path
    Other(s) -> s
  }
  |> snag.new
}

type RunResult =
  gleam.Result(Dynamic, SolveErr)

type Direction {
  // Leading
  // Trailing
  Both
}

fn string_trim(s: String, dir: Direction, sub: String) -> String {
  do_trim(s, dir, charlist.from_string(sub))
}

external fn do_trim(String, Direction, Charlist) -> String =
  "string" "trim"

fn do(
  day: Day,
  runners: RunnerMap,
  allow_crash: Bool,
) -> gleam.Result(#(RunResult, RunResult), Err) {
  use #(pt_1, pt_2) <- result.then(
    map.get(runners, day)
    |> result.replace_error(Unregistered(day)),
  )

  let input_path = string.join(["input/day_", int.to_string(day), ".txt"], "")

  use input <- result.then(
    input_path
    |> file.read()
    |> result.map(string_trim(_, Both, "\n"))
    |> result.replace_error(FailedToReadInput(input_path)),
  )

  case allow_crash {
    True -> Ok(#(Ok(pt_1(input)), Ok(pt_2(input))))
    False -> {
      let pt_1 =
        fn() { pt_1(input) }
        |> erlang.rescue
        |> result.map_error(run_err_to_string)
      let pt_2 =
        fn() { pt_2(input) }
        |> erlang.rescue
        |> result.map_error(run_err_to_string)
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

fn run_err_to_string(err: erlang.Crash) -> SolveErr {
  let dyn = crash_to_dyn(err)
  decode_gleam_err()(dyn)
  |> result.map(gleam_err_to_string)
  |> result.lazy_unwrap(fn() {
    "run failed for some reason: " <> string.inspect(err)
  })
  |> RunFailed
}

fn run_res_to_string(res: RunResult) -> String {
  case res {
    Ok(res) -> string.inspect(res)
    Error(err) ->
      case err {
        Undef -> "function undefined"
        RunFailed(s) -> s
      }
  }
}

fn collect(x: #(Day, gleam.Result(#(RunResult, RunResult), Err))) -> String {
  let day = int.to_string(x.0)
  case x.1 {
    Ok(#(res_1, res_2)) ->
      "Ran day " <> day <> ":\n" <> "  Part 1: " <> run_res_to_string(res_1) <> "\n" <> "  Part 2: " <> run_res_to_string(
        res_2,
      )

    Error(err) ->
      err
      |> err_to_snag
      |> snag.layer(string.append("failed to run day ", day))
      |> snag.pretty_print()
  }
}

// ----- CLI -----

const timeout = "timeout"

const allow_crash = "allow-crash"

fn timeout_flag() {
  flag.I
  |> flag.constraint(fn(i) {
    case i > 0 {
      True -> Ok(Nil)
      False -> snag.error("timeout value must greater than zero")
    }
  })
  |> flag.new
  |> flag.description("Run with specified timeout")
}

fn allow_crash_flag() {
  flag.B
  |> flag.default(False)
  |> flag.new
  |> flag.description("Don't catch exceptions thrown by runners")
}

pub fn run_command(runners: RunnerMap) -> glint.Command(Result(List(String))) {
  {
    use input <- glint.command()
    use allow_crash <- result.then(flag.get_bool(input.flags, allow_crash))

    let timing = timing(input.flags)

    input.flags
    |> flag.get_ints(cmd.days)
    |> result.lazy_unwrap(fn() { all_days(runners) })
    |> cmd.exec(timing, do(_, runners, allow_crash), Other, collect)
    |> Ok
  }
  |> glint.flag(timeout, timeout_flag())
  |> glint.flag(allow_crash, allow_crash_flag())
  |> glint.flag(cmd.days, cmd.days_flag())
  |> glint.description("Run the specified days")
}

pub fn run_all_command(
  runners: RunnerMap,
) -> glint.Command(Result(List(String))) {
  {
    use input <- glint.command()
    use allow_crash <- result.then(flag.get_bool(input.flags, allow_crash))

    let timing = timing(input.flags)
    runners
    |> all_days
    |> cmd.exec(timing, do(_, runners, allow_crash), Other, collect)
    |> Ok
  }
  |> glint.flag(timeout, timeout_flag())
  |> glint.flag(allow_crash, allow_crash_flag())
  |> glint.description("Run all registered days")
}

fn timing(flags: flag.Map) {
  case flag.get_int(flags, timeout) {
    Ok(timeout) -> Ending(timeout)
    _ -> Endless
  }
}

fn all_days(runners) {
  runners
  |> map.keys()
  |> list.sort(by: int.compare)
}
