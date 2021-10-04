import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import gleam/function
import gleam/erlang/charlist.{Charlist}
import cmd/run
import cmd/new
import parse
import snag.{Result}
import async

type Command {
  New(List(Int))
  Run(Timing, List(Int))
}

fn parse_command(l: List(String)) -> Result(Command) {
  case l {
    [] ->
      Error(
        "no command provided, allowed options are \"run\", \"run async\" and \"new\""
        |> snag.new(),
      )
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
      ["unrecognized command:", ..l]
      |> string.join(" ")
      |> snag.new()
      |> Error
  }
}

pub fn main(args: List(Charlist)) {
  let args = list.map(args, charlist.to_string)
  case parse_command(args) {
    Ok(New(days)) -> exec(days, new.do, new.collect, Sync)
    Ok(Run(timing, days)) -> exec(days, run.do, run.collect, timing)
    Error(err) -> [
      err
      |> snag.layer("failed to parse command")
      |> snag.pretty_print(),
    ]
  }
  |> string.join(with: "\n\n")
  |> io.println()
}

type Timing {
  Sync
  Async(Int)
}

fn exec(
  days: List(Int),
  do: fn(Int) -> Result(a),
  collect: fn(#(Result(a), Int)) -> String,
  t: Timing,
) -> List(String) {
  case t {
    Sync ->
      days
      |> iterator.from_list()
      |> iterator.map(do)
    Async(timeout) ->
      days
      |> async.list_map(do)
      |> async.try_await_many(timeout)
      |> iterator.from_list()
      |> iterator.map(result.flatten)
  }
  |> iterator.zip(iterator.from_list(days))
  |> iterator.map(collect)
  |> iterator.to_list()
}
