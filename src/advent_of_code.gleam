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

pub fn main(args: List(Charlist)) {
  let args = list.map(args, charlist.to_string)
  case args {
    ["new", ..days] -> exec(days, new.do, new.collect, Sync)
    ["run", "async", timeout, ..days] -> {
      let timeout = parse.timeout(timeout)
      case timeout {
        Ok(timeout) -> exec(days, run.do, run.collect, Async(timeout))
        Error(err) -> [snag.pretty_print(err)]
      }
    }
    ["run", ..days] -> exec(days, run.do, run.collect, Sync)
    [] -> ["no command provided, allowed options are \"run\" and \"new\""]
    _ -> [string.concat(["unrecognized command: ", ..args])]
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
