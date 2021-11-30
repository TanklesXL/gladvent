// import days/day_1
// import days/day_2
// import days/day_3
import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import gleam/map
import gleam/erlang/charlist.{Charlist}
import gleam/erlang.{start_arguments}
import cmd.{Async, Sync, Timing, exec}
import cmd/run
import cmd/new
import parse.{Day}
import snag.{Result}

fn runners() {
  map.new()
  // |> map.insert(1, day_1.run)
  // |> map.insert(2, day_2.run)
  // |> map.insert(3, day_3.run)
}

pub fn main() {
  let args = start_arguments()
  case parse_command(args) {
    Ok(Do(cmd, timing, days)) ->
      case cmd {
        New -> exec(days, new.exec(timing))
        Run -> exec(days, run.exec(timing, runners()))
      }
    Error(err) -> [
      err
      |> snag.layer(string.join(["failed to parse command:", ..args], " "))
      |> snag.pretty_print(),
    ]
  }
  |> string.join(with: "\n\n")
  |> io.println()
}

type Days =
  List(Day)

type Do {
  Do(Command, Timing, Days)
}

type Command {
  New
  Run
}

const available_commands_msg = "the available commands are 'run', 'run async', 'new' and 'new async'"

fn parse_command_name(cmd: String) -> Result(Command) {
  case cmd {
    "run" -> Ok(Run)
    "new" -> Ok(New)
    _ ->
      Error(snag.new(string.append(
        "unrecognized command, ",
        available_commands_msg,
      )))
  }
}

fn parse_command_args(args: List(String)) -> Result(fn(Command) -> Do) {
  case args {
    [] -> Error(snag.new("missing command arguments"))
    ["async"] -> Error(snag.new("async called with no arguments"))
    ["async", _] -> Error(snag.new("no days selected"))
    ["async", timeout, ..days] -> {
      try timeout =
        parse.timeout(timeout)
        |> snag.context("bad timeout for run command")
      try days = parse.days(days)
      Ok(Do(_, Async(timeout), days))
    }
    days -> {
      try days = parse.days(days)
      Ok(Do(_, Sync, days))
    }
  }
}

fn parse_command(l: List(String)) -> Result(Do) {
  try #(cmd, args) = case l {
    [] ->
      Error(snag.new(string.append(
        "no command provided, ",
        available_commands_msg,
      )))
    [cmd, ..args] -> Ok(#(cmd, args))
  }
  try build_do = parse_command_args(args)
  try cmd = parse_command_name(cmd)

  Ok(build_do(cmd))
}
