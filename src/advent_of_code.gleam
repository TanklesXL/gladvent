import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import gleam/function
import gleam/erlang/charlist.{Charlist}
import cmd/base.{Async, Sync, Timing, exec}
import cmd/run
import cmd/new
import parse.{Day}
import snag.{Result}
import async

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

fn parse_command_args(args) -> Result(#(Timing, Days)) {
  case args {
    [] -> Error(snag.new("missing command arguments"))
    ["async"] -> Error(snag.new("async called with no arguments"))
    ["async", _] -> Error(snag.new("no days selected"))
    ["async", timeout, ..days] -> {
      try timeout =
        parse.timeout(timeout)
        |> snag.context("bad timeout for run command")
      try days = parse.days(days)
      Ok(#(Async(timeout), days))
    }

    days -> {
      try days = parse.days(days)
      Ok(#(Sync, days))
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
  try cmd = parse_command_name(cmd)
  try #(timing, days) = parse_command_args(args)

  Ok(Do(cmd, timing, days))
}

pub fn main(args: List(Charlist)) {
  let args = list.map(args, charlist.to_string)
  case parse_command(args) {
    Ok(cmd) ->
      case cmd {
        Do(New, timing, days) -> exec(days, new.exec(timing))
        Do(Run, timing, days) -> exec(days, run.exec(timing))
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
