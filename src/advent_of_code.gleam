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
  New(List(String))
  Run(Timing, List(String))
}

fn parse_command(l: List(String)) -> Result(Command) {
  case l {
    [] ->
      Error(snag.new(
        "no command provided, allowed options are \"run\" and \"new\"",
      ))
    ["new", ..days] -> Ok(New(days))
    ["run", "async", timeout, ..days] -> {
      try timeout = parse.timeout(timeout)
      Ok(Run(Async(timeout), days))
    }
    ["run", ..days] -> Ok(Run(Sync, days))
    _ ->
      Error(
        l
        |> string.join(" ")
        |> snag.new()
        |> snag.layer("unrecognized command"),
      )
  }
}

pub fn main(args: List(Charlist)) {
  let args = list.map(args, charlist.to_string)
  case parse_command(args) {
    Ok(New(days)) -> exec(days, new.do, new.collect, Sync)
    Ok(Run(timing, days)) -> exec(days, run.do, run.collect, timing)
    Error(err) -> [snag.pretty_print(err)]
  }
  |> string.join(with: "\n\n")
  |> io.println()
}

type Timing {
  Sync
  Async(Int)
}

fn exec(
  days: List(String),
  do: fn(String) -> Result(a),
  collect: fn(#(Result(a), String)) -> String,
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
