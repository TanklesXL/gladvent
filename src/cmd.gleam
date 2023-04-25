import gleam/iterator
import gleam/result
import parse.{Day}
import gleam/otp/task.{Task}
import gleam/erlang
import gleam/pair
import gleam/list
import gleam/int
import gleam/string
import glint/flag
import glint/flag/constraint
import snag

pub const days = "days"

pub fn days_flag() {
  flag.new(
    flag.LI
    |> flag.constraint(fn(l) {
      case l {
        [] -> snag.error("no days selected")
        _ -> Ok(Nil)
      }
    })
    |> flag.constraint(
      fn(i) {
        case i {
          _ if i > 0 && i < 26 -> Ok(Nil)
          _ ->
            snag.error(
              "invalid day: '" <> int.to_string(i) <> "' must be in range 1 to 25",
            )
        }
      }
      |> constraint.each(),
    ),
  )
  |> flag.description("a comma separated list of days")
}

pub type Timing {
  Endless
  Ending(Timeout)
}

pub type Timeout =
  Int

pub fn exec(
  days: List(Day),
  timing: Timing,
  do: fn(Day) -> Result(a, b),
  other: fn(String) -> b,
  collect: fn(#(Day, Result(a, b))) -> String,
) -> List(String) {
  days
  |> task_map(do)
  |> try_await_many(timing)
  |> iterator.from_list()
  |> iterator.map(fn(x) {
    x
    |> pair.map_second(result.map_error(_, other))
    |> pair.map_second(result.flatten)
  })
  |> iterator.map(collect)
  |> iterator.to_list()
}

fn now_ms() {
  erlang.system_time(erlang.Millisecond)
}

fn task_map(over l: List(a), with f: fn(a) -> b) -> List(#(a, Task(b))) {
  use x <- list.map(l)
  #(x, task.async(fn() { f(x) }))
}

fn try_await_many(
  tasks: List(#(x, Task(a))),
  timing: Timing,
) -> List(#(x, Result(a, String))) {
  case timing {
    Endless -> {
      use tup <- list.map(tasks)
      use t <- pair.map_second(tup)
      task.try_await_forever(t)
      |> result.map_error(await_err_to_string)
    }

    Ending(timeout) -> {
      let end = now_ms() + timeout
      use tup <- list.map(tasks)
      use t <- pair.map_second(tup)
      end - now_ms()
      |> int.clamp(min: 0, max: timeout)
      |> task.try_await(t, _)
      |> result.map_error(await_err_to_string)
    }
  }
}

fn await_err_to_string(err: task.AwaitError) -> String {
  case err {
    task.Timeout -> "task timed out"
    task.Exit(s) -> "task exited for some reason: " <> string.inspect(s)
  }
}
