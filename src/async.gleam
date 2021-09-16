import gleam/list
import gleam/result
import gleam/otp/task.{Task}
import snag.{Result}
import ffi/time
import gleam/int

pub fn list_map(over l: List(a), with f: fn(a) -> b) -> List(Task(b)) {
  list.map(l, fn(x) { task.async(fn() { f(x) }) })
}

pub fn try_await_many(tasks: List(Task(a)), timeout: Int) -> List(Result(a)) {
  let end = time.now_ms() + timeout
  let delayed_try_await = fn(t) {
    end - time.now_ms()
    |> int.clamp(min: 0, max: timeout)
    |> task.try_await(t, _)
  }

  tasks
  |> list.map(delayed_try_await)
  |> list.map(result.map_error(
    over: _,
    with: fn(res) {
      case res {
        task.Timeout -> "task timed out"
        task.Exit(_) -> "task exited for some reason"
      }
      |> snag.new()
    },
  ))
}
