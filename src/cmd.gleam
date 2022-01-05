import async
import gleam/iterator
import gleam/result
import parse.{Day, Timeout}
import snag.{Result}

pub type Timing {
  Sync
  Async(Timeout)
}

pub fn exec(
  days: List(Day),
  timing: Timing,
  do: fn(Day) -> Result(a),
  collect: fn(#(Result(a), Day)) -> String,
) -> List(String) {
  case timing {
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

pub fn no_days_selected_err() -> String {
  "no days selected"
  |> snag.new()
  |> snag.pretty_print()
}
