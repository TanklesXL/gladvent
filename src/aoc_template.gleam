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
import snag

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
        "new" -> new.exec(days, timeout)
        "run" -> run.exec(days, timeout)
        _ -> [string.concat(["unrecognized command: ", ..args])]
      }
    Error(err) -> [err]
  }
  |> string.join(with: "\n\n")
  |> io.println()
}
