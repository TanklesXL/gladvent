import gleam/list
import gleam/int
import gleam/result
import gleam/string
import snag.{Result, Snag}
import gleam/erlang/file
import parse.{Day}
import gleam/map
import cmd.{Ending, Endless}
import glint.{CommandInput}
import glint/flag
import gleam
import runners.{RunnerMap, Solution}

pub external fn do_run(
  fn(String) -> Solution,
  String,
) -> gleam.Result(Solution, Err) =
  "gladvent_ffi" "do_run"

pub type Err {
  Undef
  RunFailed
  FailedToReadInput(String)
  Unrecognized(Day)
  Other(String)
}

fn to_snag(err: Err) -> Snag {
  case err {
    Undef -> "run function undefined"
    RunFailed -> "some error occurred"
    Unrecognized(day) ->
      string.join(["day", int.to_string(day), "unrecognized"], " ")
    FailedToReadInput(input_path) ->
      string.append("failed to read input file: ", input_path)
    Other(s) -> s
  }
  |> snag.new
}

fn do(day: Day, runners: RunnerMap) -> gleam.Result(Solution, Err) {
  try day_runner =
    map.get(runners, day)
    |> result.replace_error(Unrecognized(day))

  let input_path = string.join(["input/day_", int.to_string(day), ".txt"], "")

  try input =
    input_path
    |> file.read()
    |> result.map(string.trim)
    |> result.replace_error(FailedToReadInput(input_path))

  do_run(day_runner, input)
}

fn collect(x: #(Day, gleam.Result(Solution, Err))) -> String {
  let day = int.to_string(x.0)
  case x.1 {
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
      err
      |> to_snag
      |> snag.layer(string.append("Error on day ", day))
      |> snag.layer("failed to run advent of code")
      |> snag.pretty_print()
  }
}

pub fn register_command(
  cli: glint.Command(Result(List(String))),
  runners: RunnerMap,
) -> glint.Command(Result(List(String))) {
  let timeout_flag =
    flag.int(
      called: "timeout",
      default: 0,
      explained: "Run with specified timeout",
    )

  cli
  |> glint.add_command(
    at: ["run"],
    do: run(_, runners, False),
    with: [timeout_flag],
    described: "Run the specified days",
    used: "gleam run run <FLAGS> <dayX> <dayY> <...>",
  )
  |> glint.add_command(
    at: ["run", "all"],
    do: run(_, runners, True),
    with: [timeout_flag],
    described: "Run all registered days",
    used: "gleam run run <FLAGS>",
  )
}

pub fn run(
  input: CommandInput,
  runners: RunnerMap,
  run_all: Bool,
) -> Result(List(String)) {
  assert Ok(flag.I(timeout)) = flag.get_value(input.flags, "timeout")

  try timing = case timeout {
    0 -> Ok(Endless)
    _ if timeout < 0 -> invalid_timeout_err(timeout)
    _ -> Ok(Ending(timeout))
  }

  try days = case run_all {
    True ->
      runners
      |> map.keys()
      |> list.sort(by: int.compare)
      |> Ok

    False ->
      input.args
      |> parse.days()
      |> wrap_failed_to_parse_err(input.args)
  }

  days
  |> cmd.exec(timing, do(_, runners), Other, collect)
  |> Ok
}

fn invalid_timeout_err(timeout: Int) -> Result(a) {
  ["invalid timeout value ", "'", int.to_string(timeout), "'"]
  |> string.concat()
  |> snag.error()
  |> snag.context("timeout must be greater than or equal to 1 ms")
}

fn wrap_failed_to_parse_err(res: Result(a), args: List(String)) -> Result(a) {
  snag.context(res, string.join(["failed to parse arguments:", ..args], " "))
}
