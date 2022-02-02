import gleam/iterator
import gleam/result
import parse.{Day}
import snag.{Result, Snag}
import gleam/otp/task.{Task}
import gleam/erlang
import gleam/erlang/atom
import gleam/dynamic
import gleam/list
import gleam/result
import gleam/int
import gleam/function
import gleam

pub const input_dir = "input/"

pub const days_dir = "src/days/"

pub type Timing {
  Endless
  Ending(Timeout)
}

pub type Timeout =
  Int

pub fn exec(
  days: List(Day),
  timing: Timing,
  do: fn(Day) -> Result(a),
  collect: fn(#(Result(a), Day)) -> String,
) -> List(String) {
  days
  |> task_map(do)
  |> try_await_many(timing)
  |> iterator.from_list()
  |> iterator.map(result.flatten)
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

fn try_await_many(tasks: List(Task(a)), timing: Timing) -> List(Result(a)) {
  let await = case timing {
    // currently no await_forever so we'll use 10 mins  
    Endless -> fn(t) {
      t
      |> task.try_await(600_000)
      |> result.map_error(snag_task_error)
    }
    Ending(timeout) -> {
      let end = now_ms() + timeout
      fn(t) {
        end - now_ms()
        |> int.clamp(min: 0, max: timeout)
        |> task.try_await(t, _)
        |> result.map_error(snag_task_error)
      }
    }
  }

  list.map(tasks, await)
}

type UndefRun {
  Undef
  Run
}

fn snag_task_error(err: task.AwaitError) -> Snag {
  case err {
    task.Timeout -> "task timed out"
    task.Exit(dyn) ->
      case dynamic.unsafe_coerce(dyn) {
        #(Undef, [#(_, Run, _, _), ..]) -> "Run function missing"
        _ -> "task exited for some reason"
      }
  }
  |> snag.new()
}
