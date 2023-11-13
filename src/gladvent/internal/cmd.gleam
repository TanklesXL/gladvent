import gleam/result
import gladvent/internal/parse.{type Day}
import gleam/otp/task.{type Task}
import gleam/erlang
import gleam/pair
import gleam/list
import gleam/int
import gleam/string
import glint/flag
import snag

pub fn input_dir(year) {
  input_root <> int.to_string(year) <> "/"
}

pub const input_root = "input/"

pub const src_root = "src/"

pub fn src_dir(year) {
  src_root <> "aoc_" <> int.to_string(year) <> "/"
}

pub type Timing {
  Endless
  Ending(Timeout)
}

pub type Timeout =
  Int

pub type Year =
  Int

pub fn exec(
  days: List(Day),
  timing: Timing,
  do: fn(Day) -> a,
  collect: fn(#(Day, Result(a, String))) -> c,
) -> List(c) {
  days
  |> task_map(do)
  |> try_await_many(timing)
  |> list.map(collect)
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

@external(erlang, "erlang", "localtime")
fn date() -> #(#(Int, Int, Int), #(Int, Int, Int))

fn current_year() -> Int {
  { date().0 }.0
}

pub const year = "year"

pub fn year_flag() {
  flag.int()
  |> flag.default(current_year())
  |> flag.constraint(fn(year) {
    case year < 2015 {
      True ->
        snag.error(
          "advent of code did not exist prior to 2015, did you mistype?",
        )
      False -> Ok(Nil)
    }
  })
}
