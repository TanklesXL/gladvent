import gleam/iterator
import gleam/result
import parse.{Day}
import snag.{Result, Snag}
import gleam/otp/task.{Task}
import gleam/erlang
import gleam/list
import gleam/result
import gleam/int
import gleam

pub type Timing {
  Sync
  Async(Timeout)
}

pub type Timeout =
  Int

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
      |> task_map(do)
      |> try_await_many(timeout)
      |> iterator.from_list()
      |> iterator.map(result.flatten)
  }
  |> iterator.zip(iterator.from_list(days))
  |> iterator.map(collect)
  |> iterator.to_list()
}

fn now_ms() {
  erlang.system_time(erlang.Millisecond)
}

fn task_map(over l: List(a), with f: fn(a) -> b) -> List(Task(b)) {
  list.map(l, fn(x) { task.async(fn() { f(x) }) })
}

fn try_await_many(tasks: List(Task(a)), timeout: Timeout) -> List(Result(a)) {
  let end = now_ms() + timeout
  let delayed_try_await = fn(t) {
    end - now_ms()
    |> int.clamp(min: 0, max: timeout)
    |> task.try_await(t, _)
    |> result.map_error(snag_task_error)
  }

  list.map(tasks, delayed_try_await)
}

fn snag_task_error(err: task.AwaitError) -> Snag {
  case err {
    task.Timeout -> "task timed out"
    task.Exit(_) -> "task exited for some reason"
  }
  |> snag.new()
}
