import gleam/list
import gleam/io
import gleam/int
import gleam/iterator
import gleam/result
import gleam/string
import gleam/function
import files
import time
import gleam/erlang/charlist.{Charlist}
import cmd/run
import cmd/new
import parse
import snag.{Result}
import async

// import snag.{Result}
pub fn main(args: List(Charlist)) {
  let args = list.map(args, charlist.to_string)
  assert [command, timeout, ..days] = args

  let timeout =
    timeout
    |> parse.int()
    |> snag.context("failed to parse timeout")
    |> result.map_error(snag.pretty_print)

  case timeout {
    Ok(timeout) ->
      case command {
        "new" -> exec(days, timeout, new.do, new.collect)
        "run" -> exec(days, timeout, run.do, run.collect)
        _ -> [string.concat(["unrecognized command: ", ..args])]
      }
    Error(err) -> [err]
  }
  |> string.join(with: "\n\n")
  |> io.println()
}

fn exec(
  days: List(String),
  timeout: Int,
  do: fn(String) -> Result(a),
  collect: fn(#(Result(a), String)) -> String,
) -> List(String) {
  days
  |> async.list_map(do)
  |> async.try_await_many(timeout)
  |> iterator.from_list()
  |> iterator.map(result.flatten)
  |> iterator.zip(iterator.from_list(days))
  |> iterator.map(collect)
  |> iterator.to_list()
}
