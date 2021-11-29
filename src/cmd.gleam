import async
import gleam/iterator
import gleam/result
import parse.{Day, Timeout}
import snag.{Result}

pub type Exec(a) {
  Exec(
    do: fn(Day) -> Result(a),
    collect: fn(#(Result(a), Day)) -> String,
    timing: Timing,
  )
}

pub type Timing {
  Sync
  Async(Timeout)
}

pub fn exec(days: List(Day), cmd: Exec(a)) -> List(String) {
  case cmd.timing {
    Sync ->
      days
      |> iterator.from_list()
      |> iterator.map(cmd.do)
    Async(timeout) ->
      days
      |> async.list_map(cmd.do)
      |> async.try_await_many(timeout)
      |> iterator.from_list()
      |> iterator.map(result.flatten)
  }
  |> iterator.zip(iterator.from_list(days))
  |> iterator.map(cmd.collect)
  |> iterator.to_list()
}
