import gleam/function
import gleam/list
import gleam/result
import gleam/otp/task.{Task}
import snag.{Result, Snag}
import ffi/time
import gleam/int
import parse.{Timeout}
import gleam

pub fn list_map(over l: List(a), with f: fn(a) -> b) -> List(Task(b)) {
  list.map(l, fn(x) { task.async(fn() { f(x) }) })
}

pub fn try_await_many(tasks: List(Task(a)), timeout: Timeout) -> List(Result(a)) {
  let end = time.now_ms() + timeout
  let delayed_try_await = fn(t) {
    end - time.now_ms()
    |> int.clamp(min: 0, max: timeout)
    |> task.try_await(t, _)
  }

  tasks
  |> list.map(fn(t) {
    t
    |> delayed_try_await()
    |> result.map_error(snag_task_error)
  })
}

fn snag_task_error(err: task.AwaitError) -> Snag {
  case err {
    task.Timeout -> "task timed out"
    task.Exit(_) -> "task exited for some reason"
  }
  |> snag.new()
}
