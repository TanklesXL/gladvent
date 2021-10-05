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

type Command {
  New(List(Day))
  Run(Timing, List(Day))
}

const available_commands_msg = "the available commands are 'run', 'run async' and 'new'"

fn parse_command(l: List(String)) -> Result(Command) {
  case l {
    [] ->
      Error(snag.new(string.append(
        "no command provided, ",
        available_commands_msg,
      )))

    ["run", "async", timeout, ..days] -> {
      try timeout =
        parse.timeout(timeout)
        |> snag.context("bad timeout for run command")
      try days = parse.days(days)
      Ok(Run(Async(timeout), days))
    }

    ["run", ..days] -> {
      try days = parse.days(days)
      Ok(Run(Sync, days))
    }

    ["new", ..days] -> {
      try days = parse.days(days)
      Ok(New(days))
    }

    _ ->
      Error(snag.new(string.append(
        "unrecognized command, ",
        available_commands_msg,
      )))
  }
}

pub fn main(args: List(Charlist)) {
  let args = list.map(args, charlist.to_string)
  case parse_command(args) {
    Ok(New(days)) -> exec(days, new.exec(), Sync)
    Ok(Run(timing, days)) -> exec(days, run.exec(), timing)
    Error(err) -> [
      err
      |> snag.layer(string.join(["failed to parse command:", ..args], " "))
      |> snag.pretty_print(),
    ]
  }
  |> string.join(with: "\n\n")
  |> io.println()
}
